import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'active_task_model.dart';
import 'worker_route_service.dart';

class WorkerActiveTaskController extends ChangeNotifier {
  WorkerActiveTaskController({
    required this.taskId,
  });

  final String taskId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String workerId = FirebaseAuth.instance.currentUser!.uid;

  final WorkerRouteService _routeService = WorkerRouteService();

  StreamSubscription<DocumentSnapshot>? _taskSubscription;
  StreamSubscription<Position>? _gpsSubscription;

  ActiveTaskModel? task;

  LatLng? workerLocation;

  List<LatLng> routePoints = [];

  bool loading = true;

  bool followingWorker = true;

  double distanceKm = 0;

  double etaMinutes = 0;

  bool arrived = false;

  bool navigating = false;

  String error = "";

  bool get hasTask => task != null;

  bool get hasLocation => workerLocation != null;

  bool get isReady => task != null && workerLocation != null;

  bool get canArrive =>
      task != null &&
          task!.status == "heading_to_customer";

  bool get canStart =>
      task != null &&
          task!.status == "arrived";

  bool get canComplete =>
      task != null &&
          task!.status == "in_progress";

  bool _updating = false;

  /// innit
Future<void> initialize() async {
  loading = true;
  notifyListeners();

  await _loadTask();

  await _startGps();

  _listenToTask();

  loading = false;

  notifyListeners();
}
/// load task
Future<void> _loadTask() async {
  try {
    final doc =
    await _firestore.collection("tasks").doc(taskId).get();

    if (!doc.exists) {
      error = "Task not found";
      return;
    }

    final taskData = doc.data()!;

    final customerId = taskData["customerId"];

    Map<String, dynamic>? customer;

    if (customerId != null) {
      final customerDoc = await _firestore
          .collection("customers")
          .doc(customerId)
          .get();

      customer = customerDoc.data();
    }

    task = ActiveTaskModel.fromFirestore(
      doc.id,
      taskData,
      customer,
    );
  } catch (e) {
    error = e.toString();
  }
}

///listen for task updates

void _listenToTask() {
  _taskSubscription?.cancel();

  _taskSubscription = _firestore
      .collection("tasks")
      .doc(taskId)
      .snapshots()
      .listen((snapshot) async {
    if (!snapshot.exists) return;

    final data = snapshot.data()!;

    final customerDoc = await _firestore
        .collection("customers")
        .doc(data["customerId"])
        .get();

    task = ActiveTaskModel.fromFirestore(
      snapshot.id,
      data,
      customerDoc.data(),
    );

    await _refreshRoute();

    notifyListeners();
  });
}

/// start gps function

Future<void> _startGps() async {
  final first = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  workerLocation = LatLng(
    first.latitude,
    first.longitude,
  );

  await _updateWorkerLocation();

  await _refreshRoute();

  _gpsSubscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    ),
  ).listen((position) async {
    workerLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    await _updateWorkerLocation();

    await _refreshRoute();

    notifyListeners();
  });
}

/// update firestore location

  Future<void> _updateWorkerLocation() async {
    if (workerLocation == null) return;

    final taskRef = _firestore.collection("tasks").doc(taskId);
    final taskSnap = await taskRef.get();

    // ✅ STOP IF TASK DOESN'T EXIST
    if (!taskSnap.exists) return;

    await _firestore.collection("workers").doc(workerId).update({
      "location": {
        "lat": workerLocation!.latitude,
        "lng": workerLocation!.longitude,
      }
    });

    await taskRef.update({
      "workerLocation": {
        "lat": workerLocation!.latitude,
        "lng": workerLocation!.longitude,
      }
    });
  }

/// saftey
  Future<bool> _safeTaskUpdate(Map<String, dynamic> data) async {
    final ref = _firestore.collection("tasks").doc(taskId);

    final snap = await ref.get();
    if (!snap.exists) {
      error = "Task no longer exists";
      notifyListeners();
      await _stopGps();
      return false;
    }

    try {
      await ref.update(data);
      return true;
    } catch (e) {
      error = "Update failed: $e";
      notifyListeners();
      return false;
    }
  }
  /// gps funct
  Future<void> _stopGps() async {
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }
/// refresh routes function

Future<void> _refreshRoute() async {
  if (workerLocation == null || task == null) return;

  navigating = true;
  notifyListeners();

  final result = await _routeService.getRoute(
    start: workerLocation!,
    destination: task!.pickupLocation,
  );

  routePoints = result.polyline;
  distanceKm = result.distanceKm;
  etaMinutes = result.durationMinutes;

  arrived = _routeService.hasArrived(
    worker: workerLocation!,
    pickup: task!.pickupLocation,
  );

  navigating = false;

  notifyListeners();
}

/// headed to customer
Future<void> startHeading() async {
  if (task == null) return;

  await _firestore.collection("tasks").doc(taskId).update({
    "status": "heading_to_customer",
  });
}

/// arrived
Future<void> arrive() async {
  if (task == null) return;

  await _firestore.collection("tasks").doc(taskId).update({
    "status": "arrived",
    "arrivedAt": FieldValue.serverTimestamp(),
  });
}

/// start task
Future<void> startTask() async {
  if (task == null) return;

  await _firestore.collection("tasks").doc(taskId).update({
    "status": "in_progress",
    "startedAt": FieldValue.serverTimestamp(),
  });
}

/// complete task
Future<void> completeTask() async {
  if (task == null) return;

  final batch = _firestore.batch();

  final taskRef = _firestore.collection("tasks").doc(taskId);

  final workerRef =
  _firestore.collection("workers").doc(workerId);

  batch.update(taskRef, {
    "status": "completed",
    "completedAt": FieldValue.serverTimestamp(),
  });

  batch.update(workerRef, {
    "availability": "available",
    "currentTaskId": FieldValue.delete(),
  });

  await batch.commit();
}

/// cancel task
Future<void> cancelTask() async {
  if (task == null) return;

  await _firestore.collection("tasks").doc(taskId).update({
    "status": "cancelled",
  });

  await _firestore.collection("workers").doc(workerId).update({
    "availability": "available",
    "currentTaskId": FieldValue.delete(),
  });
}



@override
void dispose() {
  _taskSubscription?.cancel();
  _gpsSubscription?.cancel();
  super.dispose();
}
}
