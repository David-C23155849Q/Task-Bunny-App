import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> allCategories = [
    'Cleaning',
    'Furniture Assembly',
    'Electrical Help',
    'Painting',
    'Handyman',
    'Yard Work',
    'Mounting',
    'Pickup and Dropoff',
    'Delivery',
    'Home Repairs',
    'Personal Assistant',
    'Errands',
    'Help Moving',
    'Event Staffing',
  ];

  final picker = ImagePicker();
  final formKey = GlobalKey<FormState>();

  String? name, username, phone, city, bio, email;
  List<String> categories = [];
  Map<String, bool> resources = {};
  List<String> resourceImageUrls = [];
  File? newProfileImage;
  String? profileImageUrl;
  List<File> newResourceImages = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('workers').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        name = data['name'];
        username = data['username'];
        phone = data['phone'];
        city = data['city'];
        bio = data['bio'];
        email = data['email'];
        categories = List<String>.from(data['categories'] ?? []);
        resources = Map<String, bool>.from(data['resources'] ?? {});
        profileImageUrl = data['profileImageUrl'];
        resourceImageUrls = List<String>.from(data['resourceImageUrls'] ?? []);
        isLoading = false;
      });
    }
  }

  Future<void> pickProfileImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newProfileImage = File(picked.path));
    }
  }

  Future<void> pickResourceImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && (resourceImageUrls.length + newResourceImages.length) < 4) {
      setState(() => newResourceImages.add(File(picked.path)));
    }
  }

  Future<void> removeResourceImage(int index) async {
    final uid = _auth.currentUser?.uid;
    final oldUrl = resourceImageUrls[index];
    await FirebaseStorage.instance.refFromURL(oldUrl).delete();
    resourceImageUrls.removeAt(index);
    await _firestore.collection('workers').doc(uid).update({
      'resourceImageUrls': resourceImageUrls,
    });
    setState(() {});
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) return;
    formKey.currentState!.save();

    setState(() => isLoading = true);

    final uid = _auth.currentUser?.uid;
    final storageRef = FirebaseStorage.instance.ref();
    String? uploadedProfileUrl;

    if (newProfileImage != null) {
      final ref = storageRef.child('workers/$uid/profile.jpg');
      await ref.putFile(newProfileImage!);
      uploadedProfileUrl = await ref.getDownloadURL();
    }

    // Upload new resource images
    for (var i = 0; i < newResourceImages.length; i++) {
      final ref = storageRef.child('workers/$uid/resources/resource_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(newResourceImages[i]);
      final url = await ref.getDownloadURL();
      resourceImageUrls.add(url);
    }

    await _firestore.collection('workers').doc(uid).update({
      'name': name,
      'username': username,
      'phone': phone,
      'city': city,
      'bio': bio,
      'categories': categories,
      'resources': resources,
      'profileImageUrl': uploadedProfileUrl ?? profileImageUrl,
      'resourceImageUrls': resourceImageUrls,
    });

    setState(() {
      newProfileImage = null;
      newResourceImages = [];
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: newProfileImage != null
                      ? FileImage(newProfileImage!)
                      : (profileImageUrl != null ? NetworkImage(profileImageUrl!) : null) as ImageProvider?,
                  child: newProfileImage == null && profileImageUrl == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              buildTextField("Full Name", name!, (val) => name = val),
              buildTextField("Username", username!, (val) => username = val),
              buildTextField("Phone", phone!, (val) => phone = val, keyboard: TextInputType.phone),
              buildTextField("City", city!, (val) => city = val),
              buildTextField("Bio", bio!, (val) => bio = val, maxLines: 3),
              buildTextField("Email", email ?? '', (_) {}, readOnly: true),

              const SizedBox(height: 16),
              const Text("Categories (max 3)"),
              Wrap(
                spacing: 8,
                children: allCategories.map((cat) {
                  final selected = categories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val && categories.length < 3) {
                          categories.add(cat);
                        } else if (!val) {
                          categories.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Text("Resources"),
              ...['tools', 'vehicle'].map((key) {
                return SwitchListTile(
                  title: Text("Has ${key[0].toUpperCase()}${key.substring(1)}"),
                  value: resources[key] ?? false,
                  onChanged: (val) {
                    setState(() => resources[key] = val);
                  },
                );
              }),

              const SizedBox(height: 16),
              const Text("Resource Images"),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...resourceImageUrls.asMap().entries.map((entry) {
                    final i = entry.key;
                    final url = entry.value;
                    return Stack(
                      children: [
                        Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => removeResourceImage(i),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  ...newResourceImages.map((file) => Image.file(file, width: 100, height: 100, fit: BoxFit.cover)),
                  if ((resourceImageUrls.length + newResourceImages.length) < 4)
                    GestureDetector(
                      onTap: pickResourceImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label,
      String initialValue,
      void Function(String) onSave, {
        bool readOnly = false,
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: (String? val) {
          if (val != null) name = val;
        },

      ),
    );
  }

}
