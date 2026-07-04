import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WorkerAvailabilityToggle extends StatefulWidget {
  const WorkerAvailabilityToggle({super.key});

  @override
  State<WorkerAvailabilityToggle> createState() =>
      _WorkerAvailabilityToggleState();
}

class _WorkerAvailabilityToggleState
    extends State<WorkerAvailabilityToggle> {
  bool isActive = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseDatabase.instance
        .ref()
        .child("workers")
        .child(uid)
        .child("isActive")
        .get();

    setState(() {
      isActive = snap.value == true;
      loading = false;
    });
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => isActive = !isActive);

    await FirebaseDatabase.instance
        .ref()
        .child("workers")
        .child(uid)
        .update({
      "isActive": isActive,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Availability",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),

        Switch(
          value: isActive,
          onChanged: (val) => _toggle(),
          activeColor: Colors.green,
        ),

        Text(
          isActive ? "ACTIVE" : "OFFLINE",
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}