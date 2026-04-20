import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/models/queue_entry.dart';
import 'package:queueflow_mobileapp/models/ws_message.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';
import 'package:queueflow_mobileapp/utils/exceptions.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';

class AdminState {
  final List<QueueEntry> queue;
  final bool isPaused;
  final bool isLoading;
  final String? error;

  AdminState({
    this.queue = const [],
    this.isPaused = false,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<QueueEntry>? queue,
    bool? isPaused,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      queue: queue ?? this.queue,
      isPaused: isPaused ?? this.isPaused,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiService _apiService;
  final WebSocketService _websocketService;
  final String _token;

  AdminNotifier(this._apiService, this._websocketService, this._token)
      : super(AdminState()) {
    _listenToWebSocket();
    _refreshQueue();
  }

  void _listenToWebSocket() {
    _websocketService.messages.listen((message) {
      if (message.type == 'admin:queue_state') {
        _handleQueueState(message.payload);
      } else if (message.type == 'admin:user_joined') {
        _handleUserJoined(message.payload);
      }
    });
  }

  void _handleUserJoined(dynamic payload) {
    try {
      // Don't show notification when app is open
      // User can already see the queue update in the UI
      // Backend will send FCM notification if app is closed

      // Refresh queue to show the new user
      _refreshQueue();
    } catch (e) {
      AppLogger.error('Error handling user joined', e, null, 'AdminProvider');
    }
  }

  void _handleQueueState(dynamic payload) {
    try {
      // Ensure payload is a Map
      if (payload is! Map<String, dynamic>) {
        AppLogger.warning('Invalid queue data format received', 'AdminProvider');
        state = state.copyWith(queue: [], error: 'Invalid queue data format');
        return;
      }

      final queueState = QueueStatePayload.fromJson(payload);
      final queue = (queueState.queue)
          .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        queue: queue,
        isPaused: queueState.isPaused,
        clearError: true,
      );
    } catch (e, stackTrace) {
      // Handle null or invalid queue data gracefully
      AppLogger.error('Error parsing queue data', e, stackTrace, 'AdminProvider');
      AppLogger.debug('Payload: $payload', 'AdminProvider');
      state = state.copyWith(queue: [], error: 'Failed to parse queue data');
    }
  }

  Future<void> _refreshQueue() async {
    state = state.copyWith(isLoading: true);

    try {
      final queue = await _apiService.getQueueList(_token);
      state = state.copyWith(queue: queue, isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to refresh queue', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error refreshing queue', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: 'Failed to load queue');
    }
  }

  Future<void> callNext() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.callNext(_token);
      await _refreshQueue();
      state = state.copyWith(isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to call next user', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error calling next user', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: 'Failed to call next user');
    }
  }

  Future<void> removeUser(int userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.removeUser(_token, userId);
      await _refreshQueue();
      state = state.copyWith(isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to remove user', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error removing user', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: 'Failed to remove user');
    }
  }

  Future<void> pauseQueue() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.pauseQueue(_token);
      state = state.copyWith(isPaused: true, isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to pause queue', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error pausing queue', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: 'Failed to pause queue');
    }
  }

  Future<void> resumeQueue() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.resumeQueue(_token);
      state = state.copyWith(isPaused: false, isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to resume queue', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error resuming queue', e, null, 'AdminProvider');
      state = state.copyWith(isLoading: false, error: 'Failed to resume queue');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final authState = ref.watch(authProvider);
  final token = authState.user?.token ?? '';

  return AdminNotifier(
    ref.read(apiServiceProvider),
    ref.read(websocketServiceProvider),
    token,
  );
});
