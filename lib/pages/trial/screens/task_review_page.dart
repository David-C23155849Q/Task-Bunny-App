import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'my_tasks_screen.dart';

class TaskReviewPage extends StatefulWidget {
  final Map<String, dynamic> taskData;

  const TaskReviewPage({Key? key, required this.taskData}) : super(key: key);

  @override
  State<TaskReviewPage> createState() => _TaskReviewPageState();
}

class _TaskReviewPageState extends State<TaskReviewPage> {
  List<Map<String, dynamic>> matchingWorkers = [];
  String? selectedWorkerId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMatchingWorkers();
  }

  Future<void> cancelTaskRequest() async {
    final clientUid = FirebaseAuth.instance.currentUser?.uid;
    if (clientUid == null) return;

    final taskId = widget.taskData['taskId'];
    final workerId = widget.taskData['workerId'];

    final userTaskRef = FirebaseDatabase.instance.ref("users/$clientUid/tasks/$taskId");
    final workerRequestRef = FirebaseDatabase.instance.ref("workers/$workerId/requests/$taskId");

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Task Request"),
        content: const Text("Are you sure you want to cancel this task request?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Yes, Cancel"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await userTaskRef.remove();
      await workerRequestRef.remove();
    } catch (e) {
      print("❌ Failed to cancel task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to cancel task")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task request cancelled")),
    );

    // Navigate back to home or root
    Navigator.popUntil(context, (route) => route.isFirst);
  }



  Future<void> _refreshWorkers() async {
    setState(() => loading = true);
    await fetchMatchingWorkers();
  }


  Future<void> fetchMatchingWorkers() async {
    try {
      final category = widget.taskData['category'].toString().toLowerCase().trim();
      final city = widget.taskData['city'].toString().toLowerCase().trim();

      final workersRef = FirebaseDatabase.instance.ref('workers');
      final snapshot = await workersRef.get();

      final List<Map<String, dynamic>> workers = [];

      if (snapshot.exists) {
        for (final child in snapshot.children) {
          if (child.value is! Map) continue;
          final data = Map<String, dynamic>.from(child.value as Map);

          final isOnline = data['online'] == true;
          if (!isOnline) continue;

          final workerCity = data['city']?.toString().toLowerCase().trim();
          final rawCategories = data['categories'];
          final categories = (rawCategories is List)
              ? rawCategories.map((e) => e.toString().toLowerCase().trim()).toList()
              : [];

          if (workerCity == city && categories.contains(category)) {
            workers.add({
              'id': child.key,
              'name': data['name'] ?? 'Unnamed',
              'bio': data['bio'] ?? '',
              'photo': data['profilePic'],
              'rating': data['rating'] ?? 0,
              'categories': data['categories'] ?? [],
              'resources': data['resources'] ?? {},
            });
          }
        }

        // Optional: sort by highest rated
        workers.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
      }

      setState(() {
        matchingWorkers = workers;
        loading = false;
      });
    } catch (e, st) {
      print("❌ Error fetching workers: $e");
      print(st);
      setState(() {
        loading = false;
        matchingWorkers = [];
      });
    }
  }

  void showWorkerProfile(Map<String, dynamic> worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: worker['photo'] != null
                    ? NetworkImage(worker['photo'])
                    : AssetImage('assets/images/avatar.png') as ImageProvider,
              ),
              const SizedBox(height: 12),
              Text(worker['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(worker['bio']),
              const SizedBox(height: 12),
              Text('Rating: ${worker['rating']}/5'),
              const SizedBox(height: 12),
              Text('Categories: ${worker['categories'].join(', ')}'),
              if (worker['resources'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (worker['resources'] as Map).entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${entry.key}: ${entry.value}')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Select This Worker'),
                onPressed: () {
                  setState(() => selectedWorkerId = worker['id']);
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> submitTask() async {
    if (selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worker.')),
      );
      return;
    }

    final clientUid = FirebaseAuth.instance.currentUser?.uid;
    if (clientUid == null) return;

    final taskId = FirebaseDatabase.instance.ref().push().key!;
    final taskRef = FirebaseDatabase.instance.ref('users/$clientUid/tasks/$taskId');
    final workerRequestRef = FirebaseDatabase.instance.ref('workers/$selectedWorkerId/requests/$taskId');

    final taskData = {
      ...widget.taskData,
      'id': taskId,
      'workerId': selectedWorkerId,
      'status': 'pending',
      'clientId': clientUid,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await taskRef.set(taskData);
    await workerRequestRef.set(taskData);

    final notificationRef = FirebaseDatabase.instance
        .ref('workers/$selectedWorkerId/notifications')
        .push();

    await notificationRef.set({
      'title': 'New Task Request',
      'body': '${widget.taskData['title']} from a client in ${widget.taskData['city']}',
      'timestamp': DateTime.now().toIso8601String(),
      'taskId': taskId,
      'clientId': clientUid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task submitted successfully!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MyTasksScreen()),
    );
  }

  Widget buildWorkerCard(Map<String, dynamic> worker) {
    final isSelected = selectedWorkerId == worker['id'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: worker['photo'] != null
                  ? NetworkImage(worker['photo'])
                  : const AssetImage('assets/images/avatar.png'),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(worker['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(worker['bio'], maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('⭐ Rating: ${worker['rating']}/5'),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => showWorkerProfile(worker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.taskData;

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Assign Task')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshWorkers,
        child: matchingWorkers.isEmpty
            ? ListView(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text('No matching workers online.'),
              ),
            )
          ],
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('📝 Task Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Title: ${widget.taskData['title']}'),
            Text('Description: ${widget.taskData['description']}'),
            Text('Category: ${widget.taskData['category']}'),
            Text('Budget: \$${widget.taskData['budget']}'),
            Text('Scheduled For: ${widget.taskData['dateTime']}'),
            Text('City: ${widget.taskData['city']}'),
            Text('Address: ${widget.taskData['address']}'),
            const SizedBox(height: 20),
            Text('👷 Choose a Tasker', style: Theme.of(context).textTheme.titleLarge),
            ...matchingWorkers.map(buildWorkerCard).toList(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: submitTask,
              icon: const Icon(Icons.send),
              label: const Text('Submit Task'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 6,),
            ElevatedButton.icon(
              onPressed: cancelTaskRequest,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel Request"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

          ],
        ),
      ),

    );
  }
}
