import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TaskBunnyMarker {

  static Marker pin(LatLng point) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.location_pin,
        color: Colors.red,
        size: 40,
      ),
    );
  }

  static Marker worker(LatLng point) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.person_pin_circle,
        color: Colors.blue,
        size: 40,
      ),
    );
  }

  static Marker customer(LatLng point) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.location_on,
        color: Colors.green,
        size: 40,
      ),
    );
  }

}