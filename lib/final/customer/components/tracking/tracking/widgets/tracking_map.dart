import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/tracking_controller.dart';

class TrackingMap extends StatefulWidget {
  final TrackingController controller;

  const TrackingMap({
    super.key,
    required this.controller,
  });

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  bool _centeredOnce = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final worker = widget.controller.workerLocation;

    if (worker == null) {
      setState(() {});
      return;
    }

    if (worker.latitude == 0 && worker.longitude == 0) {
      setState(() {});
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        if (!_centeredOnce) {
          _centeredOnce = true;

          widget.controller.mapController.move(
            worker,
            16,
          );
        } else if (widget.controller.followWorker) {
          widget.controller.mapController.move(
            worker,
            16,
            id: "tracking",
          );
        }
      } catch (_) {
        // Map isn't attached yet.
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final worker = controller.workerLocation;
    final pickup = controller.pickupLocation;
    final customer = controller.customerLocation;
    final route = controller.route;

    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: worker ??
            pickup ??
            const LatLng(
              -17.8292,
              31.0522,
            ),
        initialZoom: 16,

        onMapReady: () {
          if (!_centeredOnce && worker != null) {
            _centeredOnce = true;

            controller.mapController.move(worker, 16);
          }
        },

        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            controller.followWorker = false;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.task.bunnyapp",
        ),

        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                strokeWidth: 6,
                color: Colors.blue,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            if (worker != null)
              Marker(
                point: worker,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.green,
                  size: 42,
                ),
              ),

            if (pickup != null)
              Marker(
                point: pickup,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 42,
                ),
              ),

            if (customer != null)
              Marker(
                point: customer,
                width: 55,
                height: 55,
                child: const Icon(
                  Icons.home,
                  color: Colors.orange,
                  size: 36,
                ),
              ),
          ],
        ),

        CurrentLocationLayer(),
      ],
    );
  }
}