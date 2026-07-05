import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/tracking_state.dart';
import '../models/trip_route.dart';
import '../models/trip_status.dart';
import '../services/route_service.dart';
import '../services/tracking_service.dart';

class TrackingController extends ChangeNotifier {
  final String taskId;

  TrackingController({
    required this.taskId,
  });

  /// SERVICES
  final TrackingService _trackingService = TrackingService();
  final RouteService _routeService = RouteService();

  /// MAP
  final MapController mapController = MapController();

  /// STREAMS
  StreamSubscription<TrackingState>? _trackingSub;

  /// STATE
  TrackingState? _state;

  TrackingState? get state => _state;

  bool loading = true;
  bool followWorker = true;

  /// ---------------- GETTERS ----------------

  LatLng? get workerLocation =>
      _state?.workerLocation?.position;

  LatLng? get pickupLocation =>
      _state?.pickupLocation;

  LatLng? get customerLocation =>
      _state?.customerLocation;

  TripRoute? get route =>
      _state?.route;

  List<LatLng> get polyline =>
      route?.points ?? [];

  double get distanceKm =>
      _state?.distanceKm ?? 0;

  String get eta =>
      _state?.eta ?? "--";

  String get taskStatus =>
      _state?.status.label ?? "Loading";

  TripStatus get status =>
      _state?.status ?? TripStatus.assigned;

  bool get hasRoute =>
      route != null;

  /// Optional worker info (requires TrackingState to expose these fields)

  String get workerName =>
      _state?.workerName ?? "Worker";

  String get workerPhoto =>
      _state?.workerPhoto ?? "";

  double get workerRating =>
      _state?.workerRating ?? 0.0;

  /// ---------------- INITIALIZE ----------------

  Future<void> initialize() async {
    loading = true;
    notifyListeners();

    _trackingSub?.cancel();

    _trackingSub = _trackingService
        .listenToTask(taskId)
        .listen((newState) async {
      _state = newState;

      await _updateRouteIfPossible();

      _updateCamera();

      loading = false;

      notifyListeners();
    });
  }

  /// ---------------- ROUTE ----------------

  Future<void> _updateRouteIfPossible() async {
    final worker = workerLocation;
    final pickup = pickupLocation;

    if (worker == null || pickup == null) {
      return;
    }

    final newRoute = await _routeService.getRoute(
      start: worker,
      end: pickup,
    );

    if (newRoute == null) return;

    _state = _state!.copyWith(
      route: newRoute,
      distanceKm: newRoute.distance / 1000,
      eta: "${(newRoute.duration / 60).round()} min",
    );
  }

  /// ---------------- CAMERA ----------------

  void _updateCamera() {}

  void centerOnWorker() {
    final worker = workerLocation;

    if (worker == null) return;

    try {
      mapController.move(worker, 16);
    } catch (_) {}
  }

  void resetOverview() {
    final worker = workerLocation;
    final pickup = pickupLocation;

    if (worker == null || pickup == null) return;

    final center = LatLng(
      (worker.latitude + pickup.latitude) / 2,
      (worker.longitude + pickup.longitude) / 2,
    );

    try {
      mapController.move(center, 13);
    } catch (_) {}
  }

  /// ---------------- USER ACTIONS ----------------

  void toggleFollowWorker() {
    followWorker = !followWorker;
    notifyListeners();
  }

  /// ---------------- DISPOSE ----------------

  @override
  void dispose() {
    _trackingSub?.cancel();
    _trackingService.dispose();
    super.dispose();
  }
}