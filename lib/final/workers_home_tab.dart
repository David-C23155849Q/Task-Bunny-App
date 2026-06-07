import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/services/tasks/worker_task_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  double? firestoreRating;
  String? _lastShownTaskId;
  DateTime? _lastDialogTime;
  Duration _cooldown = const Duration(seconds: 30);



  Map<String, dynamic>? worker;
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _listenForAssignedTasks(); // 🔥
  }




  void _listenForAssignedTasks() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('tasks')
        .where('workerId', isEqualTo: uid)
        .where('status', isEqualTo: 'assigned')
        .where('hasSeenByWorker', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final taskId = doc.id;
      final taskData = doc.data();

      // Skip if already shown recently (optional cooldown)
      final now = DateTime.now();
      if (_lastShownTaskId == taskId &&
          _lastDialogTime != null &&
          now.difference(_lastDialogTime!) < _cooldown) {
        return;
      }

      _lastShownTaskId = taskId;
      _lastDialogTime = now;

      //_playNotificationSound();
      _showNewTaskDialog(taskData, taskId);
    });

  }



  void _showNewTaskDialog(Map<String, dynamic> taskData, String taskId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('🆕 New Task Assigned'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍 Location: ${taskData['pickup']['address']}'),
              const SizedBox(height: 8),
              Text('💰 Price: \$${taskData['price']}'),
              const SizedBox(height: 8),
              Text('📝 Description: ${taskData['description']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(taskId)
                    .update({'hasSeenByWorker': true});
              },
              child: const Text('Ignore'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(taskId)
                    .update({'hasSeenByWorker': true});
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkerTaskDetailScreen(taskId: '',),
                  ),
                );
              },
              child: const Text('View Task'),
            ),
          ],
        );
      },
    );
  }




  Future<void> _fetchData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final wdoc = await _firestore.collection('workers').doc(uid).get();
    final rdocs = await _firestore
        .collection('workers')
        .doc(uid)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .get();

    setState(() {
      worker = wdoc.data();
      reviews = rdocs.docs.map((e) => e.data()).toList();
      firestoreRating = worker?['rating']?.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (worker == null) return const Center(child: CircularProgressIndicator());

    final t = Theme.of(context);
    final username = worker!['username'] ?? '';
    final city = worker!['city'] ?? '';
    final skills = List<String>.from(worker!['categories'] ?? []);
    final pic = worker!['profileImageUrl'];

    final earningsToday = worker!['earningsToday'] ?? 0.0;
    final completedTasks = worker!['completedTasksToday'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            color: Colors.blue[50],
            child: ListTile(
              leading: const Icon(Icons.handshake),
              title: Text('Hey $username 👋',
                style: TextStyle(fontWeight: FontWeight.bold) ,),
              subtitle: const Text('Welcome back to your dashboard.Let`s get some work done today!'),
            ),
          ),
          const SizedBox(height: 6),
          Card(
            color: Colors.red[50],
            child: ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: Colors.orange,),
              //title: Text('Hey $username 👋'),
              subtitle: const Text('Pro tip: Completing more tasks helps you rank higher and get more clients!'),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: pic != null ? NetworkImage(pic) : null,
                child: pic == null ? const Icon(Icons.person, size: 30) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: t.textTheme.titleMedium),
                  Text(city, style: t.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  firestoreRating == null || firestoreRating == 0.0
                      ? const Text("⭐ No rating yet",
                      style: TextStyle(color: Colors.grey))
                      : Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        firestoreRating!.toStringAsFixed(1),
                        style: t.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 20),

          // 🔍 Today Summary
          Text("📊 Today's Summary", style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              _summaryCard("Earnings Today", "\$${earningsToday.toStringAsFixed(2)}", Icons.attach_money),
              const SizedBox(height: 10),
              _summaryCard("Completed Tasks", "$completedTasks", Icons.check_circle),
            ],
          ),
          const SizedBox(height: 24),

          // 🧰 Skills
          Text('💼 Your Skills', style: t.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: skills.map((s) => Chip(label: Text(s))).toList()),
          const SizedBox(height: 24),

          // ⭐ Recent Reviews
          Text('📝 Recent Reviews', style: t.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            const Text('No reviews yet.', style: TextStyle(color: Colors.grey))
          else
            ...reviews.map((r) {
              final rating = (r['rating'] ?? 0).toInt();
              return Card(
                child: ListTile(
                  title: Text(r['reviewerName'] ?? 'Client'),
                  subtitle: Text(r['text'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(rating, (_) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                  ),
                ),
              );
            }),
        ]),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }
}
