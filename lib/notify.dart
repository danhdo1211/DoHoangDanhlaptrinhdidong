import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notify {
  static final _p = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _p.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    await _p
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> show(String title, String body) => _p.show(
    1,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails('otp', 'Mã OTP',
          importance: Importance.max, priority: Priority.high),
    ),
  );
}