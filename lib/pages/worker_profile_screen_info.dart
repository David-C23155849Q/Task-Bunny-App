import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class WorkerProfileScreenInfo extends StatelessWidget {
  final String userID;

  const WorkerProfileScreenInfo({Key? key, required this.userID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker`s Profile"),
      ),
      body: FutureBuilder<Map<dynamic, dynamic>>(
        future: _fetchUserProfile(userID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("User not found."));
          }

          final userData = snapshot.data!;

          return Center( // Center the content
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                children: [
                  CircleAvatar(
                    radius: 100,
                    backgroundImage: userData['photo'] != null
                        ? NetworkImage(userData['photo'])
                        : const AssetImage("assets/images/profile_avatar.png") as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData['name'] ?? 'Loading...',
                    style: const TextStyle(fontSize: 34,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData['email'] ?? 'Loading...',
                    style: const TextStyle(fontSize: 16,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData['phone'] ?? 'Loading...',
                    style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData['workType'] ?? 'Loading...',
                    style: const TextStyle(fontSize: 16,
                        color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<dynamic, dynamic>> _fetchUserProfile(String userId) async {
    final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('workers/$userId');
    final DatabaseEvent event = await userRef.once();

    final DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      return snapshot.value as Map<dynamic, dynamic>; // Return the user data
    } else {
      throw Exception("User not found");
    }
  }
}