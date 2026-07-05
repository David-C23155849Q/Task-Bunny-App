import 'package:latlong2/latlong.dart';

import 'trip_route.dart';
import 'trip_status.dart';
import 'worker_location.dart';

class TrackingState {
  final String taskId;

  final String? workerId;
  final String? customerId;

  /// Worker details
  final String workerName;
  final String workerPhoto;
  final double workerRating;
  final String workerPhone;

  final TripStatus status;

  final WorkerLocation? workerLocation;
  final LatLng? customerLocation;
  final LatLng? pickupLocation;

  final TripRoute? route;

  final double distanceKm;
  final String eta;

  const TrackingState({
    required this.taskId,
    this.workerId,
    this.customerId,

    this.workerName = "Worker",
    this.workerPhoto = "",
    this.workerRating = 0.0,
    this.workerPhone = "",

    this.status = TripStatus.pending,

    this.workerLocation,
    this.customerLocation,
    this.pickupLocation,

    this.route,

    this.distanceKm = 0,
    this.eta = "--",
  });

  TrackingState copyWith({
    String? workerId,
    String? customerId,

    String? workerName,
    String? workerPhoto,
    double? workerRating,
    String? workerPhone,

    TripStatus? status,

    WorkerLocation? workerLocation,
    LatLng? customerLocation,
    LatLng? pickupLocation,

    TripRoute? route,

    double? distanceKm,
    String? eta,
  }) {
    return TrackingState(
      taskId: taskId,

      workerId: workerId ?? this.workerId,
      customerId: customerId ?? this.customerId,

      workerName: workerName ?? this.workerName,
      workerPhoto: workerPhoto ?? this.workerPhoto,
      workerRating: workerRating ?? this.workerRating,
      workerPhone: workerPhone ?? this.workerPhone,

      status: status ?? this.status,

      workerLocation: workerLocation ?? this.workerLocation,
      customerLocation: customerLocation ?? this.customerLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,

      route: route ?? this.route,

      distanceKm: distanceKm ?? this.distanceKm,
      eta: eta ?? this.eta,
    );
  }
}