import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/worker_profile_tab.dart';
import 'package:flutter/material.dart';

class WorkerProfileViewScreen extends StatelessWidget {
  final String uid;

  const WorkerProfileViewScreen({Key? key, required this.uid})
      : super(key: key);



  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Worker Profile")),
        body: const Center(child: Text("Invalid worker ID")),
      );
    }

    final docRef =
    FirebaseFirestore.instance.collection('workers').doc(uid);

    return Scaffold(
      //appBar: AppBar(
        //title: const Text("Your Profile"),
      //  backgroundColor: Colors.blue[800],
     // ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Worker not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final profileImageUrl = data['profileImageUrl'] ?? '';
          final username = data['username'] ?? '';
          final name = data['name'] ?? '';
          final city = data['city'] ?? '';
          final bio = data['bio'] ?? '';
          final rating = data['rating']?.toDouble() ?? 0.0;
          final categories = List<String>.from(data['categories'] ?? []);
          final resourceImages =
          List<String>.from(data['resourceImageUrls'] ?? []);
          final phone = data['phone'] ?? '';
          final email = data['email'] ?? '';
          final resources = Map<String, dynamic>.from(data['resources'] ?? {});

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Username and Name
                Center(
                  child: Column(
                    children: [
                      Text(
                        username,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(city, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          rating.toInt(),
                              (_) => const Icon(Icons.star,
                              size: 18, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Contact Info
                Text("📞 Contact", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text("Phone: $phone"),
                Text("Email: $email"),

                const SizedBox(height: 24),

                // Bio
                Text("🧾 Bio", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(bio, style: Theme.of(context).textTheme.bodyMedium),

                const SizedBox(height: 24),

                // Categories / Skills
                Text("🛠 Skills", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories
                      .take(3)
                      .map((cat) => Chip(label: Text(cat)))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Resources
                if (resources.isNotEmpty) ...[
                  Text("🧰 Resources", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: resources.entries
                        .where((e) => e.value == true)
                        .map((e) => Chip(label: Text(e.key)))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Resource Images
                if (resourceImages.isNotEmpty) ...[
                  Text("📸 Resource Images",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: resourceImages
                        .map((url) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ))
                        .toList(),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkerProfileScreen(),
                        ),
                      );
                    },child:
                  const Text("Edit Profile Info", style: TextStyle(fontSize: 16)),
                  )
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
