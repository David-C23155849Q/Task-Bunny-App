import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/services/tasks/task_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskOffersScreen extends StatelessWidget {
  final String? taskId;

  const TaskOffersScreen({super.key, this.taskId});

  Future<void> _acceptTask(BuildContext context, String taskId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final taskRef = FirebaseFirestore.instance.collection('tasks').doc(taskId);
    final offerRef = taskRef.collection('offers').doc(uid);

    final offerDoc = await offerRef.get();
    if (!offerDoc.exists || offerDoc['status'] != 'offered') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer no longer available or already responded.')),
      );
      return;
    }

    // Update task and offer
    await taskRef.update({
      'assignedTo': uid,
      'status': 'assigned',
    });

    await offerRef.update({'status': 'accepted'});

    // Mark other offers as rejected
    final otherOffers = await taskRef.collection('offers').get();
    for (var doc in otherOffers.docs) {
      if (doc.id != uid && doc['status'] == 'offered') {
        await doc.reference.update({'status': 'rejected'});
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task accepted!')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("User not authenticated."));
    }

    final offersQuery = FirebaseFirestore.instance
        .collectionGroup('offers')
        .where('workerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Task Offers')),
      body: StreamBuilder<QuerySnapshot>(
        stream: offersQuery.snapshots(),
        builder: (context, offerSnap) {
          if (offerSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final offers = offerSnap.data?.docs ?? [];

          if (offers.isEmpty) {
            return const Center(child: Text("No task offers yet."));
          }

          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (ctx, i) {
              final offer = offers[i];
              final taskId = offer.reference.parent.parent?.id;
              final status = offer['status'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('tasks').doc(taskId).get(),
                builder: (ctx, taskSnap) {
                  if (!taskSnap.hasData || !taskSnap.data!.exists) {
                    return const SizedBox();
                  }

                  final task = taskSnap.data!.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text("${task['category'] ?? 'Task'} - \$${task['price']}"),
                      subtitle: Text("${task['description'] ?? ''}\n📍 ${task['pickup']?['address'] ?? ''}"),
                      isThreeLine: true,
                      trailing: status == 'offered'
                          ? ElevatedButton(
                        onPressed: () => _acceptTask(context, taskId!),
                        child: const Text('Accept'),
                      )
                          : Text(status == 'accepted' ? 'Accepted' : 'Rejected',
                          style: TextStyle(
                            color: status == 'accepted' ? Colors.green : Colors.red,
                          )),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsScreen(taskId: taskId!),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
