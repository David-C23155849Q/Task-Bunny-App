import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'worker_profile_tab.dart';

class WorkerProfileViewScreen extends StatelessWidget {
  final String uid;
  const WorkerProfileViewScreen({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Worker Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('workers').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Worker not found"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          Uint8List? imageBytes = data['profileImageBase64'] != null ? base64Decode(data['profileImageBase64']) : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                /// Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 50, backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null, child: imageBytes == null ? const Icon(Icons.person, size: 50) : null),
                      const SizedBox(height: 16),
                      Text(data['username'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(data['name'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 12),
                      _buildRatingRow((data['rating'] ?? 0).toDouble()),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                /// Info Section
                _buildSection("Contact Details", [
                  _buildIconTile(Icons.phone_rounded, data['phone'] ?? "N/A"),
                  _buildIconTile(Icons.email_rounded, data['email'] ?? "N/A"),
                  _buildIconTile(Icons.location_on_rounded, data['city'] ?? "N/A"),
                ]),

                _buildSection("About", [Text(data['bio'] ?? "No bio provided", style: TextStyle(color: Colors.grey.shade700, height: 1.5))]),

                _buildSection("Skills", [Wrap(spacing: 8, runSpacing: 8, children: List<String>.from(data['categories'] ?? []).map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.blue.withOpacity(0.05), side: BorderSide.none)).toList())]),

                const SizedBox(height: 30),

                /// Action Button
                SizedBox(
                  width: double.infinity, height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerProfileScreen(uid: uid))),
                    style: FilledButton.styleFrom(backgroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("EDIT PROFILE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ...children
      ]),
    );
  }

  Widget _buildIconTile(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(icon, size: 18, color: Colors.blueAccent), const SizedBox(width: 12), Text(text)]),
  );

  Widget _buildRatingRow(double rating) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(5, (index) => Icon(index < rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 24)),
  );
}