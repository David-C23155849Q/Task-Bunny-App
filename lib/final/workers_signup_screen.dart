import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:errand_app/final/worker_signup_step2.dart';

class Step1BasicInfoScreen extends StatefulWidget {
  final String role;

  const Step1BasicInfoScreen({super.key, required this.role});

  @override
  State<Step1BasicInfoScreen> createState() => _Step1BasicInfoScreenState();
}

class _Step1BasicInfoScreenState extends State<Step1BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  void _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerSignupStep2(
            uid: userCredential.user!.uid,
            name: fullNameController.text.trim(),
            username: usernameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Something went wrong. Please try again.';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor ??
          theme.colorScheme.surface.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Signup - Step 1"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              Image.asset(
                'assets/images/bunny.png',
                height: 160,
              ),
              const SizedBox(height: 20),
              Text(
                "Let's get started!",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please enter your basic account details below.",
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium!.color!.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: fullNameController,
                decoration: _inputDecoration("Full Name", Icons.person),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: usernameController,
                decoration: _inputDecoration("Username", Icons.account_circle),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Email", Icons.email),
                validator: (value) =>
                value == null || !value.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Phone Number", Icons.phone),
                validator: (value) =>
                value == null || value.length < 10 ? 'Invalid phone number' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: _inputDecoration("Password", Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value == null || value.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _createAccount,
                  icon: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.arrow_forward),
                  label: const Text("Next"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
