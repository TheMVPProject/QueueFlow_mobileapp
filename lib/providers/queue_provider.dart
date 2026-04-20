import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/models/queue_entry.dart';
import 'package:queueflow_mobileapp/models/ws_message.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';

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

  QueueNotifier(this._apiService, this._websocketService, this._token)
      : super(QueueState()) {
    _listenToWebSocket();
    _refreshStatus();
  }

  void _listenToWebSocket() {
    _websocketService.messages.listen((message) {
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

  void _handlePositionUpdate(dynamic payload) {
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
    final yourTurn = YourTurnPayload.fromJson(payload);
    state = state.copyWith(yourTurn: yourTurn, hasTimedOut: false);
  }

  void _handleTimeout(dynamic payload) {
    state = state.copyWith(
      clearStatus: true,
      clearYourTurn: true,
      hasTimedOut: true,
    );
  }

  void _handleConfirmed() {
    state = state.copyWith(clearStatus: true, clearYourTurn: true);
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _apiService.getQueueStatus(_token);
      state = state.copyWith(status: status);
    } catch (e) {
      // Silently fail - user not in queue
    }
  }

  Future<void> joinQueue() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.joinQueue(_token);
      await _refreshStatus();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> leaveQueue() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.leaveQueue(_token);
      state = state.copyWith(clearStatus: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmTurn() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.confirmTurn(_token);
      state = state.copyWith(
        clearStatus: true,
        clearYourTurn: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
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
