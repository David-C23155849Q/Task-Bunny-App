import 'package:latlong2/latlong.dart';

class WorkerLocation {
  final String workerId;
  final LatLng position;
  final DateTime timestamp;

  WorkerLocation({
    required this.workerId,
    required this.position,
    required this.timestamp,
  });

  factory WorkerLocation.fromMap(String workerId, Map data) {
    return WorkerLocation(
      workerId: workerId,
      position: LatLng(
        (data["lat"] as num).toDouble(),
        (data["lng"] as num).toDouble(),
      ),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "lat": position.latitude,
      "lng": position.longitude,
      "timestamp": timestamp.toIso8601String(),
    };
  }
}