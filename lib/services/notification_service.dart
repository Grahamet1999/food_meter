import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps local notification setup and display.
///
/// Expiration reminders themselves are scheduled server-side (see the
/// `sendExpiringItemNotifications` Cloud Function), which re-checks live
/// Firestore data every day, so a single deleted/edited item can't leave a
/// stale reminder behind and each item is only reminded about once. This
/// service is only responsible for local device setup and for surfacing a
/// notification when an FCM message arrives while the app is in the
/// foreground (Android/iOS don't display those automatically).
///
/// No-ops entirely on web: flutter_local_notifications has no web
/// implementation, and `dart:io`'s `Platform` throws if touched on web, so
/// every method below bails out via [kIsWeb] before going near either.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  /// Requests notification permissions on iOS and (Android 13+) Android.
  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  /// Shows an immediate notification, used to surface a foreground FCM message.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiring_items_channel',
          'Expiring Items',
          channelDescription: 'Notifications for items about to expire',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
