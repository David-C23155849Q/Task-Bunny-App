import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';



import '../services/maps/location_service.dart';
import '../services/maps/nominatim_service.dart';
import '../services/widgets/taskbunny_map.dart';
import '../services/widgets/taskbunny_marker.dart';
import 'components/customer_bids_screen.dart';
import 'components/customer_drawer.dart';
import 'components/task_input_panel.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState
    extends State<CustomerHomeScreen> {

final GlobalKey<ScaffoldState> _scaffoldKey =
GlobalKey<ScaffoldState>();

final MapController _mapController =
MapController();

LatLng? _selectedLatLng;

String? _pickupAddress;

bool _isOffline = false;

String? _activeTaskId;
bool _hasOpenTask = false;

late StreamSubscription<List<ConnectivityResult>>
_connectivitySub;

@override
void initState() {
super.initState();

_startConnectivityListener();

WidgetsBinding.instance.addPostFrameCallback((_) {
_getCurrentLocation();
_checkPendingTask();
});
}

@override
void dispose() {
_connectivitySub.cancel();
super.dispose();
}

/// Listen for internet connectivity
void _startConnectivityListener() {

_connectivitySub = Connectivity()
.onConnectivityChanged
.listen((results) {

final connected =
results.any(
(e) => e != ConnectivityResult.none,
);

if (!mounted) return;

setState(() {
_isOffline = !connected;
});

});

}

/// Get user's current location
Future<void> _getCurrentLocation() async {

try {

final location =
await LocationService.getCurrentLocation();

await _updatePickupLocation(location);

_mapController.move(
location,
15,
);

} catch (e) {

debugPrint(
"Location Error: $e",
);

}

}

/// Reverse geocode and update pickup location
Future<void> _updatePickupLocation(
    LatLng latLng,
    ) async {
  try {
    final address =
    await NominatimService.reverseGeocode(
      latLng.latitude,
      latLng.longitude,
    );

    if (!mounted) return;

    setState(() {
      _selectedLatLng = latLng;
      _pickupAddress = address;
    });
  } catch (e) {
    debugPrint("Reverse Geocode Error: $e");
  }
}


/// bid panel opens if user has a pending task

Future<void> _checkPendingTask() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final query = await FirebaseFirestore.instance
      .collection("tasks")
      .where("customerId", isEqualTo: uid)
      .where("status", isEqualTo: "open")
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    setState(() {
      _activeTaskId = query.docs.first.id;
      _hasOpenTask = true;
    });
  }
}

/// User tapped on the map
void _onMapTap(LatLng point) {
  _updatePickupLocation(point);
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    drawer: const CustomDrawer(),
    body: Stack(
      children: [

        /// Loading
        if (_selectedLatLng == null)
          const Center(
            child: CircularProgressIndicator(),
          )
        else

        /// TaskBunny Map
          TaskBunnyMap(
            controller: _mapController,
            center: _selectedLatLng!,
            zoom: 15,
            onTap: _onMapTap,
            markers: [
              TaskBunnyMarker.pin(
                _selectedLatLng!,
              ),
            ],
          ),

        /// Offline banner
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent,
              padding: const EdgeInsets.all(12),
              child: const SafeArea(
                child: Center(
                  child: Text(
                    "No internet connection",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

        /// Drawer button
        Positioned(
          top: 48,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
        ),

        /// My Location button
        Positioned(
          top: 48,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
            ),
          ),
        ),

        /// Bottom Task Panel or Customer bids panel deednign on task state
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _hasOpenTask && _activeTaskId != null
              ? CustomerBidsPanel(taskId: _activeTaskId!)
              : TaskInputPanel(
            selectedLatLng: _selectedLatLng,
            pickupAddress: _pickupAddress,
          ),
        ),
      ],
    ),
  );
}
}