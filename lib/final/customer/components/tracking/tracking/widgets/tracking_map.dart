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
  MapController get _map => widget.controller.mapController;

  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();

    /// listen to controller updates
    widget.controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    final worker = widget.controller.workerLocation;
    final pickup = widget.controller.pickupLocation;

    if (worker == null) return;

    /// 🔥 FIX 1: Prevent ocean bug (0,0 crash)
    if (worker.latitude == 0 && worker.longitude == 0) return;

    /// 🔥 FIX 2: Initial safe center
    if (!_hasCenteredOnce) {
      _hasCenteredOnce = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _map.move(worker, 16);
      });

      return;
    }

    /// 🔥 FIX 3: Follow mode (smooth tracking)
    if (widget.controller.followWorker) {
      _map.move(worker, _map.camera.zoom);
    }

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
            const LatLng(-17.8292, 31.0522), // fallback (Harare safe center)

        initialZoom: 15,

        onPositionChanged: (pos, hasGesture) {
          /// user moved map manually → disable follow
          if (hasGesture) {
            controller.followWorker = false;
          }
        },
      ),
      children: [
        /// BASE MAP
        TileLayer(
          urlTemplate:
          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.task.bunnyapp",
        ),

        /// ROUTE POLYLINE
        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.points,
                strokeWidth: 5,
                color: Colors.blue,
              ),
            ],
          ),

        /// MARKERS
        MarkerLayer(
          markers: [
            /// WORKER
            if (worker != null)
              Marker(
                point: worker,
                width: 55,
                height: 55,
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.green,
                  size: 42,
                ),
              ),

            /// PICKUP
            if (pickup != null)
              Marker(
                point: pickup,
                width: 55,
                height: 55,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 42,
                ),
              ),

            /// CUSTOMER
            if (customer != null)
              Marker(
                point: customer,
                width: 55,
                height: 55,
                child: const Icon(
                  Icons.home,
                  color: Colors.orange,
                  size: 38,
                ),
              ),
          ],
        ),

        /// MY LOCATION DOT (optional system GPS layer)
        CurrentLocationLayer(),
      ],
    );
  }
}