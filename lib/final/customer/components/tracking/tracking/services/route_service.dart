import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/trip_route.dart';

class RouteService {
  Future<TripRoute?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url =
        "http://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};"
        "${end.longitude},${end.latitude}"
        "?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    final route = data["routes"][0];

    final coords = route["geometry"]["coordinates"] as List;

    final points = coords.map((c) {
      return LatLng(c[1], c[0]);
    }).toList();

    return TripRoute(
      points: points,
      distance: route["distance"].toDouble(),
      duration: route["duration"].toDouble(),
    );
  }
}