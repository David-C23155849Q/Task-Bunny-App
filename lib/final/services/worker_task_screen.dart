import 'package:errand_app/final/services/tasks/task_details_screen.dart';
import 'package:errand_app/final/services/tasks/worker_task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerTasksScreen extends StatelessWidget {
  const WorkerTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Assigned Tasks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedWorkerId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return const Center(child: Text("You don't have any assigned tasks yet."));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(task['category']),
                  subtitle: Text(task['description']),
                  trailing: Text('\$${task['price'] ?? '0'}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerTaskDetailScreen(taskId: '',),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
