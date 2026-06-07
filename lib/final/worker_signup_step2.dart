import 'package:flutter/material.dart';
import 'worker_signup_step3.dart'; // Import Step 3

class WorkerSignupStep2 extends StatefulWidget {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String phone;

  const WorkerSignupStep2({
    super.key,
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
  });

  @override
  State<WorkerSignupStep2> createState() => _WorkerSignupStep2State();
}

class _WorkerSignupStep2State extends State<WorkerSignupStep2> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  final List<String> taskCategories = [
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
    'Event Staffing'
  ];
  List<String> selectedCategories = [];

  bool hasVehicle = false;
  bool hasTools = false;

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerSignupStep3(
          uid: widget.uid,
          name: widget.name,
          username: widget.username,
          email: widget.email,
          phone: widget.phone,
          bio: _bioController.text.trim(),
          city: _cityController.text.trim(),
          categories: selectedCategories,
          resources: {
            'vehicle': hasVehicle,
            'tools': hasTools,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF1565C0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[300] : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Signup - Step 2"),
        backgroundColor: primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Profile Information",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tell us more about your work and skills",
                style: TextStyle(color: subtitleColor),
              ),
              const SizedBox(height: 30),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Short Bio',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                v!.isEmpty ? 'Please provide a short bio' : null,
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter your city' : null,
              ),
              const SizedBox(height: 20),

              // Task Categories
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Task Categories (max 3)',
                  style:
                  TextStyle(fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: taskCategories.map((category) {
                  final selected = selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (bool value) {
                      setState(() {
                        if (value && selectedCategories.length < 3) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                    },
                    selectedColor: primaryBlue.withOpacity(0.8),
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Resources
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resources',
                  style:
                  TextStyle(fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              CheckboxListTile(
                value: hasVehicle,
                onChanged: (val) => setState(() => hasVehicle = val ?? false),
                title: const Text("I have a vehicle"),
              ),
              CheckboxListTile(
                value: hasTools,
                onChanged: (val) => setState(() => hasTools = val ?? false),
                title: const Text("I have tools/equipment"),
              ),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _handleNext,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Next"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
