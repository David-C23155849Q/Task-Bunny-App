import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:errand_app/final/login_screen.dart';
import 'package:errand_app/final/services/tasks/task_details_screen.dart';

import '../firebase_options.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

/// Background notification handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}

  debugPrint(
      "Background notification: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseApp app;

  try {
    if (Firebase.apps.isEmpty) {
      app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase initialized: ${app.name}");
    } else {
      app = Firebase.app();
      debugPrint("Firebase already initialized: ${app.name}");
    }
  } catch (e) {
    app = Firebase.app();
    debugPrint("Using existing Firebase app: ${app.name}");
  }

  FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();

  switch (prefs.getString("theme")) {
    case "light":
      themeNotifier.value = ThemeMode.light;
      break;

    case "dark":
      themeNotifier.value = ThemeMode.dark;
      break;

    default:
      themeNotifier.value = ThemeMode.system;
  }

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final data = message.data;

    if (data["taskId"] != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(
            taskId: data["taskId"],
          ),
        ),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}