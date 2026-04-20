import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/models/user.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/services/storage_service.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';
import 'package:queueflow_mobileapp/services/fcm_service.dart';
import 'package:queueflow_mobileapp/services/notification_service.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/utils/exceptions.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final storageServiceProvider = Provider((ref) => StorageService());

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized; // Track if we've checked stored auth

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
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
    // Ensure splash shows for minimum 1.5 seconds for better UX
    final startTime = DateTime.now();

    try {
      final user = await _storageService.getUser();

      // Calculate remaining time to show splash
      final elapsed = DateTime.now().difference(startTime);
      final minSplashDuration = const Duration(milliseconds: 1500);

      if (elapsed < minSplashDuration) {
        final remaining = minSplashDuration - elapsed;
        AppLogger.debug('Waiting ${remaining.inMilliseconds}ms more for splash', 'AuthProvider');
        await Future.delayed(remaining);
      }

      if (user != null) {
        state = state.copyWith(user: user, isInitialized: true);
        AppLogger.success('User restored, isInitialized: true', 'AuthProvider');
        _websocketService.connect(user.token);

        // Initialize FCM and update token for logged-in user (in background)
        _initializeFCMAndUpdateToken(user.token);
      } else {
        // No stored user, initialization complete
        AppLogger.info('No stored user, isInitialized: true', 'AuthProvider');
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      // Error loading user, mark as initialized anyway
      AppLogger.error('Error loading user, isInitialized: true', e, null, 'AuthProvider');

      // Still respect minimum splash time
      final elapsed = DateTime.now().difference(startTime);
      final minSplashDuration = const Duration(milliseconds: 1500);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }

      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _apiService.login(username, password);
      await _storageService.saveUser(user);
      state = state.copyWith(user: user, isLoading: false, isInitialized: true);

      // Connect WebSocket
      _websocketService.connect(user.token);

      // Initialize FCM AFTER login and send token to backend
      await _initializeFCMAndUpdateToken(user.token);
    } on AppException catch (e) {
      AppLogger.error('Login failed', e, null, 'AuthProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error during login', e, null, 'AuthProvider');
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please try again.',
      );
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _apiService.register(username, email, password);
      await _storageService.saveUser(user);
      state = state.copyWith(user: user, isLoading: false, isInitialized: true);

      // Connect WebSocket
      _websocketService.connect(user.token);

      // Initialize FCM AFTER registration and send token to backend
      await _initializeFCMAndUpdateToken(user.token);
    } on AppException catch (e) {
      AppLogger.error('Registration failed', e, null, 'AuthProvider');
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      AppLogger.error('Unexpected error during registration', e, null, 'AuthProvider');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
    }
  }

  /// Initialize FCM and update token for the logged-in user
  Future<void> _initializeFCMAndUpdateToken(String token) async {
    try {
      // Initialize notification service (local notifications)
      await NotificationService().initialize();

      // Set auth token in FCM service for automatic updates
      FCMService().setAuthToken(token);

      // Initialize FCM (requests permission and gets token)
      await FCMService().initialize();

      // Get the FCM token
      final fcmToken = FCMService().fcmToken;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        AppLogger.info('FCM token obtained: ${fcmToken.substring(0, 20)}...', 'Auth');

        // Send token to backend
        await _apiService.updateFCMToken(token, fcmToken);
        AppLogger.success('FCM token updated in backend', 'Auth');
      } else {
        AppLogger.warning('FCM token not available (permission denied or device issue)', 'Auth');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize FCM or update token', e, null, 'Auth');
      // Don't throw error - FCM is optional, app should work without it
    }
  }

  /// Refresh FCM token (call this when app resumes or token needs to be updated)
  Future<void> refreshFCMToken() async {
    if (state.user != null) {
      await _initializeFCMAndUpdateToken(state.user!.token);
    }
  }

  Future<void> logout() async {
    // Clear FCM token from backend before logging out
    if (state.user != null) {
      try {
        await _apiService.updateFCMToken(state.user!.token, '');
        AppLogger.info('FCM token cleared from backend', 'Auth');
      } catch (e) {
        AppLogger.error('Failed to clear FCM token', e, null, 'Auth');
      }
    }

    await _storageService.clearUser();
    _websocketService.disconnect();
    // Keep isInitialized: true so router redirects to auth selection, not splash
    state = AuthState(isInitialized: true);
    AppLogger.info('Logout complete - isInitialized: ${state.isInitialized}, isAuthenticated: ${state.isAuthenticated}', 'Auth');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiServiceProvider),
    ref.read(storageServiceProvider),
    ref.read(websocketServiceProvider),
  );
});
