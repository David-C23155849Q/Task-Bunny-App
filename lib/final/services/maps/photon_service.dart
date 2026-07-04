import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';
import 'map_config.dart';

class PhotonService {
  static final Dio _dio = Dio();

  static Future<List<PlaceModel>> search(
      String query,
      ) async {

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        "${MapConfig.photon}/api",
        queryParameters: {
          "q": query,
          "limit": 8,
        },
      );

      final List features =
      response.data["features"];

      return features.map((feature) {

        final coordinates =
        feature["geometry"]["coordinates"];

        final properties =
        feature["properties"];

        return PlaceModel(
          name: properties["name"] ?? "",
          address:
          properties["city"] ??
              properties["country"] ??
              "",

          location: LatLng(
            coordinates[1],
            coordinates[0],
          ),
        );

      }).toList();

    } catch (e) {
      print(e);
      return [];
    }
  }
}