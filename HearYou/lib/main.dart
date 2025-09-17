import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

import 'theme_provider.dart';
import 'login.dart';
import 'home.dart';
import 'weekly_report_page.dart';
import 'view/app_view.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = appNavigatorKey;

const AndroidNotificationChannel defaultAndroidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Channel for important notifications',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission();
  await FacebookAuth.instance.webAndDesktopInitialize(
    appId: "2034488243722567",
    cookie: true,
    xfbml: true,
    version: "v17.0",
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Create Android notification channel
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(defaultAndroidChannel);
  // Android 13+ runtime notification permission
  // Note: Requesting Android 13+ notification permission should be handled
  // via the OS permission dialog or plugin updates; skipping explicit call here.

  await FirebaseMessaging.instance.requestPermission();

  // Foreground message handler: show local notification if enabled
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notificationsEnabled') ?? true;
      if (!enabled) return;

      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        await flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          notification.title ?? 'Notification',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              defaultAndroidChannel.id,
              defaultAndroidChannel.name,
              channelDescription: defaultAndroidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    } catch (_) {}
  });

  // Handle notification taps when the app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    try {
      final data = message.data;
      if (data['type'] == 'weekly_report') {
        navigatorKey.currentState?.pushNamed('/weeklyReport');
      }
    } catch (_) {}
  });

  // Obtain FCM token and register with backend
  try {
    final token = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmTokenLast': token},
        SetOptions(merge: true),
      );
      // Best-effort register to backend auth server if reachable
      // API_BASE is provided from --dart-define (same as app)
      const String apiBase = String.fromEnvironment(
        'API_BASE',
        defaultValue: 'http://10.0.2.2:5000',
      );
      try {
        await http.post(
          Uri.parse('$apiBase/auth/register-fcm'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uid': user.uid, 'token': token}),
        );
      } catch (_) {}
    }
  } catch (_) {}

  // Realtime DB listener: show local notification when Notifications/message changes
  try {
    final DatabaseReference notificationsRef = FirebaseDatabase.instance.ref('Notifications');
    notificationsRef.onValue.listen((DatabaseEvent event) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('notificationsEnabled') ?? true;
        if (!enabled) return;

        final value = event.snapshot.value;
        String? message;
        String? control;
        if (value is Map) {
          final m = value['message'];
          final c = value['notification_control'];
          if (m is String) message = m;
          if (c is String) control = c;
        }
        if (control == 'disable') return;
        if (message != null && message != 'NULL') {
          await flutterLocalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch.remainder(100000),
            'Notification',
            message,
            NotificationDetails(
              android: AndroidNotificationDetails(
                defaultAndroidChannel.id,
                defaultAndroidChannel.name,
                channelDescription: defaultAndroidChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        }
      } catch (_) {}
    });
  } catch (_) {}

  runApp(ChangeNotifierProvider(create: (context) => ThemeProvider(), child: const MyAppView()));
  // Ensure an initial screen is shown
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  });

  // Handle notification tap when app launched from terminated state
  try {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data['type'] == 'weekly_report') {
      // Delay to ensure navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed('/weeklyReport');
      });
    }
  } catch (_) {}
}

// App shell moved to view/MyAppView; we push Splash after runApp

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

void _checkLoginStatus() async {
  await Future.delayed(const Duration(seconds: 2));
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Provider.of<ThemeProvider>(context).isDarkMode
                ? [Colors.black, Colors.grey[900]!, Colors.black87]
                : [
                    Color.fromARGB(255, 236, 184, 201),
                    Colors.white,
                    Color.fromARGB(255, 212, 184, 243),
                  ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/logo.png',
                      width: 140,
                      height: 140,
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      color: Color.fromARGB(255, 16, 12, 31),
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Helping Deaf Mothers Care for Their Babies",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 24, 18, 44),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Smart Alerts for a Safer Motherhood",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 23, 17, 43),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
