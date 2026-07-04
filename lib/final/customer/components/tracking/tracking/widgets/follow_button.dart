import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onPressed;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "follow",
      onPressed: onPressed,
      child: Icon(
        isFollowing ? Icons.my_location : Icons.location_disabled,
      ),
    );
  }
}