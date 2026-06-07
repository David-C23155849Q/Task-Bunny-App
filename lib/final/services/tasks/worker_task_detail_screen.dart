import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkerTaskDetailScreen extends StatelessWidget {
  final String taskId;

  const WorkerTaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tasks').doc(taskId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Task not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final pickup = data['pickup'] ?? {};
          final description = data['description'] ?? 'No description';
          final price = data['price']?.toString() ?? 'N/A';
          final category = data['category'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text("📌 Task ID: $taskId", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text("📍 Address: ${pickup['address'] ?? 'N/A'}"),
                Text("🏙️ City: ${pickup['city'] ?? 'N/A'}"),
                Text("💰 Price: \$${price}"),
                Text("📂 Category: $category"),
                const SizedBox(height: 16),
                Text("📝 Description:", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Mark as Accepted"),
                  onPressed: () {
                    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
                      'status': 'accepted',
                      'acceptedAt': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task marked as accepted")),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
