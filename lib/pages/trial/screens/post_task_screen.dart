import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PostTaskScreen extends StatefulWidget {
  @override
  _PostTaskScreenState createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final currentUser = FirebaseAuth.instance.currentUser;
  final database = FirebaseDatabase.instance;

  final List<String> categories = [
    'Cleaning',
    'Furniture Assembly',
    'Electrical Help',
    'Painting',
    'Handyman',
    'Yard Work',
    'Mounting',
    'Pickup and Dropoff',
    'Delivery',
    'Home Repairs',
    'Personal Assistant',
    'Errands',
    'Help Moving',
    'Event Staffing',
  ];

  String? selectedCategory;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String description = '';
  String budget = '';
  String city = '';
  String address = '';
  File? taskImage;
  String? base64Image;
  bool isLoading = false;
  bool showMatches = false;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> matchingWorkers = [];

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
    if (index == 1) Navigator.pushReplacementNamed(context, '/myTasks');
    if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
    if (index == 3) FirebaseAuth.instance.signOut();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      setState(() {
        taskImage = file;
        base64Image = base64Encode(bytes);
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _searchMatchingWorkers() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields.")));
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      isLoading = true;
      matchingWorkers.clear();
      showMatches = false;
    });

    try {
      final snapshot = await database.ref("workers").get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          final worker = Map<String, dynamic>.from(value);
          final workerCategories = List<String>.from(worker['categories'] ?? []);
          final workerCity = (worker['city'] ?? '').toString().toLowerCase();

          if (workerCategories.contains(selectedCategory) && workerCity == city.trim().toLowerCase()) {
            matchingWorkers.add({
              'id': key,
              'name': worker['name'] ?? '',
              'photo': worker['profilePic'] ?? '',
              'rating': worker['rating']?.toDouble() ?? 0.0,
              'bio': worker['bio'] ?? '',
              'categories': worker['categories'] ?? [],
              'resources': worker['resources'] ?? {}, // expecting 'image' inside here
            });
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching workers: $e")));
    }

    setState(() {
      isLoading = false;
      showMatches = true;
    });
  }

  Future<void> _assignTaskToWorker(String workerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Assign Task?"),
        content: Text("Are you sure you want to assign this task to the selected worker?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Confirm")),
        ],
      ),
    );

    if (confirmed != true) return;

    final taskId = database.ref().child("users/${currentUser!.uid}/tasks").push().key!;
    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    final timestamp = dateTime.millisecondsSinceEpoch;

    final taskData = {
      'title': '$selectedCategory Task',
      'description': description,
      'category': selectedCategory,
      'budget': budget,
      'city': city,
      'address': address,
      'timestamp': timestamp,
      'status': 'Assigned',
      'imageBase64': base64Image ?? '',
      'assignedTo': workerId,
    };

    try {
      await database.ref("users/${currentUser!.uid}/tasks/$taskId").set(taskData);
      await database.ref("workers/$workerId/tasks/$taskId").set(taskData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Task assigned successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assignment failed: $e")));
    }
  }

  void _showWorkerPreview(Map<String, dynamic> worker) {
    final resources = worker['resources'] ?? {};
    final String? resourceImage = resources['image'];

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(worker['photo'] ?? ''),
                    radius: 30,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      worker['name'] ?? 'No name',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text("⭐: ${worker['rating']?.toStringAsFixed(1) ?? 'N/A'}"),
                ],
              ),
              SizedBox(height: 10),
              if ((worker['bio'] ?? '').toString().isNotEmpty) ...[
                Text("Bio", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(worker['bio']),
                SizedBox(height: 10),
              ],
              if ((worker['categories'] ?? []).isNotEmpty) ...[
                Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: List<String>.from(worker['categories']).map((cat) => Chip(label: Text(cat))).toList(),
                ),
              ],
              SizedBox(height: 10),
              if (resourceImage != null && resourceImage.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Resource Image", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Image.network(resourceImage, height: 150),
                  ],
                )
              else
                Column(
                  children: [
                    Text("No resource image provided", style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 10),
                    Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post a New Task")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: Text("Select Category"),
                    items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) => setState(() => selectedCategory = val),
                    validator: (val) => val == null ? "Please choose category" : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Task Description"),
                    maxLines: 3,
                    onSaved: (val) => description = val ?? '',
                    validator: (val) => val!.isEmpty ? "Enter description" : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Budget (USD)"),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => budget = val ?? '',
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: "City"),
                    onSaved: (val) => city = val ?? '',
                    validator: (val) => val!.isEmpty ? "Enter city" : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Detailed Address"),
                    onSaved: (val) => address = val ?? '',
                    validator: (val) => val!.isEmpty ? "Enter address" : null,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          child: Text(selectedDate == null
                              ? "Pick Date"
                              : DateFormat.yMMMEd().format(selectedDate!)),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickTime,
                          child: Text(selectedTime == null
                              ? "Pick Time"
                              : selectedTime!.format(context)),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: Icon(Icons.image),
                    label: Text("Upload Task Image"),
                  ),
                  if (taskImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Image.file(taskImage!, height: 120),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _searchMatchingWorkers,
                    child: Text("Search Matching Workers"),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            if (showMatches && matchingWorkers.isNotEmpty) ...[
              Divider(),
              Text("Matching Workers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...matchingWorkers.map((worker) {
                return Card(
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () => _showWorkerPreview(worker),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(worker['photo']),
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    title: Text(worker['name']),
                    subtitle: Text("⭐: ${worker['rating'].toStringAsFixed(1)}"),
                    trailing: ElevatedButton(
                      onPressed: () => _assignTaskToWorker(worker['id']),
                      child: Text("Assign"),
                    ),
                  ),
                );
              }).toList(),
            ],
            if (showMatches && matchingWorkers.isEmpty)
              Text("No matching workers found."),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "My Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}
