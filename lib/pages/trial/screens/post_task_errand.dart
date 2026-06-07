import 'package:errand_app/pages/trial/screens/post_task_map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskFormPage extends StatefulWidget {
  @override
  _TaskFormPageState createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDateTime = DateTime.now();

  final List<String> _categories = [
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
    'Event Staffing'];

  void _goToNext() {
    if (_formKey.currentState?.validate() != true || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'category': _selectedCategory,
      'budget': double.tryParse(_budgetController.text.trim()) ?? 0,
      'dateTime': _selectedDateTime.toIso8601String(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskLocationPage(taskData: taskData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().add_jm().format(_selectedDateTime);

    return Scaffold(
      appBar: AppBar(title: Text('Post Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🎉 Friendly Introduction
              Text(
                "🛠️ Let's get your task posted!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Just a few quick details and we’ll help you find the right person for the job.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: Text('Select Category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Please select a category' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(labelText: 'Budget (USD) 💲'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today),
                title: Text('Scheduled Time'),
                subtitle: Text(formattedDate),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _goToNext,
                child: Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
