import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/about_us_page.dart';
import 'package:errand_app/final/settings_screen.dart';
import 'package:errand_app/final/task_offer_screen.dart';
import 'package:errand_app/final/woker_profile_view.dart';
import 'package:errand_app/final/worker_earnings.dart';
import 'package:errand_app/final/worker_profile_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'workers_home_tab.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;
  bool isOnline = false;

  List<Widget> get _tabs => [
    const HomeTab(),
    const EarningsTab(),
    const TaskOffersScreen(taskId: '',),
    WorkerProfileViewScreen(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
  ];


  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
  }

  Future<void> _loadOnlineStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('workers').doc(uid).get();
    setState(() {
      isOnline = doc.data()?['isOnline'] ?? false;
    });
  }

  Future<void> _toggleOnline(bool val) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('workers').doc(uid).update({'isOnline': val});
    setState(() => isOnline = val);
  }

  void _logout() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskLink', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(isOnline ? Icons.circle : Icons.circle_outlined,
                  color: isOnline ? Colors.green : Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(color: isOnline ? Colors.green : Colors.grey),
              ),
              Switch(
                value: isOnline,
                onChanged: _toggleOnline,
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _firestore.collection('workers').doc(_auth.currentUser?.uid).get(),
              builder: (ctx, snap) {
                final data = snap.data?.data() ?? {};
                return UserAccountsDrawerHeader(
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: data['profileImageUrl'] != null
                        ? NetworkImage(data['profileImageUrl'])
                        : null,
                    child: data['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  accountName: Text(data['username'] ?? ''),
                  accountEmail: Text(_auth.currentUser?.email ?? ''),
                );
              },
            ),
            ListTile(leading: const Icon(Icons.info),
                title: const Text('About Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutUsPage(),
                  ),
                );
              },

            ),
            ListTile(leading: const Icon(Icons.settings),
                title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
