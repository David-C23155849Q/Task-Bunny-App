import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';
import 'map_config.dart';

class ValhallaService {
  static final Dio _dio = Dio();

  static Future<RouteModel?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.post(
        "${MapConfig.valhalla}/route",
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
        data: jsonEncode({
          "locations": [
            {
              "lat": origin.latitude,
              "lon": origin.longitude,
            },
            {
              "lat": destination.latitude,
              "lon": destination.longitude,
            }
          ],
          "costing": "auto",
          "directions_options": {
            "units": "kilometers"
          },
          "shape_format": "geojson",
        }),
      );

      final trip = response.data["trip"];

      final summary = trip["summary"];

      final shape = trip["legs"][0]["shape"];

      List<LatLng> points = [];

      for (final p in shape["coordinates"]) {
        points.add(
          LatLng(
            p[1],
            p[0],
          ),
        );
      }

      return RouteModel(
        points: points,
        distance: summary["length"].toDouble(),
        duration: summary["time"].toDouble(),
      );
    } catch (e) {
      print("Valhalla Error: $e");
      return null;
    }
  }
}