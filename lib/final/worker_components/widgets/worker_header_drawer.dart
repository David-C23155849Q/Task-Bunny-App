import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../woker_profile_view.dart';
import '../../worker_profile_tab.dart';

class WorkerHeaderDrawer extends StatelessWidget {
  final String name;
  final String? photoUrl; // this is actually BASE64 in your case
  final VoidCallback onLogout;
  final VoidCallback onProfile;

  const WorkerHeaderDrawer({
    super.key,
    required this.name,
    required this.onLogout,
    required this.onProfile,
    this.photoUrl,
  });

  Uint8List? _decodeImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;

    try {
      return base64Decode(base64Str);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeImage(photoUrl);

    return Drawer(
      child: Column(
        children: [
          /// HEADER
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black54],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// PROFILE IMAGE (FIXED)
                CircleAvatar(
                  radius: 38,
                  backgroundImage:
                  imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),

                const SizedBox(height: 12),

                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Worker Dashboard",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// MENU ITEMS
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);

              final uid = FirebaseAuth.instance.currentUser!.uid;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerProfileViewScreen(uid: uid),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Task History"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {},
          ),

          const Spacer(),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}