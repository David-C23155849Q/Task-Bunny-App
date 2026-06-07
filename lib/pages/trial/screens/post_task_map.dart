import 'dart:convert';
import 'package:errand_app/pages/trial/screens/task_review_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class TaskLocationPage extends StatefulWidget {
  final Map<String, dynamic> taskData;

  const TaskLocationPage({Key? key, required this.taskData}) : super(key: key);

  @override
  _TaskLocationPageState createState() => _TaskLocationPageState();
}

class _TaskLocationPageState extends State<TaskLocationPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _loading = false;

  // New bool to track broadcast choice
  bool _broadcastToWorkers = true;

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _updateLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateLocation(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _loading = true;
    });

    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? '';
        final address =
            "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";

        _cityController.text = city;
        _addressController.text = address;
      } else {
        _cityController.clear();
        _addressController.clear();
      }

      await _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retrieve address')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> sendNotificationToWorker(
      String token,
      String title,
      String body,
      String taskId,
      String address,
      Map<String, dynamic> taskData,
      ) async {
    const String serverKey = ''; // 🔁 Replace this with your FCM server key

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": title,
            "body": body,
            "sound": "default",
          },
          "data": {
            "taskId": taskId,
            "title": taskData['title'],
            "description": taskData['description'],
            "budget": taskData['budget'].toString(),
            "category": taskData['category'],
            "address": address,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent');
      } else {
        print('❌ Notification failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending FCM: $e');
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (_selectedLocation == null ||
        _cityController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid location')),
      );
      return;
    }

    final db = FirebaseDatabase.instance;
    final clientUid = FirebaseAuth.instance.currentUser?.uid;
    if (clientUid == null) return;

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final city = _cityController.text.trim();
    final taskCategory = widget.taskData['category'];

    final finalTask = {
      ...widget.taskData,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'city': city,
      'address': _addressController.text.trim(),
      'status': 'open',
      'timestamp': ServerValue.timestamp,
      'taskId': taskId,
      'broadcast': _broadcastToWorkers, // Save choice here
    };

    try {
      // Save task under client
      await db.ref('users/$clientUid/tasks/$taskId').set(finalTask);

      if (_broadcastToWorkers) {
        // Broadcast only if chosen
        final workersSnapshot = await db.ref('workers').get();
        if (workersSnapshot.exists) {
          final workers = Map<String, dynamic>.from(workersSnapshot.value as Map);

          for (final entry in workers.entries) {
            final workerId = entry.key;
            final workerData = Map<String, dynamic>.from(entry.value);
            final List workerCategories = workerData['categories'] ?? [];
            final String workerCity = (workerData['city'] ?? '').toString().toLowerCase();
            final token = workerData['fcmToken'];

            if (workerCategories.contains(taskCategory) &&
                workerCity == city.toLowerCase()) {
              // Save to worker
              await db.ref('workers/$workerId/requests/$taskId').set(finalTask);

              // Try sending notification
              if (token != null && token.toString().isNotEmpty) {
                await sendNotificationToWorker(
                  token,
                  "New $taskCategory task in $city",
                  "Tap to send an offer.",
                  taskId,
                  _addressController.text.trim(),
                  finalTask,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error submitting task: $e');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TaskReviewPage(taskData: finalTask),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Task Location')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-17.8292, 31.0522), // Harare default
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (pos) => _updateLocation(pos),
                  markers: _selectedLocation != null
                      ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                    )
                  }
                      : {},
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 10,
                  right: 10,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _getCurrentLocation,
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Use GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(  // <-- Wrap here
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // make Column take only needed height
                  children: [
                    TextFormField(
                      controller: _cityController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      readOnly: true,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text("Broadcast task to matching workers?"),
                      value: _broadcastToWorkers,
                      onChanged: (val) {
                        if (val != null) setState(() => _broadcastToWorkers = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _confirmAndSubmit,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
