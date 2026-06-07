import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../task_offer_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this during app initialization (e.g., after login)
  Future<void> init(BuildContext context) async {
    await _requestPermissions();
    await _saveTokenToFirestore(); // Automatically detect role
    await _setupForegroundMessageListener(context);
    _handleNotificationTap(context);
  }

  /// Request notification permissions (especially needed on iOS)
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted.');
    } else {
      debugPrint('⚠️ Notification permission declined.');
    }
  }

  /// Save current user's FCM token to Firestore under correct role
  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    // Detect role (customer or worker)
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final isCustomer = userDoc.exists;
    final collection = isCustomer ? 'users' : 'workers';

    await FirebaseFirestore.instance.collection(collection).doc(user.uid).update({
      'fcmToken': token,
    });

    debugPrint("📲 Token saved to Firestore ($collection): $token");
  }

  /// Show snackbar when receiving notifications in foreground
  Future<void> _setupForegroundMessageListener(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message: ${message.notification?.title}");

      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${message.notification!.title}\n${message.notification!.body ?? ""}",
              style: const TextStyle(fontSize: 14),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  /// Handle notification when user taps it and app opens from background
  void _handleNotificationTap(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      debugPrint("📦 Notification tap payload: $data");

      if (data.containsKey('screen')) {
        final screen = data['screen'];
        final taskId = data['taskId'];

        if (screen == 'taskDetail' && taskId != null) {
          Navigator.pushNamed(context, '/taskDetail', arguments: taskId);
        } else if (screen == 'taskOffers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskOffersScreen(taskId: taskId),
            ),
          );
        }
      }
    });
  }

  /// Background handler (required for top-level in main.dart)
  static Future<void> backgroundHandler(RemoteMessage message) async {
    debugPrint("🔔 Background notification: ${message.notification?.title}");
  }
}
