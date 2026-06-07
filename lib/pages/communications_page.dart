import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class CommunicationsPage extends StatefulWidget {
  const CommunicationsPage({super.key});

  @override
  State<CommunicationsPage> createState() => _CommunicationsPageState();
}

class _CommunicationsPageState extends State<CommunicationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize Firebase Auth

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availabe Workers'),
      ),
      body: _buildUserList(),
    );
  }

  // Build a list of users
  Widget _buildUserList() {
    return FutureBuilder<DatabaseEvent>(
      future: FirebaseDatabase.instance.ref('workers').once(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error occurred while loading users.'));
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No users found.'));
        }

        final Map<dynamic, dynamic> usersMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final List<Widget> userList = usersMap.entries.map<Widget>((entry) {
          final user = entry.value;
          return _buildUserListItem(user, entry.key);
        }).toList();

        return ListView(children: userList); // Convert to list
      },
    );
  }

  // Build individual user list items
  Widget _buildUserListItem(Map<dynamic, dynamic> user, String userId) {
    // Display users except for the current user
    if (_auth.currentUser!.uid != userId) {
      return ListTile(
        //leading: user['photo'] != null
          //  ? CircleAvatar(
          //radius: 10,
          //backgroundImage: NetworkImage(user['profilePicture']),
        //)
        //    : CircleAvatar(
        //               backgroundImage: AssetImage('assets/images/default_avatar.png'), // Local asset
        //             ),
        title: Text(user['name'] ?? 'Unnamed User',
        style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
        ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? 'No email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4), // Space between email and workType
            Text(
              user['workType'] ?? 'No work type specified',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey, // Different color for workType
              ),
            ),
          ],
        ),
        onTap: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverUserEmail: user['email'],
                receiverUserName: user['name'],
                receiverUserID: userId,
                workType: 'workType',
              ),
            ),
          );
        },
      );
    } else {
      return Container(); // Empty container for the current user
    }
  }
}
