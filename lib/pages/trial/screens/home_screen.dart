import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'client_profile_page.dart';
import 'my_tasks_screen.dart';
import 'post_task_errand.dart';
import 'services/settings_screen.dart';
import 'task_review_page.dart';

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final database = FirebaseDatabase.instance;

  String userName = 'Client';
  String? profilePicUrl;
  List<Map<String, dynamic>> recentTasks = [];
  int _currentIndex = 0;
  int unreadTaskCount = 0;
  int unreadMessageCount = 0;

  late DatabaseReference _notificationsRef;
  StreamSubscription<DatabaseEvent>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
    _saveDeviceToken();
    fetchUserData();
    fetchRecentTasks();

    if (currentUser != null) {
      _notificationsRef = database.ref("users/${currentUser!.uid}/notifications");
      listenToClientNotifications();
    }

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message?.data != null) {
        _handleNotificationTap(message!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }



  void _initializeFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages, optionally show a dialog or toast here
      print("📩 Foreground FCM message received: ${message.notification?.title}");
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('taskData')) {
      try {
        final taskData = Map<String, dynamic>.from(data['taskData']);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskReviewPage(taskData: taskData)),
        );
      } catch (_) {}
    }
  }

  void listenToClientNotifications() {
    _notificationsSubscription = _notificationsRef.onChildAdded.listen((event) async {
      final notif = event.snapshot.value as Map<dynamic, dynamic>?;

      if (notif == null) return;

      final type = notif['type'] ?? "Task Update";
      final message = notif['message'] ?? "You have a task update";
      final taskData = Map<String, dynamic>.from(notif['taskData'] ?? {});

      if (type == 'task_status' && message.toLowerCase().contains('declined')) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Task Declined"),
            content: Text("$message\nWould you like to reassign this task?"),
            actions: [
              TextButton(
                  child: Text("Later"),
                  onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                child: Text("Reassign Task"),
                onPressed: () {
                  Navigator.pop(context);
                  if (taskData.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              TaskReviewPage(taskData: taskData)),
                    );
                  }
                },
              ),
            ],
          ),
        );
      }

      await event.snapshot.ref.remove();
    });
  }

  Future<void> fetchUserData() async {
    if (currentUser == null) return;
    final snapshot = await database.ref("users/${currentUser!.uid}").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        userName = data['name'] ?? 'Client';
        profilePicUrl = data['profilePic'];
      });
    }
  }

  Future<void> fetchRecentTasks() async {
    if (currentUser == null) return;
    final ref = database.ref("users/${currentUser!.uid}/tasks");
    final snapshot = await ref.orderByChild("timestamp").limitToLast(5).get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> tasks = [];
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      for (final key in data.keys) {
        final task = Map<String, dynamic>.from(data[key]);

        final isCompleted = task['status'] == 'completed';
        final dateStr = task['date'] ?? '';
        final isExpired = dateStr.isNotEmpty &&
            DateTime.tryParse(dateStr)?.isBefore(DateTime.now()) == true;

        if (isCompleted || isExpired) {
          await ref.child(key).remove();
        } else {
          tasks.add({
            "title": task["title"] ?? "Untitled",
            "status": task["status"] ?? "Pending",
            "workerId": task["workerId"] ?? "",
          });
        }
      }

      setState(() {
        recentTasks = tasks.reversed.toList();
        unreadTaskCount = tasks.where((t) => t['status'] == 'pending').length;
      });
    } else {
      setState(() {
        recentTasks = [];
        unreadTaskCount = 0;
      });
    }
  }

  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseDatabase.instance.ref('users/${user.uid}/fcmToken').set(token);
      }
    }
  }

  Future<void> showWorkerProfile(String workerId) async {
    final snapshot = await database.ref("workers/$workerId").get();
    if (snapshot.exists) {
      final worker = Map<String, dynamic>.from(snapshot.value as Map);
      showModalBottomSheet(
        context: context,
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundImage: worker['profilePic'] != null
                    ? NetworkImage(worker['profilePic'])
                    : const AssetImage('assets/images/default_avatar.png')
                as ImageProvider,
                radius: 40,
              ),
              const SizedBox(height: 10),
              Text(worker['name'] ?? 'Worker',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(worker['bio'] ?? 'No bio provided.'),
              const SizedBox(height: 10),
              if (worker['categories'] != null)
                Wrap(
                  spacing: 6,
                  children: (worker['categories'] as List)
                      .map<Widget>((cat) => Chip(label: Text(cat.toString())))
                      .toList(),
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget buildRecentTasks() {
    final theme = Theme.of(context);
    if (recentTasks.isEmpty) {
      return Text("You have no recent tasks.",
          style: TextStyle(color: theme.hintColor));
    }

    return Column(
      children: recentTasks.map((task) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(Icons.task, color: theme.colorScheme.primary),
            title: Text(task['title']),
            subtitle: Text("Status: ${task['status']}"),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              if (task['workerId'] != null &&
                  task['workerId'].toString().isNotEmpty) {
                showWorkerProfile(task['workerId']);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget buildHomeTab() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        await fetchUserData();
        await fetchRecentTasks();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Hi $userName 👋",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text("You have $unreadTaskCount pending task(s).",
              style: TextStyle(color: theme.hintColor)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Post a New Task"),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TaskFormPage()));
            },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 24),
          Text("🕒 Recent Tasks", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          buildRecentTasks(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = [
      buildHomeTab(),
      MyTasksScreen(),
      Center(child: Text("Messages (coming soon)")),
      ClientProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("TaskBunny",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: profilePicUrl != null
                    ? NetworkImage(profilePicUrl!)
                    : const AssetImage('assets/images/avatar.png')
                as ImageProvider,
              ),
              decoration: BoxDecoration(color: theme.primaryColor),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClientSettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.hintColor,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.list_alt),
                if (unreadTaskCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        unreadTaskCount.toString(),
                        style:
                        const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            label: "My Tasks",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (unreadMessageCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        unreadMessageCount.toString(),
                        style:
                        const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            label: "Messages",
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
