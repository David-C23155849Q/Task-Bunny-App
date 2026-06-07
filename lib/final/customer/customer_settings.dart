import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/trial/main.dart';
import '../../pages/trial/screens/services/how_it_works_page.dart';
import '../how_it_works_screen.dart';
import '../legal_screen.dart';
import 'c_how_it_works_page.dart';
import 'c_terms_and_privacy_policy_page.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  bool isDark = false;
  bool _isSending = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _emailController.text = _auth.currentUser?.email ?? '';
    isDark = themeNotifier.value == ThemeMode.dark;
  }

  void _toggleDarkMode(bool value) async {
    setState(() => isDark = value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value ? 'dark' : 'light');
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Please enter a valid email.');
      return;
    }

    setState(() {
      _isSending = true;
      _message = '';
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() => _message = 'Reset email sent to $email');
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    }

    setState(() => _isSending = false);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _message = '');
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => _toggleDarkMode(!isDark),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("👤 Account", style: textTheme.titleLarge),
          const SizedBox(height: 10),
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
            icon: const Icon(Icons.lock_reset),
            label: Text(_isSending ? "Sending..." : "Send Password Reset"),
            onPressed: _isSending ? null : _sendResetEmail,
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

          const Divider(height: 32),

          Text("⚙️ Preferences", style: textTheme.titleLarge),
          SwitchListTile(
            value: isDark,
            onChanged: _toggleDarkMode,
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.brightness_6),
          ),

          const Divider(height: 32),

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
                children: const [
                  Text("Built with Flutter\nContact: dev@tasklink.com"),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy & Terms"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerTermsPrivacyPolicy()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text("App Tutorial"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerHowItWorksPage()),
            ),
          ),

          const Divider(height: 32),

          Center(
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
