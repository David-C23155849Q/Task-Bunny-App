import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/tracking_state.dart';
import '../models/trip_status.dart';
import '../models/worker_location.dart';

class TrackingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _taskSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _workerSub;

  TrackingState? _latestState;
  String? _listeningWorkerId;

  /// -------------------------------------------------
  /// TASK STREAM
  /// -------------------------------------------------
  Stream<TrackingState> listenToTask(String taskId) {
    final controller = StreamController<TrackingState>();

    _taskSub?.cancel();
    _workerSub?.cancel();

    _taskSub = _db
        .collection("tasks")
        .doc(taskId)
        .snapshots()
        .listen((taskDoc) {
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;

      final workerId = data["assignedWorkerId"];
      final customerId = data["customerId"];

      LatLng? pickupLocation;
      if (data["pickup"] != null) {
        pickupLocation = LatLng(
          (data["pickup"]["lat"] as num).toDouble(),
          (data["pickup"]["lng"] as num).toDouble(),
        );
      }

      LatLng? customerLocation;
      if (data["customerLocation"] != null) {
        customerLocation = LatLng(
          (data["customerLocation"]["lat"] as num).toDouble(),
          (data["customerLocation"]["lng"] as num).toDouble(),
        );
      }

      _latestState = (_latestState ??
          TrackingState(
            taskId: taskId,
          ))
          .copyWith(
        workerId: workerId,
        customerId: customerId,
        pickupLocation: pickupLocation,
        customerLocation: customerLocation,
        status: _parseStatus(data["status"] ?? "pending"),
      );

      controller.add(_latestState!);

      if (workerId != null &&
          workerId.toString().isNotEmpty &&
          workerId != _listeningWorkerId) {
        _listenToWorker(workerId, controller);
      }
    });

    controller.onCancel = dispose;

    return controller.stream;
  }

  /// -------------------------------------------------
  /// WORKER LIVE LOCATION
  /// -------------------------------------------------
  void _listenToWorker(
      String workerId,
      StreamController<TrackingState> controller,
      ) {
    _listeningWorkerId = workerId;

    _workerSub?.cancel();

    _workerSub = _db
        .collection("workers")
        .doc(workerId)
        .snapshots()
        .listen((workerDoc) {
      if (!workerDoc.exists) return;
      if (_latestState == null) return;

      final data = workerDoc.data()!;

      double? lat;
      double? lng;

      if (data["location"] != null) {
        lat = (data["location"]["lat"] as num?)?.toDouble();
        lng = (data["location"]["lng"] as num?)?.toDouble();
      } else {
        lat = (data["lat"] as num?)?.toDouble();
        lng = (data["lng"] as num?)?.toDouble();
      }

      if (lat == null || lng == null) return;

      _latestState = _latestState!.copyWith(
        workerLocation: WorkerLocation(
          workerId: workerId,
          position: LatLng(lat, lng),
          timestamp: DateTime.now(),
        ),

        workerName: data["name"] ?? "Worker",

        workerPhoto: data["profileImageBase64"] ?? "",

        workerRating:
        (data["rating"] as num?)?.toDouble() ?? 0.0,

        workerPhone: data["phone"] ?? "",
      );

      controller.add(_latestState!);
    });
  }

  /// -------------------------------------------------
  /// STATUS PARSER
  /// -------------------------------------------------
  TripStatus _parseStatus(String raw) {
    switch (raw) {
      case "assigned":
        return TripStatus.assigned;

      case "accepted":
        return TripStatus.accepted;

      case "enroute":
        return TripStatus.enrouteToPickup;

      case "arrived":
        return TripStatus.arrivedAtPickup;

      case "picked":
        return TripStatus.pickedUp;

      case "completed":
        return TripStatus.completed;

      case "cancelled":
        return TripStatus.cancelled;

      default:
        return TripStatus.pending;
    }
  }

  /// -------------------------------------------------
  /// DISPOSE
  /// -------------------------------------------------
  void dispose() {
    _taskSub?.cancel();
    _workerSub?.cancel();

    _taskSub = null;
    _workerSub = null;

    _latestState = null;
    _listeningWorkerId = null;
  }
}