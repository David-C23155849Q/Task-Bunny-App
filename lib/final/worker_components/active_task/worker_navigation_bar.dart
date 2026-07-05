import 'package:flutter/material.dart';

class WorkerNavigationBar extends StatelessWidget {
  final double distanceKm;
  final double etaMinutes;
  final VoidCallback onRecenter;
  final VoidCallback onCancel;

  const WorkerNavigationBar({
    super.key,
    required this.distanceKm,
    required this.etaMinutes,
    required this.onRecenter,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            /// Distance
            _infoBox(
              icon: Icons.route,
              label: "Distance",
              value: "${distanceKm.toStringAsFixed(1)} km",
              color: Colors.blue,
            ),

            const SizedBox(width: 12),

            /// ETA
            _infoBox(
              icon: Icons.timer,
              label: "ETA",
              value: "${etaMinutes.toStringAsFixed(0)} min",
              color: Colors.orange,
            ),

            const Spacer(),

            /// Recenter
            IconButton(
              onPressed: onRecenter,
              icon: const Icon(Icons.my_location),
              tooltip: "Recenter",
            ),

            /// Cancel / Exit
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              color: Colors.red,
              tooltip: "Exit Task",
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}