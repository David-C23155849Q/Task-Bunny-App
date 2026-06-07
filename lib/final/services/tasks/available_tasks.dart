import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AvailableTasksScreen extends StatelessWidget {
  final String workerCity;
  final List<String> workerCategories;
  final String workerId;

  const AvailableTasksScreen({
    super.key,
    required this.workerCity,
    required this.workerCategories,
    required this.workerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Tasks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('status', isEqualTo: 'pending')
            .where('pickup.city', isEqualTo: workerCity)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allTasks = snapshot.data!.docs;
          final filteredTasks = allTasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return workerCategories.contains(data['category']);
          }).toList();

          if (filteredTasks.isEmpty) {
            return const Center(child: Text('No tasks available at the moment.'));
          }

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index].data() as Map<String, dynamic>;
              final taskId = filteredTasks[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(task['category']),
                  subtitle: Text(task['description']),
                  trailing: ElevatedButton(
                    child: const Text('Accept'),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(taskId)
                          .update({
                        'assignedWorkerId': workerId,
                        'status': 'assigned',
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Task accepted')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
