import 'package:latlong2/latlong.dart';

class PlaceModel {
  final String name;
  final String address;
  final LatLng location;

  const PlaceModel({
    required this.name,
    required this.address,
    required this.location,
  });
}