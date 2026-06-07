import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String name;

  const WelcomeScreen({required this.name});

  void _showNotInstalled(BuildContext context, String appName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$appName is not installed.")),
    );
  }

  void _shareToWhatsApp(BuildContext context) async {
    final message = Uri.encodeFull("🎉 Join me on TaskBunny to get your chores done! 🐰 https://taskbunny.page.link/invite");
    final url = "whatsapp://send?text=$message";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showNotInstalled(context, "WhatsApp");
    }
  }

  void _shareToInstagram(BuildContext context) async {
    final message = Uri.encodeFull("Need help with errands? 🧹🛠️ Join me on TaskBunny! https://taskbunny.page.link/invite");
    final url = "https://www.instagram.com/?text=$message";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showNotInstalled(context, "Instagram");
    }
  }

  void _shareToFacebook(BuildContext context) async {
    final message = Uri.encodeFull("Check out TaskBunny! 🐰 Post jobs, get help! https://taskbunny.page.link/invite");
    final url = "https://www.facebook.com/sharer/sharer.php?u=$message";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showNotInstalled(context, "Facebook");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Image.asset(
                  'assets/images/bunny.png',
                  height: 140,
                ),
                SizedBox(height: 2),
                Image.asset(
                  'assets/images/banner.png',
                  height: 60,
                ),
                SizedBox(height: 30),

                Text(
                  "Account Created Successfully!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                Text(
                  "Welcome, $name 👋",
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey[300] : Colors.black54,
                  ),
                ),

                SizedBox(height: 20),

                Text(
                  "You're all set to explore taskers, request help, and manage your tasks easily.",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ClientHomeScreen()),
                    );
                  },
                  child: Text("Go to Dashboard"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  "Invite friends on",
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),

                SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Image.asset('assets/images/whatsapp.png', height: 36),
                      onPressed: () => _shareToWhatsApp(context),
                    ),
                    IconButton(
                      icon: Image.asset('assets/images/instagram.png', height: 36),
                      onPressed: () => _shareToInstagram(context),
                    ),
                    IconButton(
                      icon: Image.asset('assets/images/facebook.png', height: 36),
                      onPressed: () => _shareToFacebook(context),
                    ),
                  ],
                ),

                SizedBox(height: 40),

                Column(
                  children: [
                    Divider(thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    SizedBox(height: 10),
                    Text(
                      "Follow us @TaskBunnyApp",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "We’re here to help you get things done 🛠️",
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.grey[600] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
