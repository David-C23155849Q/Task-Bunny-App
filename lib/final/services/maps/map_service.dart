import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  /// Move to a new location while keeping the current zoom.
  static void move(
      MapController controller,
      LatLng point,
      double currentZoom,
      ) {
    controller.move(point, currentZoom);
  }

  /// Change the zoom while keeping the current center.
  static void zoom(
      MapController controller,
      LatLng currentCenter,
      double zoom,
      ) {
    controller.move(currentCenter, zoom);
  }
}