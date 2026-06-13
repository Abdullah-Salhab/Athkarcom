import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

import '../main.dart';
import 'offlineAthkar/counter_page.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static String? pendingPayload;
  static bool isAppLoaded = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Amman'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Check if the app was launched by clicking a notification
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails != null &&
        notificationAppLaunchDetails.didNotificationLaunchApp) {
      pendingPayload = notificationAppLaunchDetails.notificationResponse?.payload;
    }
  }

  Future<void> scheduleDailyNotifications() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_notification_channel', // Channel ID
      'Daily Notifications', // Channel Name
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Schedule 8:00 AM notification
    await flutterLocalNotificationsPlugin
        .zonedSchedule(
          0, // Notification ID
          'أذكار الصباح',
          'ابدأ يومك بأذكار الصباح',
          _nextInstanceOfTime(7, 30), // 7:30 AM
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'navigate_to_morning_screen',
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle, // Add this parameter
        )
        .onError((error, stackTrace) => print(error.toString()));

    // Schedule 9:00 PM notification
    await flutterLocalNotificationsPlugin
        .zonedSchedule(
          1, // Notification ID
          'أذكار المساء',
          'اختتم يومك بأذكار المساء',
          _nextInstanceOfTime(19, 0), // 7:00 PM
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'navigate_to_evening_screen',
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle, // Add this parameter
        )
        .onError((error, stackTrace) => print(error.toString()));
  }

  Future<void> onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    String? payload = response.payload;

    if (payload != null) {
      if (isAppLoaded) {
        navigateToScreen(payload);
      } else {
        pendingPayload = payload;
      }
    }
  }

  static void navigateToScreen(String payload) {
    if (payload == 'navigate_to_morning_screen') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const CounterPage(
            id: 1,
            title: "أذكار الصباح",
          ),
        ),
      );
    } else if (payload == 'navigate_to_evening_screen') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const CounterPage(
            id: 2,
            title: "أذكار المساء",
          ),
        ),
      );
    }
  }
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  // If the scheduled time has passed today, schedule it for tomorrow
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}
