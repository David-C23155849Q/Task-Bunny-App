import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  // Send Message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    Map<String, dynamic> newMessage = {
      'sender_id': currentUserId,
      'sender_email': currentUserEmail,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp,
    };

    // Construct chat room ID
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Add message to the database
    await _databaseReference.child('chat_rooms/$chatRoomId/messages').push().set(newMessage);
  }

  // Get Messages
  Stream<List<Map<String, dynamic>>> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _databaseReference.child('chat_rooms/$chatRoomId/messages').onValue.map((event) {
      final List<Map<String, dynamic>> messages = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          messages.add(Map<String, dynamic>.from(value)); // Convert to Map
        });
      }

      return messages;
    });
  }

  // Delete Message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _databaseReference.child('chat_rooms/$chatRoomId/messages/$messageId').remove();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  // Get Work Type
  Future<String?> getWorkType(String userId) async {
    final snapshot = await _databaseReference.child('workers/$userId/resources').once();
    if (snapshot.snapshot.value != null) { // Check if data exists
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data['workType'] as String?;
    }
    return null; // Return null if not found
  }
}