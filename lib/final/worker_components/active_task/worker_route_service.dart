import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Result returned from OSRM
class RouteResult {
  final List<LatLng> polyline;
  final double distanceKm;
  final double durationMinutes;

  const RouteResult({
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
  });

  static const empty = RouteResult(
    polyline: [],
    distanceKm: 0,
    durationMinutes: 0,
  );
}

class WorkerRouteService {
  static const _baseUrl =
      "https://router.project-osrm.org/route/v1/driving";

  /// Downloads a real road route from OSRM
  Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final url =
          "$_baseUrl/"
          "${start.longitude},${start.latitude};"
          "${destination.longitude},${destination.latitude}"
          "?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return RouteResult.empty;
      }

      final json = jsonDecode(response.body);

      final routes = json["routes"] as List?;

      if (routes == null || routes.isEmpty) {
        return RouteResult.empty;
      }

      final route = routes.first;

      final geometry = route["geometry"];

      final coordinates =
      geometry["coordinates"] as List<dynamic>;

      final points = coordinates.map((point) {
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();

      return RouteResult(
        polyline: points,
        distanceKm:
        (route["distance"] as num).toDouble() / 1000.0,
        durationMinutes:
        (route["duration"] as num).toDouble() / 60.0,
      );
    } catch (e) {
      return RouteResult.empty;
    }
  }

  /// Straight-line fallback distance
  double calculateDistance(
      LatLng start,
      LatLng end,
      ) {
    const distance = Distance();

    return distance.as(
      LengthUnit.Kilometer,
      start,
      end,
    );
  }

  /// Simple ETA estimate
  double estimateEta({
    required double distanceKm,
    double averageSpeedKmPerHour = 40,
  }) {
    if (distanceKm <= 0) return 0;

    return (distanceKm / averageSpeedKmPerHour) * 60;
  }

  /// Has the worker reached the pickup?
  bool hasArrived({
    required LatLng worker,
    required LatLng pickup,
    double radiusMeters = 30,
  }) {
    const distance = Distance();

    final meters = distance.as(
      LengthUnit.Meter,
      worker,
      pickup,
    );

    return meters <= radiusMeters;
  }
}