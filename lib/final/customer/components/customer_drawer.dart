// lib/customer/components/custom_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../customer_profile_screen.dart';
import '../customer_settings.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            final userData = snapshot.data ?? {};
            final name = userData['username'] ?? 'User';
            final rating = userData['rating']?.toStringAsFixed(1) ?? '';
            final profileImage = userData['profileImage'];

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(name),
                  accountEmail: Text(rating),
                  currentAccountPicture: profileImage != null
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(profileImage),
                  )
                      : const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  decoration: const BoxDecoration(color: Colors.indigo),
                ),

                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: const Text("City"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("Request history"),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to history screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notifications"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.shield),
                  title: const Text("Safety"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text("Help"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.support),
                  title: const Text("Support"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout"),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                  },
                ),

                const Spacer(),

                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Switch to driver mode
                  },
                  icon: const Icon(Icons.switch_left),
                  label: const Text("Driver Mode"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[700],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.facebook, color: Colors.blue),
                      onPressed: () {
                        // TODO: Link to Facebook
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.pink),
                      onPressed: () {
                        // TODO: Link to Instagram
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
