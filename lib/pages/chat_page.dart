import 'package:errand_app/assistants/chat_service.dart';
import 'package:errand_app/pages/worker_profile_screen_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  final String workType;
  final String receiverUserName;

  ChatPage({
    Key? key,
    required this.receiverUserName,
    required this.receiverUserEmail,
    required this.receiverUserID,
    required this.workType,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final DatabaseReference _usersReference = FirebaseDatabase.instance.ref().child('users');

  bool areAllFieldsFilled() {
    return _messageController.text.isNotEmpty && _amountController.text.isNotEmpty;
  }

  void sendMessage() async {
    if (areAllFieldsFilled()) {
      String combinedMessage = "Errand: ${_messageController.text}, Amount: \$${_amountController.text}";
      await _chatService.sendMessage(widget.receiverUserID, combinedMessage);
      _messageController.clear();
      _amountController.clear();
    } else {
      _showErrorDialog('Please fill in all fields before sending the message.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void deleteMessage(String messageId) async {
    List<String> ids = [_firebaseAuth.currentUser!.uid, widget.receiverUserID];
    ids.sort();
    String chatRoomId = ids.join("_");
    await _chatService.deleteMessage(chatRoomId, messageId);
  }

  Widget _buildMessageItem(Map<String, dynamic> data, String profilePictureUrl) {
    var isCurrentUserSender = (data['sender_id'] == _firebaseAuth.currentUser!.uid);
    var alignment = isCurrentUserSender ? Alignment.centerRight : Alignment.centerLeft;

    return GestureDetector(
      onLongPress: () {
        if (isCurrentUserSender) {
          _showDeleteConfirmation(data['id']);
        }
      },
      child: Column(
        children: [
          Container(
            alignment: alignment,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: isCurrentUserSender ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isCurrentUserSender)
                  CircleAvatar(
                    backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                    child: profilePictureUrl.isEmpty ? Icon(Icons.account_circle, color: Colors.green) : null,
                    radius: 20,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isCurrentUserSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(data['sender_email']),
                      const SizedBox(height: 5),
                      ChatBubble(message: data['message']),
                    ],
                  ),
                ),
                if (isCurrentUserSender)
                  CircleAvatar(
                    backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                    child: profilePictureUrl.isEmpty ? Icon(Icons.account_circle, color: Colors.blue) : null,
                    radius: 20,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Message?'),
          content: Text('Are you sure you want to delete this message?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                deleteMessage(messageId);
                Navigator.pop(context);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getProfilePictureUrl(String userId) async {
    String profilePictureUrl = '';
    try {
      DataSnapshot usersSnapshot = await _usersReference.child(userId).child('photo').once().then((data) => data as DataSnapshot);
      if (usersSnapshot.exists) {
        profilePictureUrl = usersSnapshot.value.toString();
      }
      DataSnapshot workersSnapshot = await _usersReference.child(userId).child('photo').once().then((data) => data as DataSnapshot);
      if (workersSnapshot.exists) {
        profilePictureUrl = workersSnapshot.value.toString();
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
    return profilePictureUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkerProfileScreenInfo(userID: widget.receiverUserID),
              ),
            );
          },
          child: Text(widget.receiverUserName),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getMessages(widget.receiverUserID, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No messages'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return FutureBuilder<String>(
              future: _getProfilePictureUrl(snapshot.data![index]['sender_id']),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                return _buildMessageItem(snapshot.data![index], profileSnapshot.data ?? '');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Enter Errand',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _amountController,
              decoration: InputDecoration(
                prefixText: '\$',
                prefixStyle: TextStyle(color: Colors.green, fontSize: 16),
                hintText: 'Enter Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.send, size: 40),
          ),
        ],
      ),
    );
  }
}