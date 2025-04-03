import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingAPI {
  // get firebase messaging
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission for iOS
    FirebaseMessaging.instance.requestPermission();

    // Get the FCM token
    FirebaseMessaging.instance.getToken().then((token) {
      // print("FCM Token: $token");
    });
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      flutterLocalNotificationsPlugin.show(
        100,
        message.notification?.title,
        message.notification?.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'FCM_Channel_ID',
            'FCM Notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification_sound'),
          ),
        ),
      );
    });

    // Handle background messages
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('Message clicked! ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ ');
    // });
  }
}
