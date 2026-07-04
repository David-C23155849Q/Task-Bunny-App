import 'package:latlong2/latlong.dart';

class TripRoute {
  final List<LatLng> points;
  final double distance; // meters
  final double duration; // seconds

  TripRoute({
    required this.points,
    required this.distance,
    required this.duration,
  });
}