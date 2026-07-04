import 'package:latlong2/latlong.dart';

class RouteModel {
  final List<LatLng> points;
  final double distance; // metres
  final double duration; // seconds

  const RouteModel({
    required this.points,
    required this.distance,
    required this.duration,
  });

  double get distanceKm => distance / 1000;

  double get durationMinutes => duration / 60;
}