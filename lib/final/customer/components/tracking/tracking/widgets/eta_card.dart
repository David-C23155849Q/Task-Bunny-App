import 'package:flutter/material.dart';

class EtaCard extends StatelessWidget {
  final double distanceKm;
  final String eta;
  final String status;

  const EtaCard({
    super.key,
    required this.distanceKm,
    required this.eta,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text("Distance",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${distanceKm.toStringAsFixed(1)} km"),
              ],
            ),
            Column(
              children: [
                const Text("ETA",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(eta),
              ],
            ),
            Column(
              children: [
                const Text("Status",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}