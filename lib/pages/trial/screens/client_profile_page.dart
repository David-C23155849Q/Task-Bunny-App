import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';

class ClientProfilePage extends StatefulWidget {
  @override
  _ClientProfilePageState createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  final _storage = FirebaseStorage.instance;

  Map<String, dynamic> userData = {};
  bool isLoading = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _db.ref("users/$uid").get();
    if (snapshot.exists) {
      setState(() {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      await uploadProfilePicture();
    }
  }

  Future<void> uploadProfilePicture() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _selectedImage == null) return;

    final ref = _storage.ref().child("users/$uid/profile.jpg");
    await ref.putFile(_selectedImage!);
    final url = await ref.getDownloadURL();

    await _db.ref("users/$uid/photo").set(url);

    setState(() {
      userData['photo'] = url;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile picture updated!")),
    );
  }

  Future<void> resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset email sent to $email")),
      );
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete your account? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = user.uid;

      try {
        await user.delete();
        await _db.ref("users/$uid").remove();
        await _storage.ref("users/$uid/profile.jpg").delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account deleted.")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => ClientLoginScreen()),
              (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete account. Re-login required.")),
        );
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ClientLoginScreen()),
          (route) => false,
    );
  }

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Log Out"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text("Log Out"),
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
          ),
        ],
      ),
    );
  }

  void editPhoneDialog() {
    final controller = TextEditingController(text: userData['phone'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Phone Number"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: "Enter new phone number"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                final uid = _auth.currentUser?.uid;
                if (uid != null) {
                  await _db.ref("users/$uid/phone").set(newPhone);
                  setState(() => userData['phone'] = newPhone);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Phone number updated!")),
                  );
                }
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      //appBar: AppBar(
       // title: Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
       // centerTitle: true,
     // ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchUserData,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: userData['photo'] != null
                        ? NetworkImage(userData['photo'])
                        : AssetImage('assets/images/avatar.png') as ImageProvider,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.black),
                    onPressed: pickImage,
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "👤 My Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text("Name"),
                subtitle: Text(userData['name'] ?? 'Not set'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text("Email"),
                subtitle: Text(userData['email'] ?? 'Not set'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.phone),
                title: Text("Phone"),
                subtitle: Text(userData['phone'] ?? 'Not set'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: editPhoneDialog,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.lock_reset),
              label: Text("Reset Password"),
              onPressed: resetPassword,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              onPressed: confirmLogout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
            SizedBox(height: 10),
            OutlinedButton.icon(
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text("Delete Account", style: TextStyle(color: Colors.red)),
              onPressed: deleteAccount,
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
