import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:errand_app/final/worker_components/tasks/task_model.dart';
import '../bids/worker_task_bids_panel.dart';
import '../widgets/bid_dialog.dart';

class TaskDetailsSheet extends StatelessWidget {
  final TaskModel task;
  final LatLng workerLocation;

  const TaskDetailsSheet({
    super.key,
    required this.task,
    required this.workerLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate straight-line distance
    final distance = const Distance();

    final meters = distance(
      workerLocation,
      task.pickupLocation,
    );

    final km = meters / 1000;

    // Approximate driving time (40 km/h average)
    final minutes = (km / 40 * 60).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            /// Category + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.category,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "\$${task.price}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// Description
            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              task.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            /// Pickup Address
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Pickup"),
                subtitle: Text(task.pickupAddress),
              ),
            ),

            const SizedBox(height: 12),

            /// Distance
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.near_me,
                  color: Colors.blue,
                ),
                title: Text(
                  "${km.toStringAsFixed(1)} km away",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Approx. $minutes min drive",
                ),
              ),
            ),

            const SizedBox(height: 28),

            /// Bid Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                icon: const Icon(Icons.gavel),
                label: const Text(
                  "Place Bid",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(context);

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => WorkerTaskBidsSheet(taskId: task.id,),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}