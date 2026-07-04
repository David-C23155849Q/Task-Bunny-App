import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/worker_components/bids/worker_task_bids_panel.dart';
import 'package:errand_app/final/worker_components/tasks/task_details_sheet.dart';
import 'package:errand_app/final/worker_components/tasks/task_model.dart';
import 'package:errand_app/final/worker_components/tasks/worker_task_service.dart';
import 'package:errand_app/final/worker_components/widgets/worker_header_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../final/services/widgets/taskbunny_map.dart';
import '../../final/services/widgets/taskbunny_marker.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WorkerTaskService _taskService = WorkerTaskService();

  List<TaskModel> _tasks = [];

  LatLng? _workerLocation;
  String _city = "";
  List<String> _categories = [];

  StreamSubscription? _taskSub;
  StreamSubscription<Position>? _posSub;

  bool _loading = true;
  bool _didInitialMove = false;
  bool _followWorker = true;

  String _workerName = "";
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// ---------------- MASTER INIT ----------------
  Future<void> _init() async {
    await _loadWorkerData();
    await _loadWorkerProfile();
    await _startLiveGPS(); // must set _workerLocation
  }

  /// ---------------- FIRESTORE LOAD ----------------
  Future<void> _loadWorkerData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection("workers")
          .doc(uid)
          .get();

      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        _city = data["city"] ?? "";
        _categories = List<String>.from(data["categories"] ?? []);
      });

      debugPrint("CITY: $_city");
      debugPrint("CATEGORIES: $_categories");
    } catch (e) {
      debugPrint("Firestore load error: $e");
    }
  }

  /// ---------------- LIVE GPS (REAL DEVICE LOCATION) ----------------
  Future<void> _startLiveGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    // 🔥 FIRST LOCATION (IMPORTANT FIX)
    final first = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _moveToUser(first.latitude, first.longitude);

    // 🔥 STREAM UPDATES
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) async {
      _moveToUser(pos.latitude, pos.longitude);

      // update firestore silently
      await FirebaseFirestore.instance
          .collection("workers")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "location": {
          "lat": pos.latitude,
          "lng": pos.longitude,
        }
      });
    });



    setState(() => _loading = false);
  }

  /// ---------------- MOVE CAMERA + STATE ----------------
  void _moveToUser(double lat, double lng) {
    final newPos = LatLng(lat, lng);

    final firstLocation = _workerLocation == null;

    setState(() {
      _workerLocation = newPos;
    });

    // Start task stream once GPS is available
    if (firstLocation) {
      _startTaskStream();
    }

    if (!_didInitialMove) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(newPos, 20);
      });

      _didInitialMove = true;
      return;
    }

    if (_followWorker) {
      _mapController.move(newPos, 20);
    }
  }

  /// ---------------- TASK STREAM ----------------
  void _startTaskStream() {
    _taskSub?.cancel();

    if (_workerLocation == null) {
      debugPrint("Worker location not ready.");
      return;
    }

    if (_categories.isEmpty) {
      debugPrint("Worker categories not loaded.");
      return;
    }

    debugPrint("========== STARTING TASK STREAM ==========");
    debugPrint("Worker location: "
        "${_workerLocation!.latitude}, ${_workerLocation!.longitude}");
    debugPrint("Categories: $_categories");

    _taskSub = _taskService
        .getTasksForWorker(
      categories: _categories,
      workerLocation: _workerLocation!,
      radiusKm: 10,
    )
        .listen(
          (tasks) {
        debugPrint("TASKS RECEIVED: ${tasks.length}");

        for (final task in tasks) {
          debugPrint(
            "Task: ${task.description}"
                " (${task.pickupLocation.latitude}, "
                "${task.pickupLocation.longitude})",
          );
        }

        if (!mounted) return;

        setState(() {
          _tasks = tasks;
        });
      },
      onError: (e) {
        debugPrint("TASK STREAM ERROR: $e");
      },
    );
  }

  /// ---------------- TASK TAP ----------------
  void _onTaskTap(TaskModel task) {
    if (_workerLocation == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskDetailsSheet(
        task: task,
        workerLocation: _workerLocation!,
      ),
    );
  }

  /// recenter back to worker location
  void _recenterToWorker() {
    if (_workerLocation == null) return;

    _mapController.move(
      _workerLocation!,
      20, // fixed zoom for "focused tracking view"
    );
  }

  /// load worker profile
  Future<void> _loadWorkerProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("workers")
        .doc(uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _workerName = data["name"] ?? "Worker";
      _photoBase64 = data["profileImageBase64"];
    });
  }

  @override
  void dispose() {
    _taskSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: WorkerHeaderDrawer(
        name: _workerName,
        photoUrl: _photoBase64,
        onProfile: () {
          Navigator.pop(context);
          // navigate to profile screen
        },
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _workerLocation == null
          ? const Center(child: Text("Waiting for GPS..."))
          : Stack(
        children: [

          /// MAP LAYER
          TaskBunnyMap(
            controller: _mapController,
            center: _workerLocation!,
            zoom: 14,
            markers: [
              TaskBunnyMarker.worker(_workerLocation!),
              ..._tasks.map((task) =>
                  Marker(
                    point: task.pickupLocation,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _onTaskTap(task),
                      child: const Icon(
                          Icons.location_on, color: Colors.blueAccent,
                          size: 36),
                    ),
                  )),
            ],
          ),

          /// TOP CONTROLS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildGlassButton(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: Icons.menu_rounded,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(
                          0.05), blurRadius: 10)
                      ],
                    ),
                    child: Text(
                      "${_tasks.length} TASKS NEARBY",
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: _recenterToWorker,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to maintain a consistent "glass" look
  Widget _buildGlassButton(
      {required VoidCallback onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}