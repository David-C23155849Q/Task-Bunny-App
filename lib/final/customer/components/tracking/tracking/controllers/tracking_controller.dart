import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/tracking_state.dart';
import '../models/trip_route.dart';
import '../models/trip_status.dart';
import '../services/tracking_service.dart';
import '../services/route_service.dart';

class TrackingController extends ChangeNotifier {
  final String taskId;

  TrackingController({required this.taskId});

  /// Services
  final TrackingService _trackingService = TrackingService();
  final RouteService _routeService = RouteService();

  /// Map
  final MapController mapController = MapController();

  /// Streams
  StreamSubscription? _trackingSub;

  /// State
  TrackingState? _state;

  TrackingState? get state => _state;

  bool loading = true;
  bool followWorker = true;

  /// Convenience getters
  LatLng? get workerLocation => _state?.workerLocation?.position;
  LatLng? get pickupLocation => _state?.pickupLocation;
  LatLng? get customerLocation => _state?.customerLocation;

  TripRoute? get route => _state?.route;

  double get distanceKm => _state?.distanceKm ?? 0;
  String get eta => _state?.eta ?? "--";
  String get taskStatus => _state?.status.label ?? "Loading";

  /// ---------------- INIT ----------------
  Future<void> initialize() async {
    _trackingSub =
        _trackingService.listenToTask(taskId).listen((newState) async {
          _state = newState;

          await _updateRouteIfPossible();
          _updateCamera();

          loading = false;
          notifyListeners();
        });
  }

  /// ---------------- ROUTE UPDATE ----------------
  Future<void> _updateRouteIfPossible() async {
    final worker = workerLocation;
    final pickup = pickupLocation;

    if (worker == null || pickup == null) return;

    final route = await _routeService.getRoute(
      start: worker,
      end: pickup,
    );

    if (route == null) return;

    _state = _state!.copyWith(
      route: route,
      distanceKm: route.distance / 1000,
      eta: "${(route.duration / 60).round()} min",
    );
  }

  /// ---------------- CAMERA CONTROL ----------------
  void _updateCamera() {
    if (!followWorker) return;

    final worker = workerLocation;
    if (worker == null) return;

    mapController.move(worker, mapController.camera.zoom);
  }

  /// ---------------- USER ACTIONS ----------------
  void toggleFollowWorker() {
    followWorker = !followWorker;
    notifyListeners();
  }

  void centerOnWorker() {
    final worker = workerLocation;
    if (worker == null) return;

    mapController.move(worker, 16);
  }

  void resetOverview() {
    final worker = workerLocation;
    final pickup = pickupLocation;

    if (worker == null || pickup == null) return;

    final lat = (worker.latitude + pickup.latitude) / 2;
    final lng = (worker.longitude + pickup.longitude) / 2;

    mapController.move(LatLng(lat, lng), 13);
  }

  /// ---------------- DISPOSE ----------------
  void dispose() {
    _trackingSub?.cancel();
    _trackingService.dispose();
    super.dispose();
  }
}