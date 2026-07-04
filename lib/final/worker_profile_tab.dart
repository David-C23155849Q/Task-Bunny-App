import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// ui helper
extension UIComponents on State {
  Widget buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
        ),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }
}

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key, required String uid});

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
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.check_circle, color: Colors.blue), onPressed: saveChanges)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: newProfileImage != null
                          ? FileImage(newProfileImage!)
                          : (profileImageUrl != null ? NetworkImage(profileImageUrl!) : null) as ImageProvider?,
                      child: (newProfileImage == null && profileImageUrl == null) ? const Icon(Icons.person, size: 50) : null,
                    ),
                    Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.blue, radius: 18, child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: pickProfileImage))),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Personal Info
              buildSection("Personal Details", [
                _modernTextField("Full Name", name ?? "", (val) => name = val),
                _modernTextField("Username", username ?? "", (val) => username = val),
                _modernTextField("Phone", phone ?? "", (val) => phone = val, type: TextInputType.phone),
                _modernTextField("City", city ?? "", (val) => city = val),
              ]),

              // Categories
              buildSection("Services Provided (Max 3)", [
                Wrap(
                  spacing: 8,
                  children: allCategories.map((cat) => FilterChip(
                    label: Text(cat),
                    selected: categories.contains(cat),
                    onSelected: (val) => setState(() => val && categories.length < 3 ? categories.add(cat) : categories.remove(cat)),
                  )).toList(),
                )
              ]),

              // Resource Images
              buildSection("Work Samples (${resourceImageUrls.length + newResourceImages.length}/4)", [
                _buildImageGrid(),
              ]),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernTextField(String label, String init, Function(String) onSave, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: init,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        onSaved: (val) => onSave(val!),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: [
        ...resourceImageUrls.asMap().entries.map((e) => _imageBox(url: e.value, onRemove: () => removeResourceImage(e.key))),
        ...newResourceImages.map((f) => _imageBox(file: f)),
        if ((resourceImageUrls.length + newResourceImages.length) < 4)
          InkWell(
            onTap: pickResourceImage,
            child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue)), child: const Icon(Icons.add, color: Colors.blue)),
          )
      ],
    );
  }

  Widget _imageBox({String? url, File? file, VoidCallback? onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: url != null ? Image.network(url, width: 80, height: 80, fit: BoxFit.cover) : Image.file(file!, width: 80, height: 80, fit: BoxFit.cover)),
        if (onRemove != null) Positioned(top: 0, right: 0, child: IconButton(onPressed: onRemove, icon: const Icon(Icons.cancel, color: Colors.red))),
      ],
    );
  }
}