import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:errand_app/final/signup_completed.dart';

class WorkerSignupStep3 extends StatefulWidget {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String bio;
  final String city;
  final List<String> categories;
  final Map<String, bool> resources;

  const WorkerSignupStep3({
    super.key,
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.city,
    required this.categories,
    required this.resources,
  });

  @override
  State<WorkerSignupStep3> createState() => _WorkerSignupStep3State();
}

class _WorkerSignupStep3State extends State<WorkerSignupStep3> {
  File? profileImage;
  List<File> resourceImages = [];
  bool isLoading = false;

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          profileImage = File(image.path);
        } else if (resourceImages.length < 4) {
          resourceImages.add(File(image.path));
        }
      });
    }
  }

  Future<String> _uploadImage(File imageFile, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _finishSignup() async {
    if (profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a profile picture")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Upload profile image
      final profileImageUrl = await _uploadImage(
          profileImage!, 'workers/${widget.uid}/profile.jpg');

      // Upload resource images
      List<String> resourceImageUrls = [];
      for (int i = 0; i < resourceImages.length; i++) {
        String url = await _uploadImage(
            resourceImages[i], 'workers/${widget.uid}/resources/resource_$i.jpg');
        resourceImageUrls.add(url);
      }

      // Save all data to Firestore
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.uid)
          .set({
        'uid': widget.uid,
        'name': widget.name,
        'username': widget.username,
        'email': widget.email,
        'phone': widget.phone,
        'bio': widget.bio,
        'city': widget.city,
        'categories': widget.categories,
        'resources': widget.resources,
        'profileImageUrl': profileImageUrl,
        'resourceImageUrls': resourceImageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': true,
        'role': 'worker',

        // ✅ Default values
        'rating': 3.0,
        'blockStatus': 'no',
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SignupCompletePage(
            name: widget.name,
            username: widget.username,
          ),
        ),
      );
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Signup - Step 3"),
        backgroundColor: primaryBlue,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upload Your Images",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Add a profile picture and optional resource images (max 4)",
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),

                // Profile Image Picker
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(true),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                      child: profileImage == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Resource Images Grid
                Text(
                  "Resource Images (Optional)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var img in resourceImages)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              img,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => resourceImages.remove(img));
                              },
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (resourceImages.length < 4)
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_a_photo),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _finishSignup,
                    icon: const Icon(Icons.check),
                    label: const Text("Finish Signup"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
