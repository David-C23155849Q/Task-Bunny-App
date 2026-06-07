import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;


class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({Key? key}) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? name;
  String? email;
  String? phone;
  String? profileImageUrl;

  bool isEditingName = false;
  bool isEditingPhone = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    if (user == null) return;
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        name = data['username'];
        email = data['email'];
        phone = data['phone'];
        profileImageUrl = data['profileImage'];
        _nameController.text = name ?? '';
        _phoneController.text = phone ?? '';
      });
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['username'] = name;
    if (phone != null) updates['phone'] = phone;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(updates);
    fetchProfileData();
  }

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = path.basename(file.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user!.uid}/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profileImage': downloadUrl});

      setState(() {
        profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated!")),
      );
    }
  }


  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .delete();
              await user!.delete();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? Icon(Icons.person, size: 60, color: textColor)
                      : null,
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: textColor),
                  onPressed: _changeProfileImage,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email (non-editable)
            _buildTile(
              context,
              icon: Icons.email,
              label: "Email",
              value: email ?? "Not set",
              isEditable: false,
            ),

            // Name (editable)
            _buildTile(
              context,
              icon: Icons.person,
              label: "Name",
              value: name ?? "Not set",
              isEditable: true,
              isEditing: isEditingName,
              controller: _nameController,
              onEditTap: () => setState(() => isEditingName = !isEditingName),
              onSave: () {
                updateProfile(name: _nameController.text.trim());
                setState(() => isEditingName = false);
              },
            ),

            // Phone (editable)
            _buildTile(
              context,
              icon: Icons.phone,
              label: "Phone",
              value: phone ?? "Not set",
              isEditable: true,
              isEditing: isEditingPhone,
              controller: _phoneController,
              onEditTap: () => setState(() => isEditingPhone = !isEditingPhone),
              onSave: () {
                updateProfile(phone: _phoneController.text.trim());
                setState(() => isEditingPhone = false);
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => FirebaseAuth.instance.sendPasswordResetEmail(email: email!),
              icon: const Icon(Icons.lock_reset),
              label: const Text("Reset Password"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil("/", (_) => false);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Delete Account"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        bool isEditable = false,
        bool isEditing = false,
        TextEditingController? controller,
        VoidCallback? onEditTap,
        VoidCallback? onSave,
      }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing && controller != null
                ? TextField(
              controller: controller,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit,
                color: theme.iconTheme.color,
              ),
              onPressed: isEditing ? onSave : onEditTap,
            ),
        ],
      ),
    );
  }
}
