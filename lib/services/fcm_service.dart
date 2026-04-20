import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:queueflow_mobileapp/services/notification_service.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Background] Message received: ${message.messageId}');

  // Show notification when message received in background
  if (message.notification != null) {
    await NotificationService().showYourTurnNotification();
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('[FCM] Token: $_fcmToken');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('[FCM] Token refreshed: $newToken');
        // TODO: Send updated token to backend
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('[FCM Foreground] Message received: ${message.messageId}');
        print('[FCM Foreground] Title: ${message.notification?.title}');
        print('[FCM Foreground] Body: ${message.notification?.body}');

        // Show notification when app is in foreground
        NotificationService().showYourTurnNotification();
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('[FCM] Notification tapped: ${message.messageId}');
        // TODO: Navigate to appropriate screen
      });

      // Check if app was opened from terminated state via notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('[FCM] App opened from terminated state: ${initialMessage.messageId}');
        // TODO: Navigate to appropriate screen
      }
    }
  }
}
