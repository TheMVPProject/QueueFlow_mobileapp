import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

    await _notifications.initialize(initSettings);
  }

  Future<void> showYourTurnNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'queue_channel',
      'Queue Notifications',
      channelDescription: 'Notifications for queue updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🎉 It\'s Your Turn!',
      'Please confirm your presence within 3 minutes',
      notificationDetails,
    );
  }

  Future<void> showTimeoutWarning() async {
    const androidDetails = AndroidNotificationDetails(
      'queue_channel',
      'Queue Notifications',
      channelDescription: 'Notifications for queue updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
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

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
