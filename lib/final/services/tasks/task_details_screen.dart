import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tasks').doc(taskId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final task = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category: ${task['category']}", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text("Description: ${task['description']}"),
                const SizedBox(height: 10),
                Text("Price: \$${task['price']}"),
                const SizedBox(height: 10),
                Text("Pickup Address: ${task['pickup']['address']}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
