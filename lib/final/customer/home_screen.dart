import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart';

import 'components/customer_drawer.dart';
import 'components/location_service.dart';
import 'components/task_input_panel.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;

  LatLng? _selectedLatLng;
  String? _pickupAddress;
  bool _isOffline = false;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  /// 🌐 Listen for internet connectivity
  void _startConnectivityListener() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        setState(() => _isOffline = !hasInternet);
      }
    });
  }


  

  /// 📍 Get and update current user location
  Future<void> _getCurrentLocation() async {
    final loc = await LocationService.getLocation();
    await _updatePickupFromLatLng(loc);
    _mapController?.animateCamera(CameraUpdate.newLatLng(loc));
  }

  /// 🏷️ Reverse geocode coordinates into address
  Future<void> _updatePickupFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      final placemark = placemarks.first;
      final address =
          "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}";
      setState(() {
        _selectedLatLng = latLng;
        _pickupAddress = address;
      });
    } catch (e) {
      debugPrint("Failed to get address: $e");
    }
  }

  /// 🗺️ When the user taps the map
  void _onMapTap(LatLng tappedLatLng) {
    _updatePickupFromLatLng(tappedLatLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // 🗺️ Google Map
          _selectedLatLng == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng!,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId("pickup"),
                position: _selectedLatLng!,
              ),
            },
          ),

          // 🔌 No internet banner
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.redAccent,
                child: const SafeArea(
                  child: Center(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

          // ☰ Drawer button
          Positioned(
            top: 48,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),

          // 📍 Use my location button
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

          // 📝 Slide-up task input panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TaskInputPanel(
              selectedLatLng: _selectedLatLng,
              pickupAddress: _pickupAddress,
            ),
          ),
        ],
      ),
    );
  }
}
