import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  final picker = ImagePicker();

  Future<void> _pickImage(bool isProfile) async {
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

  Future<String?> _toBase64(File file) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 40,
      minWidth: 400,
      minHeight: 400,
    );

    if (compressed == null) return null;

    return base64Encode(compressed);
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
      // ✅ PROFILE IMAGE → BASE64
      final profileBase64 = await _toBase64(profileImage!);

      // ✅ RESOURCE IMAGES → BASE64 LIST
      List<String> resourceBase64List = [];

      for (final img in resourceImages) {
        final base64 = await _toBase64(img);
        if (base64 != null) {
          resourceBase64List.add(base64);
        }
      }

      // ✅ SAVE EVERYTHING IN FIRESTORE
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

        // ✅ IMAGES AS BASE64
        'profileImageBase64': profileBase64,
        'resourceImagesBase64': resourceBase64List,

        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': true,
        'role': 'worker',

        // defaults
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage != null
                        ? FileImage(profileImage!)
                        : null,
                    child: profileImage == null
                        ? const Icon(Icons.camera_alt)
                        : null,
                  ),
                ),

                const SizedBox(height: 30),

                Wrap(
                  spacing: 10,
                  children: [
                    for (var img in resourceImages)
                      Stack(
                        children: [
                          Image.file(
                            img,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => resourceImages.remove(img));
                              },
                              child: const Icon(Icons.close, color: Colors.red),
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
                          color: Colors.grey[300],
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: isLoading ? null : _finishSignup,
                  child: const Text("Finish Signup"),
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