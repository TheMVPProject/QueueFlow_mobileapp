import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/models/queue_entry.dart';
import 'package:queueflow_mobileapp/models/ws_message.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';
import 'package:queueflow_mobileapp/services/navigation_service.dart';
import 'package:queueflow_mobileapp/utils/exceptions.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';

class QueueState {
  final QueueStatus? status;
  final bool isLoading;
  final String? error;
  final YourTurnPayload? yourTurn;
  final bool hasTimedOut;

  QueueState({
    this.status,
    this.isLoading = false,
    this.error,
    this.yourTurn,
    this.hasTimedOut = false,
  });

  bool get inQueue => status != null;
  bool get isWaiting => status?.isWaiting ?? false;
  bool get isCalled => status?.isCalled ?? false;
  bool get isConfirmed => status?.isConfirmed ?? false;

  QueueState copyWith({
    QueueStatus? status,
    bool? isLoading,
    String? error,
    YourTurnPayload? yourTurn,
    bool? hasTimedOut,
    bool clearStatus = false,
    bool clearYourTurn = false,
    bool clearError = false,
  }) {
    return QueueState(
      status: clearStatus ? null : (status ?? this.status),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      yourTurn: clearYourTurn ? null : (yourTurn ?? this.yourTurn),
      hasTimedOut: hasTimedOut ?? this.hasTimedOut,
    );
  }
}

class QueueNotifier extends StateNotifier<QueueState> {
  final ApiService _apiService;
  final WebSocketService _websocketService;
  final String _token;
  StreamSubscription<WSMessage>? _wsSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  QueueNotifier(this._apiService, this._websocketService, this._token)
      : super(QueueState()) {
    _listenToWebSocket();
    _listenToConnectionStatus();
    _refreshStatus();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _listenToWebSocket() {
    _wsSubscription = _websocketService.messages.listen((message) {
      switch (message.type) {
        case 'queue:position_update':
          _handlePositionUpdate(message.payload);
          break;
        case 'queue:your_turn':
          _handleYourTurn(message.payload);
          break;
        case 'queue:timeout':
          _handleTimeout(message.payload);
          break;
        case 'queue:confirmed':
          _handleConfirmed();
          break;
      }
    });
  }

  void _listenToConnectionStatus() {
    _statusSubscription = _websocketService.status.listen((status) {
      if (status == ConnectionStatus.connected) {
        AppLogger.info('WebSocket reconnected, syncing queue state', 'QueueProvider');
        _refreshStatus();
      }
    });
  }

  void _handlePositionUpdate(dynamic payload) {
    if (!mounted) return;
    final update = PositionUpdate.fromJson(payload);
    state = state.copyWith(
      status: QueueStatus(
        position: update.position,
        status: update.status,
        totalInQueue: update.totalInQueue,
      ),
    );
  }

  void _handleYourTurn(dynamic payload) {
    if (!mounted) return;
    final yourTurn = YourTurnPayload.fromJson(payload);
    state = state.copyWith(yourTurn: yourTurn, hasTimedOut: false);

    // Don't show notification when app is open (user can see the UI)
    // Backend will send FCM notification if app is closed

    // Navigate to your turn screen
    NavigationService().navigateTo('/your-turn');
  }

  void _handleTimeout(dynamic payload) {
    if (!mounted) return;
    state = state.copyWith(
      clearStatus: true,
      clearYourTurn: true,
      hasTimedOut: true,
    );
  }

  void _handleConfirmed() {
    if (!mounted) return;
    state = state.copyWith(clearStatus: true, clearYourTurn: true);
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _apiService.getQueueStatus(_token);
      if (!mounted) return;

      // If user is called, construct YourTurnPayload
      if (status != null && status.isCalled && status.timeoutAt != null) {
        final timeoutInSec = status.timeoutAt!.difference(DateTime.now()).inSeconds;
        state = state.copyWith(
          status: status,
          yourTurn: YourTurnPayload(
            position: status.position,
            timeoutAt: status.timeoutAt!,
            timeoutInSeconds: timeoutInSec,
          ),
          hasTimedOut: false,
        );
        AppLogger.success('Restored "called" state after reconnect', 'QueueProvider');
      } else {
        state = state.copyWith(status: status, hasTimedOut: false);
      }
    } on QueueException catch (e) {
      // Expected: User not currently in any queue
      AppLogger.debug('Queue status check: ${e.message}', 'QueueProvider');
      if (!mounted) return;
      // Clear any stale state
      state = state.copyWith(clearStatus: true, clearYourTurn: true, clearError: true);
    } catch (e) {
      AppLogger.error('Unexpected error refreshing queue status', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(clearStatus: true, clearYourTurn: true, clearError: true);
    }
  }

  Future<void> joinQueue() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null, hasTimedOut: false);

    try {
      await _apiService.joinQueue(_token);
      await _refreshStatus();
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to join queue', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error joining queue', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join queue. Please try again.',
      );
    }
  }

  Future<void> leaveQueue() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.leaveQueue(_token);
      if (!mounted) return;
      state = state.copyWith(clearStatus: true, isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to leave queue', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error leaving queue', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to leave queue. Please try again.',
      );
    }
  }

  Future<void> confirmTurn() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.confirmTurn(_token);
      if (!mounted) return;
      state = state.copyWith(
        clearStatus: true,
        clearYourTurn: true,
        isLoading: false,
      );
    } on AppException catch (e) {
      AppLogger.error('Failed to confirm turn', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error confirming turn', e, null, 'QueueProvider');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to confirm turn. Please try again.',
      );
    }
  }

  void clearError() {
    if (!mounted) return;
    state = state.copyWith(clearError: true);
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  final authState = ref.watch(authProvider);
  final token = authState.user?.token ?? '';

  return QueueNotifier(
    ref.read(apiServiceProvider),
    ref.read(websocketServiceProvider),
    token,
  );
});
