import 'package:errand_app/pages/trial/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'forgot_password_screen.dart';
import 'home_screen.dart';


class ClientLoginScreen extends StatefulWidget {
  @override
  _ClientLoginScreenState createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();

  final _formKey = GlobalKey<FormState>();
  String emailOrName = '';
  String password = '';
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<String?> getEmailFromName(String name) async {
    final snapshot = await _database.child("users").get();
    if (snapshot.exists) {
      final workers = snapshot.value as Map<dynamic, dynamic>;
      for (var entry in workers.entries) {
        final data = Map<String, dynamic>.from(entry.value);
        if (data['name'].toString().toLowerCase() == name.toLowerCase()) {
          return data['email'];
        }
      }
    }
    return null;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      String emailToUse = emailOrName;

      // If input is not email, treat as username
      if (!emailOrName.contains('@')) {
        final foundEmail = await getEmailFromName(emailOrName);
        if (foundEmail == null) {
          throw Exception("No user found with name \"$emailOrName\"");
        }
        emailToUse = foundEmail;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final uid = userCredential.user!.uid;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientHomeScreen(),
        ),
      );
    } catch (e) {
      print("Login failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Login failed: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Client Login")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              SizedBox(height: 50),
              Image.asset(
                'assets/images/bunny.png',
                height: 160,
              ),
              SizedBox(height: 20),


              TextFormField(
                decoration: InputDecoration(labelText: "Username/Email"),
                onSaved: (val) => emailOrName = val!.trim(),
                validator: (val) =>
                val!.isEmpty ? "Enter email or username" : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                onSaved: (val) => password = val!.trim(),
                validator: (val) =>
                val!.length < 6 ? "Minimum 6 characters" : null,
              ),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text("Forgot Password?"),
                ),
              ),

              SizedBox(height: 16),

              ElevatedButton(
                onPressed: login,
                child: Text("Login"),
              ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ClientSignupScreen()),
                      );
                    },
                    child: Text(
                      "SignUp here",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),


        ),


      ),
    );
  }
}
