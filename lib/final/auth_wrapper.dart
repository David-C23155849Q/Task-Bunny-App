import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/workers_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer/home_screen.dart';
import 'cutomer_signup_screen.dart';
import 'login_screen.dart';
import 'role_selector_page.dart';
import 'workers_signup_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const RoleSelectorScreen();

        final user = snapshot.data!;
        final uid = user.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${userSnapshot.error}')),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

            if (userData == null || userData['role'] == null) {
              return const LoginScreen();
            }

            final role = userData['role'];
            final isProfileComplete = userData['isProfileComplete'] ?? false;

            if (userData['disabled'] == true) {
              return Scaffold(
                body: Center(child: Text('This account has been disabled')),
              );
            }

            if (role == 'worker') {
              return isProfileComplete
                  ? WorkerHomeScreen()
                  : Step1BasicInfoScreen(role: '',); // or ResumeSignupScreen
            } else if (role == 'customer') {
              return isProfileComplete
                  ? CustomerHomeScreen()
                  : CustomerSignupScreen(role: '',);
            } else {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Unknown role assigned.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Logout & Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

