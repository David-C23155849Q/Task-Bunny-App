import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/trial/main.dart';
import '../final/about_us_page.dart';
import 'how_it_works_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  bool _isSending = false;
  String _message = '';
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = _auth.currentUser?.email ?? '';
    isDark = themeNotifier.value == ThemeMode.dark;
  }

  Future<void> sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Please enter a valid email.');
      return;
    }

    try {
      setState(() {
        _isSending = true;
        _message = '';
      });
      await _auth.sendPasswordResetEmail(email: email);
      setState(() {
        _message = 'Password reset email sent to $email.';
        _isSending = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _message = '');
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isSending = false;
      });
    }
  }

  void toggleDarkMode(bool value) async {
    setState(() => isDark = value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value ? 'dark' : 'light');
  }


  void logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: const Text("Log Out"),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 👈 go back
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => toggleDarkMode(!isDark),
          ),
        ],
      ),


      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account
          Text("👤 Account", style: textTheme.titleLarge),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isSending ? null : sendPasswordReset,
            icon: const Icon(Icons.lock_reset),
            label: const Text("Send Password Reset Email"),
          ),
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _message,
                style: TextStyle(
                  color: _message.contains('sent') ? Colors.green : Colors.red,
                ),
              ),
            ),

          const SizedBox(height: 24),
          const Divider(),

          // Preferences
          Text("⚙️ Preferences", style: textTheme.titleLarge),
          const SizedBox(height: 10),
          SwitchListTile(
            value: isDark,
            onChanged: toggleDarkMode,
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.brightness_6),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // App Info
          Text("ℹ️ App Info", style: textTheme.titleLarge),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("App Version"),
            subtitle: const Text("1.0.0"),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: const Text("Developer"),
            subtitle: const Text("David Sithole"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "TaskLink",
                applicationVersion: "1.0.0",
                children: [
                  const Text("Built with Flutter.\nContact: dev@tasklink.com"),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy & Terms"),
            onTap: () => Navigator.pushNamed(context, '/legal'),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text("App Tutorial"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HowItWorksScreen(uid: ''),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("About Us"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AboutUsPage(),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Logout
          Center(
            child: ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
