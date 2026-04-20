import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:queueflow_mobileapp/services/notification_service.dart';
import 'package:queueflow_mobileapp/services/navigation_service.dart';
import 'package:queueflow_mobileapp/services/api_service.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';
import 'dart:io';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Background message received: ${message.messageId}', 'FCM');
  AppLogger.info('Data: ${message.data}', 'FCM');
  AppLogger.info('Has notification: ${message.notification != null}', 'FCM');

  // FCM automatically shows notification if 'notification' field is present
  // We only show custom notification if FCM didn't show one
  // This prevents duplicate notifications!
  if (message.notification == null) {
    final type = message.data['type'];
    if (type == 'your_turn') {
      AppLogger.info('Showing custom notification: your_turn', 'FCM');
      await NotificationService().showYourTurnNotification();
    } else if (type == 'user_joined') {
      AppLogger.info('Showing custom notification: user_joined', 'FCM');
      final username = message.data['username'] as String?;
      await NotificationService().showUserJoinedNotification(username: username);
    }
  } else {
    AppLogger.info('FCM notification already shown, skipping custom notification', 'FCM');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _initialized = false;
  String? _currentAuthToken; // Store auth token for automatic backend updates

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  /// Set auth token for automatic FCM token updates
  void setAuthToken(String? token) {
    _currentAuthToken = token;
  }

  Future<void> initialize() async {
    AppLogger.info('Initializing FCM service...', 'FCM');

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info('Permission status: ${settings.authorizationStatus}', 'FCM');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {

      try {
        // iOS simulator fix
        if (Platform.isIOS) {
          String? apnsToken = await _messaging.getAPNSToken();

          if (apnsToken == null) {
            AppLogger.info('Simulator detected. Skipping FCM token.', 'FCM');
            _initialized = true;
            return;
          }
        }

        _fcmToken = await _messaging.getToken();
        AppLogger.success('Token obtained: ${_fcmToken?.substring(0, 20)}...', 'FCM');

        // Setup message handlers only once
        if (!_initialized) {
          _setupMessageHandlers();
          _initialized = true;
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          AppLogger.info('Token refreshed: ${newToken.substring(0, 20)}...', 'FCM');
          _fcmToken = newToken;

          // 🔄 NEW: Update backend when token refreshes
          await _updateTokenInBackend(newToken);
        });

      } catch (e) {
        AppLogger.error('Token error', e, null, 'FCM');
        _initialized = true; // Mark as initialized even on error
      }
    } else {
      AppLogger.warning('Notification permission denied', 'FCM');
      _initialized = true;
    }
  }

  /// Force refresh FCM token
  Future<String?> refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken(vapidKey: null);
      AppLogger.info('Token refreshed: ${_fcmToken?.substring(0, 20)}...', 'FCM');
      return _fcmToken;
    } catch (e) {
      AppLogger.error('Failed to refresh token', e, null, 'FCM');
      return null;
    }
  }

  /// Handle notification tap and navigate to appropriate screen
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    AppLogger.info('Handling notification tap navigation', 'FCM');
    // 🔄 NEW: Use async navigation that waits for router
    await NavigationService().handleNotificationTap(data);
  }

  void _setupMessageHandlers() {
    // Handle foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Foreground message received: ${message.messageId}', 'FCM');
      AppLogger.info('Data: ${message.data}', 'FCM');
      AppLogger.info('Has notification: ${message.notification != null}', 'FCM');

      // When app is in foreground, DON'T show notifications
      // User can already see the UI updates via WebSocket
      // Notifications should only appear when app is in background/killed
      AppLogger.info('App is open, skipping notification (WebSocket will handle UI updates)', 'FCM');
    });

    // Handle when user taps on notification (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      AppLogger.info('Notification tapped (app in background)', 'FCM');
      AppLogger.info('Data: ${message.data}', 'FCM');
      await _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state by tapping notification
    _messaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        AppLogger.info('App opened from terminated state via notification', 'FCM');
        AppLogger.info('Data: ${message.data}', 'FCM');
        // 🔄 NEW: Wait for router to be ready before navigating
        await NavigationService().waitForRouter();
        await _handleNotificationTap(message.data);
      }
    });
  }

  /// Update FCM token in backend
  Future<void> _updateTokenInBackend(String fcmToken) async {
    if (_currentAuthToken == null || _currentAuthToken!.isEmpty) {
      AppLogger.warning('No auth token available, skipping backend update', 'FCM');
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.updateFCMToken(_currentAuthToken!, fcmToken);
      AppLogger.success('Token updated in backend', 'FCM');
    } catch (e) {
      AppLogger.error('Failed to update token in backend', e, null, 'FCM');
    }
  }
}
