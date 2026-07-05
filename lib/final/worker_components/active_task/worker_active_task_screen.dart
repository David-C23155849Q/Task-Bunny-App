
import 'package:errand_app/final/worker_components/active_task/worker_active_task_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/models/route_model.dart';
import '../../services/widgets/taskbunny_map.dart';
import '../../services/widgets/taskbunny_marker.dart';


import 'worker_customer_card.dart';
import 'worker_navigation_bar.dart';
import 'worker_task_status_widget.dart';

class WorkerActiveTaskScreen extends StatefulWidget {
  final String taskId;

  const WorkerActiveTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<WorkerActiveTaskScreen> createState() =>
      _WorkerActiveTaskScreenState();
}

class _WorkerActiveTaskScreenState
    extends State<WorkerActiveTaskScreen> {

  late WorkerActiveTaskController controller;

  final MapController mapController = MapController();

  bool _initialCameraMoved = false;
  bool _mapReady = false;

  int _activePanel = -1;

  @override
  void initState() {
    super.initState();

    controller = WorkerActiveTaskController(
      taskId: widget.taskId,
    );

    controller.addListener(_controllerListener);

    controller.initialize();

  }

  void _controllerListener() {
    if (!mounted) return;

    setState(() {});

    if (controller.workerLocation == null) return;

    // ✅ ADD THIS GUARD HERE
    if (!_mapReady) return;

    if (!_initialCameraMoved) {
      _initialCameraMoved = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(controller.workerLocation!, 17);
      });
    }

    if (controller.followingWorker) {
      mapController.move(
        controller.workerLocation!,
        mapController.camera.zoom,
      );
    }
  }

  Widget _iconButton(IconData icon, int index) {
    final isActive = _activePanel == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activePanel = isActive ? -1 : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActivePanel() {
    switch (_activePanel) {
      case 0:
        return WorkerCustomerCard(
          task: controller.task!,
          distanceKm: controller.distanceKm,
          etaMinutes: controller.etaMinutes,
        );

      case 1:
        return WorkerTaskStatusWidget(
          controller: controller,
        );

      case 2:
        return WorkerNavigationBar(
          distanceKm: controller.distanceKm,
          etaMinutes: controller.etaMinutes,
          onRecenter: () {
            controller.followingWorker = true;
            mapController.move(controller.workerLocation!, 18);
          },
          onCancel: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Exit Task"),
                content: const Text("Are you sure you want to leave this task?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await controller.cancelTask();
              if (context.mounted) Navigator.pop(context);
            }
          },
        );

      default:
        return const SizedBox.shrink(); // closed state
    }
  }

  @override
  void dispose() {
    controller.removeListener(_controllerListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (controller.error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(controller.error),
        ),
      );
    }

    if (!controller.isReady) {
      return const Scaffold(
        body: Center(
          child: Text("Loading task..."),
        ),
      );
    }

    return Scaffold(

      body: Stack(

        children: [

          _buildMap(),

          _buildTopBar(),

          _buildBottomPanel(),

          _buildRecenterButton(),

        ],

      ),

    );
  }

  Widget _buildMap() {
    return TaskBunnyMap(
      controller: mapController,
      center: controller.workerLocation!,
      zoom: 17,

      route: controller.routePoints.isEmpty
          ? null
          : RouteModel(
        points: controller.routePoints,
        distance: controller.distanceKm * 1000, // km → meters
        duration: controller.etaMinutes * 60,   // minutes → seconds
      ),

      markers: [
        TaskBunnyMarker.worker(
          controller.workerLocation!,
        ),

        Marker(
          point: controller.task!.pickupLocation,
          width: 45,
          height: 45,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 42,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Row(

          children: [

            FloatingActionButton.small(

              heroTag: "back",

              onPressed: () {
                Navigator.pop(context);
              },

              child: const Icon(Icons.arrow_back),

            ),

            const Spacer(),

            Container(

              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                BorderRadius.circular(25),

              ),

              child: Text(

                "${controller.distanceKm.toStringAsFixed(1)} km",

                style: const TextStyle(

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

          ],

        ),

      ),

    );
  }

  Widget _buildRecenterButton() {
    return Positioned(

      bottom: 280,

      right: 20,

      child: FloatingActionButton(

        heroTag: "gps",

        onPressed: () {
          controller.followingWorker = true;

          mapController.move(

            controller.workerLocation!,

            18,

          );
        },

        child: const Icon(

          Icons.my_location,

        ),

      ),

    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black26,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// 🔹 ICON BAR
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    _iconButton(Icons.person, 0),
                    _iconButton(Icons.task_alt, 1),
                    _iconButton(Icons.navigation, 2),

                  ],
                ),
              ),

              /// 🔹 EXPANDABLE CONTENT
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildActivePanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}