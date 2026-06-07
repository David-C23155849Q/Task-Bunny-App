import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'communications_page.dart';

class ErrandDesignPage extends StatefulWidget {
  @override
  _ErrandDesignPageState createState() => _ErrandDesignPageState();
}

class _ErrandDesignPageState extends State<ErrandDesignPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  String username = "";
  double searchContainerHeight = 276;

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  void fetchUsername() async {
    User? user = _auth.currentUser; // Get the current user
    if (user != null) {
      // Fetch the user's name from the database
      databaseReference.child('users/${user.uid}/name').once().then((snapshot) {
        setState(() {
          username = snapshot.snapshot.value != null ? snapshot.snapshot.value.toString() : "User";
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 122), // Space above

                  const Text(
                    "Welcome To Errand Buddy",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10), // Space below

                  // Display the username if it's available
                  Text(
                    username.isNotEmpty ? username : "Loading...",
                    style: TextStyle(
                      color: Colors.blue.shade400,
                      fontSize: 24,
                    ),
                  ),

                  const SizedBox(height: 2), // Space below

                  Image.asset(
                    "assets/images/people.png",
                  ),

                  const SizedBox(height: 122), // Space after image

                  const Text(
                    "Connect with workers and your errand done for you",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 22), // Space below
                ],
              ),
            ),
          ),
          // Positioned widget should be outside SingleChildScrollView
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // Change to 0 to position at the bottom
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => CommunicationsPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => CommunicationsPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Add functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.work,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}