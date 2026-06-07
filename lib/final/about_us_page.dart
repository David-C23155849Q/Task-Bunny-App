import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 👈 go back
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/bunny.png'), // Replace with your logo
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 20),
            Text(
              "TaskLink",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Connecting you to trusted help in your city — anytime, anywhere.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              "Who We Are",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              "TaskLink is a platform that bridges the gap between clients who need tasks done and skilled workers (taskers) ready to help. Whether it's cleaning, moving, repairs, or deliveries — we simplify the process and ensure quality service every time.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              "Our Mission",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              "To empower local communities by providing easy access to reliable taskers while creating earning opportunities for skilled individuals.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              "Contact Us",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.email),
              title: Text("support@tasklink.co.zw"),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text("+263 78 076 6533"),
            ),
            ListTile(
              leading: Icon(Icons.web),
              title: Text("www.tasklink.co.zw"),
            ),
            const SizedBox(height: 40),
            Text(
              "© ${DateTime.now().year} TaskLink. All rights reserved.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
