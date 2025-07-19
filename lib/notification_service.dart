// notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'profile_page.dart'; // تأكد من استيراد صفحة البروفايل

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final Map<String, dynamic> data = json.decode(response.payload!);
          if (data['postId'] != null) {
            // استخدم navigatorKey للانتقال إلى صفحة البروفايل مع تحديد المنشور
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  // هنا يجب أن يكون لديك طريقة لتمرير postId إلى ProfilePage
                  // قد تحتاج إلى تعديل ProfilePage لاستقبال postId والبحث عنه
                  // هذا مثال مبسط
                  postIdToNavigateTo: data['postId'],
                ),
              ),
            );
          }
        }
      },
    );

    // التعامل مع الإشعارات عندما يكون التطبيق في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // معرف القناة
              'High Importance Notifications', // اسم القناة
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: json.encode(message.data), // تمرير البيانات الإضافية
        );
      }
    });

    // التعامل مع الإشعارات عند النقر عليها والتطبيق في الخلفية أو مغلق
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['postId'] != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              postIdToNavigateTo: message.data['postId'],
            ),
          ),
        );
      }
    });
  }
}
