import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MyTasksScreen extends StatefulWidget {
  @override
  _MyTasksScreenState createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final database = FirebaseDatabase.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  late DatabaseReference _tasksRef;
  late DatabaseReference _notificationsRef;
  StreamSubscription<DatabaseEvent>? _tasksSub;
  StreamSubscription<DatabaseEvent>? _notificationsSub;

  List<Map<String, dynamic>> allTasks = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    _notificationsRef = database.ref("users/${currentUser.uid}/notifications");
    _tasksRef = database.ref("users/${currentUser.uid}/tasks");
    listenToNotifications();
    listenToTasks();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _notificationsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void initializeNotifications() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    flutterLocalNotificationsPlugin.initialize(settings);
  }

  void showLocalNotification(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_updates',
        'Task Updates',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  void listenToNotifications() {
    _notificationsSub = _notificationsRef.onChildAdded.listen((event) async {
      final notif = event.snapshot.value as Map?;
      if (notif != null) {
        final message = notif['message'] ?? "Task update";
        final title = notif['type'] ?? "Update";
        showLocalNotification(title, message);
        await event.snapshot.ref.remove();
      }
    });
  }

  void listenToTasks() {
    _tasksSub = _tasksRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        List<Map<String, dynamic>> temp = [];
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        for (var entry in data.entries) {
          final task = Map<String, dynamic>.from(entry.value);
          task['id'] = entry.key;

          // Fetch worker info if assigned
          if (task['workerId'] != null) {
            final workerSnap = await database.ref("workers/${task['workerId']}").get();
            if (workerSnap.exists) {
              final workerData = Map<String, dynamic>.from(workerSnap.value as Map);
              task['worker'] = {
                'id': task['workerId'],
                'name': workerData['name'],
                'photo': workerData['profilePic'],
                'rating': (workerData['rating'] != null)
                    ? double.tryParse(workerData['rating'].toString()) ?? 0.0
                    : 0.0,
                'bio': workerData['bio'] ?? '',
                'city': workerData['city'] ?? '',
                'categories': workerData['categories'] ?? [],
              };
            }
          }

          temp.add(task);
        }

        setState(() => allTasks = temp);
      } else {
        setState(() => allTasks = []);
      }
    });
  }

  void showWorkerProfile(Map worker) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: worker['photo'] != null
                    ? NetworkImage(worker['photo'])
                    : AssetImage('assets/images/avatar.png') as ImageProvider,
              ),
              SizedBox(height: 12),
              Text(worker['name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(worker['bio']),
              SizedBox(height: 6),
              Text('City: ${worker['city']}'),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildStarRating(worker['rating'] ?? 0),
                  SizedBox(width: 8),
                  Text('${(worker['rating'] ?? 0).toStringAsFixed(1)}/5'),
                ],
              ),
              SizedBox(height: 6),
              Text('Skills: ${worker['categories']?.join(', ') ?? ''}'),
            ],
          ),
        ),
      ),
    );
  }

  // Star rating widget showing full, half, and empty stars
  Widget buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  void showReviewDialog(String workerId, String taskId) async {
    final controller = TextEditingController();
    final ratingNotifier = ValueNotifier<double>(3); // default rating 3 stars

    // Check if this client already reviewed this task for this worker
    final existingSnap = await database
        .ref("workers/$workerId/ratings")
        .orderByChild("taskId")
        .equalTo(taskId)
        .get();

    bool alreadyReviewed = false;
    if (existingSnap.exists) {
      final Map ratingsMap = existingSnap.value as Map;
      for (var entry in ratingsMap.values) {
        if (entry['clientId'] == currentUser.uid) {
          alreadyReviewed = true;
          break;
        }
      }
    }

    if (alreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have already reviewed this task.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Leave a Review"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: ratingNotifier,
              builder: (_, value, __) => Slider(
                min: 1,
                max: 5,
                divisions: 4,
                label: "${value.toStringAsFixed(1)} ⭐",
                value: value,
                onChanged: (val) => ratingNotifier.value = val,
              ),
            ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(hintText: "Your feedback..."),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Submit"),
            onPressed: () async {
              final comment = controller.text.trim();
              final rating = ratingNotifier.value;

              if (comment.isNotEmpty) {
                final ref = database.ref("workers/$workerId/ratings").push();
                await ref.set({
                  'clientId': currentUser.uid,
                  'taskId': taskId,
                  'rating': rating,
                  'comment': comment,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });

                // Recalculate average rating
                final allRatingsSnap = await database.ref("workers/$workerId/ratings").get();
                if (allRatingsSnap.exists) {
                  final ratingsMap = Map<String, dynamic>.from(allRatingsSnap.value as Map);
                  double total = 0;
                  int count = 0;

                  for (var entry in ratingsMap.values) {
                    if (entry is Map && entry.containsKey('rating')) {
                      total += (entry['rating'] as num).toDouble();
                      count++;
                    }
                  }

                  if (count > 0) {
                    final avgRating = total / count;
                    await database.ref("workers/$workerId/rating").set(avgRating.toStringAsFixed(1));
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Review submitted")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildWorkerInfo(Map<String, dynamic>? worker, String? status, String taskId) {
    if (worker == null) return const Text("Not assigned");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: worker['photo'] != null
                  ? NetworkImage(worker['photo'])
                  : AssetImage('assets/images/avatar.png') as ImageProvider,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    buildStarRating(worker['rating'] ?? 0),
                    SizedBox(width: 6),
                    Text('${(worker['rating'] ?? 0).toStringAsFixed(1)}/5',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => showWorkerProfile(worker),
              child: Text("View Worker"),
            ),
            SizedBox(width: 10),
            if ((status ?? '').toLowerCase() == 'completed')
              OutlinedButton(
                onPressed: () => showReviewDialog(worker['id'], taskId),
                child: Text("Leave Review"),
              ),
          ],
        )
      ],
    );
  }

  List<Map<String, dynamic>> getTasksForTab(String tab) {
    if (tab == 'All') return allTasks;
    return allTasks.where((task) => (task['status'] ?? '').toLowerCase() == tab.toLowerCase()).toList();
  }

  Widget buildTaskList(String tabLabel) {
    final filteredTasks = getTasksForTab(tabLabel);
    if (filteredTasks.isEmpty) {
      return Center(child: Text("No $tabLabel tasks."));
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (_, index) {
        final task = filteredTasks[index];
        return Card(
          margin: EdgeInsets.all(10),
          child: ListTile(
            title: Text(task['title'] ?? 'No title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text("Status: ${task['status']}"),
                Text("Category: ${task['category']}"),
                SizedBox(height: 8),
                Text("Assigned Worker:"),
                buildWorkerInfo(task['worker'], task['status'], task['id']),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Tasks"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Pending"),
            Tab(text: "Completed"),
            Tab(text: "All"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTaskList("pending"),
          buildTaskList("completed"),
          buildTaskList("All"),
        ],
      ),
    );
  }
}
