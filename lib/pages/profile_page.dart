import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../authentication/login_screen.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String? profilePicture;
  String? name;
  String? email;
  String? phoneNumber;
  XFile? imageFile;
  String urlOfUploadedImage = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _databaseReference.child('users/$userId').once();

    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        profilePicture = data['photo'];
        name = data['name'];
        email = data['email'];
        phoneNumber = data['phone'];
      });
    }
  }



  Future<void> uploadImageToStorage() async {
    if (imageFile == null) return;

    String imageIDName = DateTime.now().microsecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance.ref().child("images").child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    final userId = FirebaseAuth.instance.currentUser!.uid;
    await _databaseReference.child('users/$userId').update({'photo': urlOfUploadedImage});

    setState(() {
      profilePicture = urlOfUploadedImage;
    });
  }

  Future<void> chooseImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Center( // Center the entire body
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center column items
            children: [
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              imageFile == null
                  ? CircleAvatar(
                radius: 86,
                backgroundImage: profilePicture != null
                    ? NetworkImage(profilePicture!)
                    : AssetImage("assets/images/profile_avatar.png") as ImageProvider,
              )
                  : Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(File(imageFile!.path)),
                  ),
                ),
              ),
              GestureDetector(
                onTap: chooseImageFromGallery,
                child: const Text(
                  "Add Profile",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),


              const SizedBox(height: 16),


              Text(
                name ?? 'Loading...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),


              const SizedBox(height: 8),


              Text(email ?? 'Loading...', style: TextStyle(fontSize: 18)),


              const SizedBox(height: 8),


              Text(phoneNumber ?? 'Loading...', style: TextStyle(fontSize: 18)),


              const SizedBox(height: 22),


              ElevatedButton(
                onPressed: uploadImageToStorage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                ),
                child: const Text("Save Image"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                ),
                child: const Text("Log Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}