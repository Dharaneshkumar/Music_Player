import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // Request notification permission (will be handled gracefully if activity not ready)
      await Permission.notification.request();
    } catch (e) {
      debugPrint('Permission request deferred: $e');
    }

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
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      debugPrint('Notification permission status: $status');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }


  Future<void> showNowPlayingNotification({
    required String title,
    required String artist,
    bool isPlaying = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'music_player_channel',
      'Music Player',
      channelDescription: 'Music playback notifications',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      usesChronometer: false,
      subText: isPlaying ? 'Playing' : 'Paused',
      styleInformation: const MediaStyleInformation(
        htmlFormatContent: true,
        htmlFormatTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      artist,
      details,
      payload: 'music_player',
    );
  }

  Future<void> cancelNotification() async {
    await _notifications.cancel(0);
  }

  Future<void> showPlaybackNotification({
    required String title,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'playback_channel',
      'Playback Notifications',
      channelDescription: 'Notifications for playback events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      title,
      message,
      details,
    );
  }
}
