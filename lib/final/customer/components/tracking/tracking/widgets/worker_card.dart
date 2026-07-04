import 'package:flutter/material.dart';

class WorkerCard extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double rating;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const WorkerCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.onCall,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage:
              photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: onCall,
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: onChat,
            ),
          ],
        ),
      ),
    );
  }
}