import 'package:flutter/material.dart';

import 'customer/home_screen.dart';

class CustomerSignupCompleteScreen extends StatelessWidget {
  const CustomerSignupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "You're all set!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Thanks for signing up with TaskLink. You can now explore the platform.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => CustomerHomeScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Go to Dashboard"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
