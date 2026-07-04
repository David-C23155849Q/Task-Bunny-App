import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

import '../maps/map_config.dart';
import '../models/route_model.dart';

class TaskBunnyMap extends StatelessWidget {
  final MapController controller;

  final LatLng center;
  final double zoom;

  final List<Marker> markers;

  final RouteModel? route;

  final Function(LatLng)? onTap;

  final bool showMyLocation;

  /// ✅ NEW: map ready callback
  final VoidCallback? onMapReady;

  const TaskBunnyMap({
    super.key,
    required this.controller,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.route,
    this.onTap,
    this.showMyLocation = true,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,

      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,

        /// ✅ THIS FIXES YOUR ISSUE
        onMapReady: () {
          if (onMapReady != null) {
            onMapReady!();
          }
        },

        onTap: (_, point) {
          if (onTap != null) {
            onTap!(point);
          }
        },
      ),

      children: [
        /// OpenStreetMap
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: "com.taskbunny.app",
        ),

        /// Route
        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route!.points,
                strokeWidth: 5,
                color: Colors.blue,
              ),
            ],
          ),

        /// Markers
        MarkerLayer(markers: markers),

        /// Current location
        if (showMyLocation) CurrentLocationLayer(),
      ],
    );
  }
}