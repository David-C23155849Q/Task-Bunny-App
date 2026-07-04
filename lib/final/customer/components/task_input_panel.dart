import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'customer_bids_screen.dart';

class TaskInputPanel extends StatefulWidget {
  final LatLng? selectedLatLng;
  final String? pickupAddress;

  const TaskInputPanel({
    super.key,
    required this.selectedLatLng,
    required this.pickupAddress,
  });

  @override
  State<TaskInputPanel> createState() => _TaskInputPanelState();
}

class _TaskInputPanelState extends State<TaskInputPanel>
    with SingleTickerProviderStateMixin {
final TextEditingController _descriptionController =
TextEditingController();

final TextEditingController _priceController =
TextEditingController();

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

Future<void> _submitTask() async {
  if (_selectedCategory == null ||
      _descriptionController.text.trim().isEmpty ||
      widget.selectedLatLng == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please complete all fields."),
      ),
    );
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Task"),
      content: const Text(
        "Post this task for nearby workers to bid on?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Post Task"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  setState(() => _isSubmitting = true);

  final user = FirebaseAuth.instance.currentUser;

  final description = _descriptionController.text.trim();
  final selectedCategory = _selectedCategory!;
  final address = widget.pickupAddress;
  final latLng = widget.selectedLatLng!;

  String city = "";

  if (address != null && address.contains(",")) {
    final parts = address.split(",");
    if (parts.length >= 2) {
      city = parts[1].trim();
    }
  }

  try {
    /// ✅ CREATE TASK AND GET ID
    final taskRef = await FirebaseFirestore.instance.collection("tasks").add({
      "description": description,
      "price": _priceController.text.trim(),
      "category": selectedCategory,
      "customerId": user?.uid,
      "timestamp": FieldValue.serverTimestamp(),

      "pickup": {
        "lat": latLng.latitude,
        "lng": latLng.longitude,
        "address": address,
        "city": city,
      },

      "status": "open",
      "assignedWorkerId": null,
      "winningBidId": null,
      "acceptedPrice": null,
      "bidCount": 0,
    });

    if (!mounted) return;

    /// ✅ SUCCESS MESSAGE
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task posted successfully."),
      ),
    );


    /// Show bids panel immediately
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerBidsPanel(taskId: taskRef.id),
    );

    /// RESET FORM
    setState(() {
      _descriptionController.clear();
      _priceController.clear();
      _selectedCategory = null;
      _isSubmitting = false;
    });
  } catch (e) {
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error posting task: $e"),
      ),
    );
  }
}
@override
Widget build(BuildContext context) {
  return AnimatedSlide(
    duration: const Duration(milliseconds: 400),
    offset: const Offset(0, 0),
    child: Card(
      margin: const EdgeInsets.all(12),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// Pickup Location
              Row(
                children: [
                  const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.pickupAddress ??
                          "Pickup location not set",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// Categories
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories.entries.map((entry) {
                    final isSelected =
                        _selectedCategory == entry.key;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.value,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(entry.key),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor:
                        Theme.of(context).primaryColor,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory =
                            isSelected ? null : entry.key;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              /// Task Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Task Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              /// Customer Budget
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Your Budget Offer (\$)",
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              /// Post Task Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  _isSubmitting ? null : _submitTask,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Icon(Icons.campaign),
                  label: Text(
                    _isSubmitting
                        ? "Posting..."
                        : "Post Task",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.greenAccent[400],
                    foregroundColor: Colors.black,
                    minimumSize:
                    const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Nearby workers will see your task and send you bids. You choose the worker you want.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
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
