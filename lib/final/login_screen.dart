import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/services/notification_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:errand_app/final/workers_home_screen.dart';
import 'package:errand_app/final/role_selector_page.dart';

import 'customer/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameOrEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isObscured = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String input = _usernameOrEmailController.text.trim();
      String password = _passwordController.text.trim();
      String email = input;

      // If not an email, treat as username and resolve to email
      if (!input.contains('@')) {
        // Check both users and workers collections
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        final workerQuery = await FirebaseFirestore.instance
            .collection('workers')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          email = userQuery.docs.first['email'];
        } else if (workerQuery.docs.isNotEmpty) {
          email = workerQuery.docs.first['email'];
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with that username.',
          );
        }
      }


      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );


      final uid = credential.user!.uid;

      // Check customer role
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        final role = userDoc['role'];
        if (!mounted) return;

        if (role == 'customer') {
          // 🔔 Get FCM Token and save it
          await NotificationService().init(context);


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
          return;
        }
      }

      // Check worker role
      final workerDoc = await FirebaseFirestore.instance.collection('workers').doc(uid).get();
      if (workerDoc.exists && workerDoc.data()!.containsKey('role')) {
        final role = workerDoc['role'];
        final name = workerDoc['name'] ?? 'Worker';
        if (!mounted) return;
        if (role == 'worker') {
          // 🔔 Get FCM Token and save it

          await NotificationService().init(context);


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => WorkerHomeScreen()),
          );
          return;
        }
      }

      setState(() {
        _errorMessage = 'User role not found.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Login failed';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    String input = _usernameOrEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email or username first')),
      );
      return;
    }

    try {
      String email = input;

      if (!input.contains('@')) {
        // Resolve username to email
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        final workerQuery = await FirebaseFirestore.instance
            .collection('workers')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          email = userQuery.docs.first['email'];
        } else if (workerQuery.docs.isNotEmpty) {
          email = workerQuery.docs.first['email'];
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with that username.',
          );
        }
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  Image.asset('assets/images/bunny.png', height: 100),
                  const SizedBox(height: 10),
                  const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _usernameOrEmailController,
                    decoration: _inputDecoration('Username or Email'),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter username or email' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscured,
                    decoration: _inputDecoration('Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isObscured = !_isObscured),
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                    ),
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text("Login", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),

                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: "SignUp here",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RoleSelectorScreen()));
                            },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
