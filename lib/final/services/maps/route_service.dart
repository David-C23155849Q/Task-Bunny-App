import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';

class RouteService {
  /// Replace with your OpenRouteService API key
  static const String _apiKey = "YOUR_OPENROUTESERVICE_API_KEY";

  static const String _baseUrl =
      "https://api.openrouteservice.org/v2/directions/driving-car";

  Future<RouteModel?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final uri = Uri.parse(
        "$_baseUrl?api_key=$_apiKey"
            "&start=${start.longitude},${start.latitude}"
            "&end=${end.longitude},${end.latitude}",
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body);

      final features = json["features"];

      if (features == null || features.isEmpty) {
        return null;
      }

      final geometry = features[0]["geometry"];

      final coordinates = geometry["coordinates"] as List;

      final points = coordinates
          .map(
            (e) => LatLng(
          (e[1] as num).toDouble(),
          (e[0] as num).toDouble(),
        ),
      )
          .toList();

      final summary =
      features[0]["properties"]["summary"];

      final distance =
      (summary["distance"] as num).toDouble();

      final duration =
      (summary["duration"] as num).toDouble();

      return RouteModel(
        points: points,
        distance: distance,
        duration: duration,
      );
    } catch (e) {
      print("Route error: $e");
      return null;
    }
  }
}