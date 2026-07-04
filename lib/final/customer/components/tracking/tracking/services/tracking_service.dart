import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/worker_location.dart';
import '../models/tracking_state.dart';
import '../models/trip_status.dart';

class TrackingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription? _taskSub;
  StreamSubscription? _workerSub;

  /// ---------------- TASK STREAM ----------------
  Stream<TrackingState> listenToTask(String taskId) {
    final controller = StreamController<TrackingState>();

    _taskSub = _db.collection("tasks").doc(taskId).snapshots().listen(
          (doc) async {
        if (!doc.exists) return;

        final data = doc.data()!;

        final workerId = data["assignedWorkerId"];
        final customerId = data["customerId"];
        final statusRaw = data["status"] ?? "pending";

        final status = _parseStatus(statusRaw);

        LatLng? pickup;
        if (data["pickup"] != null) {
          pickup = LatLng(
            (data["pickup"]["lat"] as num).toDouble(),
            (data["pickup"]["lng"] as num).toDouble(),
          );
        }

        final state = TrackingState(
          taskId: taskId,
          workerId: workerId,
          customerId: customerId,
          status: status,
          pickupLocation: pickup,
        );

        controller.add(state);

        /// Auto attach worker stream when assigned
        if (workerId != null) {
          _listenToWorker(workerId, controller, state);
        }
      },
    );

    return controller.stream;
  }

  /// ---------------- WORKER STREAM ----------------
  void _listenToWorker(
      String workerId,
      StreamController<TrackingState> controller,
      TrackingState currentState,
      ) {
    _workerSub?.cancel();

    _workerSub = _db
        .collection("workers")
        .doc(workerId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;

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

      final updatedState = currentState.copyWith(
        workerLocation: WorkerLocation(
          workerId: workerId,
          position: LatLng(lat, lng),
          timestamp: DateTime.now(),
        ),
      );

      controller.add(updatedState);
    });
  }

  /// ---------------- STATUS PARSER ----------------
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

  /// ---------------- DISPOSE ----------------
  void dispose() {
    _taskSub?.cancel();
    _workerSub?.cancel();
  }
}