import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart'; // 👈 Add this import

class ClientSignupScreen extends StatefulWidget {
  @override
  _ClientSignupScreenState createState() => _ClientSignupScreenState();
}

class _ClientSignupScreenState extends State<ClientSignupScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String email = '';
  String password = '';
  String confirmPassword = '';
  String name = '';
  String phone = '';
  bool isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool isNameAvailable = true;
  bool isCheckingName = false;

  // Check if name already exists
  Future<void> checkNameAvailability(String inputName) async {
    if (inputName.trim().isEmpty) {
      setState(() => isNameAvailable = true);
      return;
    }

    setState(() => isCheckingName = true);

    final snapshot = await FirebaseDatabase.instance.ref("users").get();

    bool taken = false;
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      for (final user in data.values) {
        final existingName = (user as Map)['name']?.toString().trim().toLowerCase();
        if (existingName == inputName.trim().toLowerCase()) {
          taken = true;
          break;
        }
      }
    }

    setState(() {
      isNameAvailable = !taken;
      isCheckingName = false;
    });
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final emailMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (emailMethods.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This email is already registered.")),
        );
        setState(() => isLoading = false);
        return;
      }

      final usersSnapshot = await FirebaseDatabase.instance.ref("users").get();
      bool phoneExists = false;

      if (usersSnapshot.exists) {
        final data = usersSnapshot.value as Map<dynamic, dynamic>;
        for (final user in data.values) {
          final userMap = user as Map;
          final dbPhone = userMap['phone']?.toString().trim();
          final dbName = userMap['name']?.toString().trim().toLowerCase();

          if (dbPhone == _phoneController.text.trim()) phoneExists = true;
          if (dbName == name.trim().toLowerCase()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("This username is already taken.")),
            );
            setState(() => isLoading = false);
            return;
          }
        }
      }

      if (phoneExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This phone number is already registered.")),
        );
        setState(() => isLoading = false);
        return;
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user!.uid;

      await FirebaseDatabase.instance.ref().child("users/$uid").set({
        "email": email,
        "name": name,
        "phone": _phoneController.text,
      });

      // ✅ Navigate to welcome screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(name: name),
        ),
      );
    } catch (e) {
      print("Signup error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed. ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Client Signup")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
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

              // Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                  suffixIcon: isCheckingName
                      ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : Icon(
                    isNameAvailable ? Icons.check_circle : Icons.error,
                    color: isNameAvailable ? Colors.green : Colors.red,
                  ),
                ),
                onChanged: (val) => checkNameAvailability(val),
                onSaved: (val) => name = val!.trim(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Enter name";
                  if (!isNameAvailable) return "Username already taken";
                  return null;
                },
              ),

              SizedBox(height: 12),

              // Email
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => email = val!.trim(),
                validator: (val) => val!.isEmpty ? "Enter email" : null,
              ),

              SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 5),
                    child: Text("🇿🇼", style: TextStyle(fontSize: 20)),
                  ),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                onChanged: (val) {
                  String raw = val.replaceAll(RegExp(r'[^\d+]'), '');
                  if (raw.startsWith('07')) {
                    raw = raw.replaceFirst('07', '+2637');
                  } else if (raw.startsWith('2637')) {
                    raw = '+$raw';
                  } else if (!raw.startsWith('+2637')) {
                    raw = '+2637';
                  }
                  if (raw.length > 13) raw = raw.substring(0, 13);
                  if (raw != _phoneController.text) {
                    _phoneController.value = TextEditingValue(
                      text: raw,
                      selection: TextSelection.collapsed(offset: raw.length),
                    );
                  }
                },
                onSaved: (val) => phone = _phoneController.text,
                validator: (val) {
                  final pattern = RegExp(r'^\+2637[7-9][0-9]{7}$');
                  if (val == null || val.isEmpty) return "Enter phone number";
                  if (!pattern.hasMatch(val.trim())) return "Use format +2637xxxxxxxx";
                  return null;
                },
              ),

              SizedBox(height: 12),

              // Password
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                onSaved: (val) => password = val!.trim(),
                validator: (val) =>
                val!.length < 6 ? "Minimum 6 characters" : null,
              ),

              SizedBox(height: 12),

              // Confirm Password
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() =>
                    _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                onSaved: (val) => confirmPassword = val!.trim(),
                validator: (val) =>
                val!.isEmpty ? "Confirm your password" : null,
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: isNameAvailable && !isCheckingName ? signUp : null,
                child: Text("Sign Up"),
              ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ClientLoginScreen()),
                      );
                    },
                    child: Text(
                      "Login here",
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
