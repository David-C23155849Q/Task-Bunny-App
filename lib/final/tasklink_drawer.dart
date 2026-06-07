import 'package:flutter/material.dart';

class TaskLinkDrawer extends StatelessWidget {
  final VoidCallback onSwitchToDriver;

  const TaskLinkDrawer({Key? key, required this.onSwitchToDriver})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Profile
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/default_avatar.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("David", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(" 4.8", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
            const Divider(),

            // Menu items
            _buildMenuItem(context, Icons.location_city, "City"),
            _buildMenuItem(context, Icons.history, "Request history"),
            _buildMenuItem(context, Icons.public, "City to City"),
            _buildMenuItem(context, Icons.notifications_none, "Notifications"),
            _buildMenuItem(context, Icons.security, "Safety"),
            _buildMenuItem(context, Icons.settings, "Settings"),
            _buildMenuItem(context, Icons.help_outline, "Help"),
            _buildMenuItem(context, Icons.chat_bubble_outline, "Support"),

            const Spacer(),

            // Driver mode toggle button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: ElevatedButton(
                onPressed: onSwitchToDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCBF135), // Lime green
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Driver mode"),
              ),
            ),

            // Social media icons
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.facebook, color: Colors.blue, size: 30),
                  SizedBox(width: 20),
                  Icon(Icons.camera_alt_outlined, color: Colors.pink, size: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // Close drawer
        // Handle navigation logic here...
      },
    );
  }
}
