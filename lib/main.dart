import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup.dart';
import 'profile_page.dart';
import 'notification_page.dart'; // تأكد من وجود هذا الملف إذا كنت تستخدمه
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // *** إضافة جديدة ***
import 'dart:convert'; // *** إضافة جديدة ***

// *** إضافة جديدة: مفتاح للتحكم بالـ Navigator من خارج الـ Widgets ***
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// *** إضافة جديدة: للتعامل مع الإشعارات عندما يكون التطبيق مغلقاً ***
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // يمكنك إضافة أي منطق هنا إذا احتجت
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // *** تعديل: إعداد المستمعين للإشعارات ***
  await _setupFCM();

  runApp(const MyApp());
}

// *** دالة جديدة: لتنظيم إعدادات FCM ***
Future<void> _setupFCM() async {
  // طلب الأذونات
  await FirebaseMessaging.instance.requestPermission();

  // التعامل مع الإشعارات في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تحديث التوكن تلقائيًا
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': newToken,
      });
      print('✅ تم تحديث FCM Token تلقائيًا في Firestore');
    }
  });

  // تهيئة الإشعارات المحلية (لإظهارها داخل التطبيق)
  await _initializeLocalNotifications();
}

// *** دالة جديدة: لتهيئة flutter_local_notifications ***
Future<void> _initializeLocalNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // إعدادات الأندرويد
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // إعدادات عامة
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // عند النقر على الإشعار (سواء كان التطبيق في المقدمة أو الخلفية)
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        final Map<String, dynamic> data = json.decode(response.payload!);
        _navigateToPost(data['postId']);
      }
    },
  );

  // إنشاء قناة الإشعارات للأندرويد
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // الاستماع للإشعارات عندما يكون التطبيق في المقدمة
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'launch_background', // تأكد من وجود هذا الملف في res/drawable
          ),
        ),
        // تمرير البيانات المهمة (postId) عند النقر
        payload: json.encode(message.data),
      );
    }
  });

  // عند الضغط على الإشعار والتطبيق في الخلفية (وليس مغلق)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _navigateToPost(message.data['postId']);
  });
}

// *** دالة جديدة: للانتقال إلى صفحة البروفايل مع تحديد المنشور ***
void _navigateToPost(String? postId) {
  if (postId != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userId: FirebaseAuth.instance.currentUser?.uid,
          postIdToNavigateTo: postId,
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // *** تعديل: ربط الـ navigatorKey ***
      title: 'Olive land',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF606C38),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF606C38),
        ),
      ),
      home: const RootPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  void initState() {
    super.initState();
    // *** تعديل: التحقق من الإشعار الأولي عند فتح التطبيق وهو مغلق ***
    _handleInitialMessage();
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // تأخير بسيط لضمان بناء شجرة الـ Widgets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPost(initialMessage.data['postId']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // هنا يتم تحديد الصفحة الرئيسية بعد تسجيل الدخول
          // استخدام HomePage بدلاً من ProfilePage قد يكون أفضل
          // لكن سأتركها ProfilePage كما في الكود الأصلي
          return ProfilePage(
            user: snapshot.data,
            userId: snapshot.data?.uid,
          );
        }

        return const LoginPage();
      },
    );
  }
}
