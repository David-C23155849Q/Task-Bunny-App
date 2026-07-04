import 'package:flutter/material.dart';

import 'controllers/tracking_controller.dart';
import 'widgets/tracking_map.dart';
import 'widgets/worker_card.dart';
import 'widgets/eta_card.dart';
import 'widgets/follow_button.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String taskId;

  const CustomerTrackingScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<CustomerTrackingScreen> createState() =>
      _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  late final TrackingController controller;

  @override
  void initState() {
    super.initState();

    controller = TrackingController(taskId: widget.taskId);

    controller.initialize(); // ✅ FIXED (was init)

    controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          TrackingMap(controller: controller),

          /// ETA CARD (FIXED PARAMS)
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: EtaCard(
              distanceKm: controller.distanceKm,
              eta: controller.eta,
              status: controller.taskStatus,
            ),
          ),

          /// FOLLOW BUTTON
          Positioned(
            right: 15,
            bottom: 250,
            child: FollowButton(
              isFollowing: controller.followWorker,
              onPressed: () {
                controller.toggleFollowWorker();
                controller.centerOnWorker();
              },
            ),
          ),

          /// WORKER CARD (FIXED PARAMS)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: WorkerCard(
              name: controller.workerLocation == null
                  ? "Worker"
                  : "Worker",
              photoUrl: "",
              rating: 4.5,
              onCall: () {},
              onChat: () {},
            ),
          ),
        ],
      ),
    );
  }
}