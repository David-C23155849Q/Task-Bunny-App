import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import 'map_config.dart';

class NominatimService {
  static final Dio _dio = Dio(
    BaseOptions(
      headers: {
        "User-Agent": MapConfig.userAgent,
      },
    ),
  );

  /// Address → Coordinates
  static Future<LatLng?> geocode(String address) async {
    try {
      final response = await _dio.get(
        "${MapConfig.nominatim}/search",
        queryParameters: {
          "q": address,
          "format": "jsonv2",
          "limit": 1,
        },
      );

      if ((response.data as List).isEmpty) {
        return null;
      }

      final item = response.data.first;

      return LatLng(
        double.parse(item["lat"]),
        double.parse(item["lon"]),
      );
    } catch (e) {
      print("Geocode Error: $e");
      return null;
    }
  }

  /// Coordinates → Address
  static Future<String> reverseGeocode(
      double latitude,
      double longitude,
      ) async {
    try {
      final response = await _dio.get(
        "${MapConfig.nominatim}/reverse",
        queryParameters: {
          "lat": latitude,
          "lon": longitude,
          "format": "jsonv2",
        },
      );

      return response.data["display_name"] ?? "Unknown location";
    } catch (e) {
      print("Reverse Geocode Error: $e");
      return "Unknown location";
    }
  }
}