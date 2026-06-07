import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/fcm_service.dart';

class TaskInputPanel extends StatefulWidget {
  final LatLng? selectedLatLng;
  final String? pickupAddress;

  const TaskInputPanel({
    Key? key,
    required this.selectedLatLng,
    required this.pickupAddress,
  }) : super(key: key);

  @override
  State<TaskInputPanel> createState() => _TaskInputPanelState();
}

class _TaskInputPanelState extends State<TaskInputPanel>
    with SingleTickerProviderStateMixin {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isSubmitting = false;

  String? _selectedCategory;

  final Map<String, IconData> _categories = {
    'Cleaning': Icons.cleaning_services,
    'Furniture Assembly': Icons.chair_alt,
    'Electrical Help': Icons.electrical_services,
    'Painting': Icons.format_paint,
    'Handyman': Icons.handyman,
    'Yard Work': Icons.park,
    'Mounting': Icons.tv,
    'Pickup and Dropoff': Icons.local_shipping,
    'Delivery': Icons.delivery_dining,
    'Home Repairs': Icons.home_repair_service,
    'Personal Assistant': Icons.person,
    'Errands': Icons.shopping_bag,
    'Help Moving': Icons.move_to_inbox,
    'Event Staffing': Icons.event,
  };

  void _submitTask() async {
    if (_selectedCategory == null ||
        _descriptionController.text.trim().isEmpty ||
        widget.selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Task"),
        content: const Text("Are you sure you want to post this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    final selectedCategory = _selectedCategory!;
    final description = _descriptionController.text.trim();
    final address = widget.pickupAddress;
    final latLng = widget.selectedLatLng!;

    // 🔍 Extract city from address (basic approach)
    String city = '';
    if (address != null && address.contains(',')) {
      final parts = address.split(',');
      if (parts.length >= 2) {
        city = parts[1].trim(); // crude city extraction
      }
    }

    // ✅ Add task to Firestore with pickup.city
    final taskRef = await FirebaseFirestore.instance.collection('tasks').add({
      'description': description,
      'price': _priceController.text.trim(),
      'pickup': {
        'lat': latLng.latitude,
        'lng': latLng.longitude,
        'address': address,
        'city': city, // ✅ required for notifications
      },
      'category': selectedCategory,
      'customerId': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    final taskId = taskRef.id;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Task posted under $selectedCategory at ${address ?? ''}",
        ),
      ),
    );

    // 🔍 Find matching workers (still optional fallback if Cloud Function fails)
    final workersQuery = await FirebaseFirestore.instance
        .collection('workers')
        .where('city', isEqualTo: city)
        .where('categories', arrayContains: selectedCategory)
        .get();

    final workerDocs = workersQuery.docs;

    // 📋 Show available workers in dialog
    _showMatchingWorkersDialog(context, workerDocs, taskId);

    // 🔁 Reset form
    setState(() {
      _isSubmitting = false;
      _descriptionController.clear();
      _priceController.clear();
      _selectedCategory = null;
    });
  }


  void _showMatchingWorkersDialog(BuildContext context, List<QueryDocumentSnapshot> workerDocs, String taskId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Assign Task to a Worker'),
          content: workerDocs.isEmpty
              ? const Text('No workers available for this task.')
              : SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workerDocs.length,
              itemBuilder: (_, index) {
                final worker = workerDocs[index].data() as Map<String, dynamic>;
                final workerId = workerDocs[index].id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: worker['profileImageUrl'] != null
                        ? NetworkImage(worker['profileImageUrl'])
                        : null,
                    child: worker['profileImageUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(worker['username'] ?? 'Unnamed'),
                  subtitle: Text(worker['city'] ?? ''),
                  onTap: () async {
                    // Update task in Firestore
                    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
                      'assignedWorkerId': workerId,
                      'status': 'assigned',
                      'hasSeenByWorker': false,
                    });

                    // 🔔 Send FCM Notification
                    final fcmToken = worker['fcmToken'];
                    if (fcmToken != null) {
                      await FCMService.sendNotificationToWorker(
                        token: fcmToken,
                        title: 'New Task Assigned',
                        body: 'You have been assigned a new $_selectedCategory task.',
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ Task assigned to ${worker['username'] ?? 'worker'}')),
                      );
                    }
                  },

                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      offset: const Offset(0, 0),
      child: Card(
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Pickup location (address)
                Row(
                  children: [
                    const Icon(Icons.location_pin, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.pickupAddress ?? 'Pickup location not set',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(entry.value, size: 18),
                              const SizedBox(width: 4),
                              Text(entry.key),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: Theme.of(context).primaryColor,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = isSelected ? null : entry.key;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Task description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Task Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Price offer
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Offer Your Price (\$)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitTask,
                  icon: const Icon(Icons.search),
                  label: Text(_isSubmitting ? "Posting..." : "Find a worker"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
