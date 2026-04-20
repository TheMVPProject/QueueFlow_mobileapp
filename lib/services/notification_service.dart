import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:queueflow_mobileapp/services/navigation_service.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        AppLogger.info('Notification tapped', 'NotificationService');
        AppLogger.info('Payload: ${response.payload}', 'NotificationService');

        // Delay navigation to ensure app is fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
          final payload = response.payload;

          if (payload == 'user_joined') {
            AppLogger.info('Navigating to /admin (user joined)', 'NotificationService');
            NavigationService().navigateTo('/admin');
          } else if (payload == 'your_turn') {
            AppLogger.info('Navigating to /your-turn', 'NotificationService');
            NavigationService().navigateTo('/your-turn');
          } else {
            // Default to your-turn for backward compatibility
            AppLogger.info('Navigating to /your-turn (default)', 'NotificationService');
            NavigationService().navigateTo('/your-turn');
          }
        });
      },
    );

    // Create notification channel for Android (CRITICAL for background notifications)
    await _createNotificationChannel();

    // Request notification permissions for Android 13+
    await _requestPermissions();
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'queue_channel', // Must match the channel ID used in notifications
      'Queue Notifications',
      description: 'Notifications for queue updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      AppLogger.info('Notification channel created', 'NotificationService');
    }
  }

  Future<void> _requestPermissions() async {
    // For Android 13+ (API 33+), request notification permission
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // For iOS, permissions are requested during initialization above
  }

  /// Helper method to build common Android notification details
  AndroidNotificationDetails _buildAndroidDetails({
    Importance importance = Importance.max,
    Priority priority = Priority.high,
    bool showWhen = false,
    String? ticker,
  }) {
    return AndroidNotificationDetails(
      'queue_channel',
      'Queue Notifications',
      channelDescription: 'Notifications for queue updates',
      importance: importance,
      priority: priority,
      showWhen: showWhen,
      enableVibration: true,
      playSound: true,
      ticker: ticker,
    );
  }

  Future<void> showYourTurnNotification() async {
    AppLogger.info('Attempting to show notification', 'NotificationService');

    final androidDetails = _buildAndroidDetails(
      showWhen: true,
      ticker: 'Your turn in queue',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🎉 It\'s Your Turn!',
      'Please confirm your presence within 3 minutes',
      notificationDetails,
      payload: 'your_turn', // Add payload for tap handling
    );

    AppLogger.success('Notification triggered', 'NotificationService');
  }

  Future<void> showTimeoutWarning() async {
    final androidDetails = _buildAndroidDetails(
      importance: Importance.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      '⚠️ Time Running Out!',
      'Less than 1 minute remaining to confirm',
      notificationDetails,
    );
  }

  Future<void> showUserJoinedNotification({String? username}) async {
    AppLogger.info('Showing user joined notification', 'NotificationService');

    final androidDetails = _buildAndroidDetails(
      showWhen: true,
      ticker: 'New user in queue',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final usernameText = username != null && username.isNotEmpty
        ? username
        : 'A user';

    await _notifications.show(
      2,
      '👤 New User Joined',
      '$usernameText has joined the queue',
      notificationDetails,
      payload: 'user_joined', // Add payload for tap handling
    );

    AppLogger.success('User joined notification triggered', 'NotificationService');
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
