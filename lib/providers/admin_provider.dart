import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/models/queue_entry.dart';
import 'package:queueflow_mobileapp/models/ws_message.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';

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
      }
    });
  }

  void _handleQueueState(dynamic payload) {
    final queueState = QueueStatePayload.fromJson(payload);
    final queue =
        queueState.queue.map((e) => QueueEntry.fromJson(e)).toList();

    state = state.copyWith(
      queue: queue,
      isPaused: queueState.isPaused,
    );
  }

  Future<void> _refreshQueue() async {
    state = state.copyWith(isLoading: true);

    try {
      final queue = await _apiService.getQueueList(_token);
      state = state.copyWith(queue: queue, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> callNext() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.callNext(_token);
      await _refreshQueue();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeUser(int userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.removeUser(_token, userId);
      await _refreshQueue();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> pauseQueue() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.pauseQueue(_token);
      state = state.copyWith(isPaused: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resumeQueue() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.resumeQueue(_token);
      state = state.copyWith(isPaused: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
