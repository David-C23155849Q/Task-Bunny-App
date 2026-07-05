import 'package:flutter/material.dart';

import 'active_task_model.dart';

class WorkerCustomerCard extends StatelessWidget {
  final ActiveTaskModel task;

  final double distanceKm;
  final double etaMinutes;

  const WorkerCustomerCard({
    super.key,
    required this.task,
    required this.distanceKm,
    required this.etaMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Customer
            Row(
              children: [

                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                        task.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        task.customerPhone.isEmpty
                            ? "No phone number"
                            : task.customerPhone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),

                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    "\$${task.acceptedPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 20),

            Divider(
              color: Colors.grey.shade300,
            ),

            const SizedBox(height: 12),

            _infoRow(
              Icons.work_outline,
              "Task",
              task.description,
            ),

            const SizedBox(height: 10),

            _infoRow(
              Icons.category,
              "Category",
              task.category,
            ),

            const SizedBox(height: 10),

            _infoRow(
              Icons.place,
              "Pickup",
              task.pickupAddress,
            ),

            const SizedBox(height: 18),

            Row(
              children: [

                Expanded(
                  child: _statCard(
                    "Distance",
                    "${distanceKm.toStringAsFixed(1)} km",
                    Icons.route,
                    Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _statCard(
                    "ETA",
                    "${etaMinutes.toStringAsFixed(0)} min",
                    Icons.timer,
                    Colors.orange,
                  ),
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Icon(
          icon,
          color: Colors.blue,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

            ],
          ),
        ),

      ],
    );
  }

  Widget _statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: [

          Icon(
            icon,
            color: color,
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),

        ],
      ),
    );
  }
}