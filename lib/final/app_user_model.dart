import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String uid;
  final String username;
  final String role;
  final String? email;

  AppUserModel({
    required this.uid,
    required this.username,
    required this.role,
    this.email,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      role: data['role'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
