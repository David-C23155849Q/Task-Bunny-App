import 'dart:convert';
import 'package:http/http.dart' as http;

class FCMService {
  static const String _serverKey = 'YOUR_SERVER_KEY_HERE'; // 🔐 Replace with your FCM server key

  static Future<void> sendNotificationToWorker({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": title,
            "body": body,
            "sound": "default",
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "status": "done",
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent to worker');
      } else {
        print('❌ Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('❗ Error sending FCM: $e');
    }
  }
}
