import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/models/user.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/services/storage_service.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';
import 'package:queueflow_mobileapp/services/fcm_service.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final storageServiceProvider = Provider((ref) => StorageService());

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  final WebSocketService _websocketService;

  AuthNotifier(this._apiService, this._storageService, this._websocketService)
      : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _storageService.getUser();
    if (user != null) {
      state = state.copyWith(user: user);
      _websocketService.connect(user.token);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _apiService.login(username, password);
      await _storageService.saveUser(user);
      state = state.copyWith(user: user, isLoading: false);

      // Connect WebSocket
      _websocketService.connect(user.token);

      // Send FCM token to backend
      final fcmToken = FCMService().fcmToken;
      if (fcmToken != null) {
        try {
          await _apiService.updateFCMToken(user.token, fcmToken);
          print('[Auth] FCM token sent to backend');
        } catch (e) {
          print('[Auth] Failed to send FCM token: $e');
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _storageService.clearUser();
    _websocketService.disconnect();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiServiceProvider),
    ref.read(storageServiceProvider),
    ref.read(websocketServiceProvider),
  );
});
