import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notificación background: ${message.messageId}');
}

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> inicializar() async {
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Init local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Canal Android
    const AndroidNotificationChannel canal = AndroidNotificationChannel(
      'tuki_canal',
      'Tuki Notificaciones',
      description: 'Notificaciones de pedidos',
      importance: Importance.high,
    );

   final androidPlugin = _localNotifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
await androidPlugin?.createNotificationChannel(canal);

    // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final notif = message.notification;
  if (notif != null) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'tuki_canal',
        'Tuki Notificaciones',
        channelDescription: 'Notificaciones de pedidos',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    _localNotifications.show(
      notif.hashCode,
      notif.title,
      notif.body,
      details,
    );
  }
});
  }

  static Future<String?> obtenerToken() async {
    try {
      final String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error obteniendo FCM token: $e');
      return null;
    }
  }

  static void escucharTokenRefresh(Function(String) onToken) {
    _messaging.onTokenRefresh.listen(onToken);
  }
}