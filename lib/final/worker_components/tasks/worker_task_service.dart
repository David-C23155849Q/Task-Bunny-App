import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand_app/final/worker_components/tasks/task_model.dart';
import 'package:latlong2/latlong.dart';

class WorkerTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TaskModel>> getTasksForWorker({
    required List<String> categories,
    required LatLng workerLocation,
    double radiusKm = 100,
  }) {
    print("=================================");
    print("STARTING TASK QUERY");
    print("Worker Location:");
    print("Lat: ${workerLocation.latitude}");
    print("Lng: ${workerLocation.longitude}");
    print("Categories: $categories");
    print("Radius: $radiusKm km");
    print("=================================");

    return _firestore
        .collection("tasks")
        .where("status", isEqualTo: "open")
        .snapshots()
        .map((snapshot) {
      print("Firestore returned ${snapshot.docs.length} open tasks");

      final tasks = snapshot.docs
          .map((doc) {
        final task = TaskModel.fromMap(doc.id, doc.data());

        print("--------------------------------");
        print("Task: ${task.description}");
        print("Category: ${task.category}");
        print("City: ${task.city}");
        print("Latitude: ${task.pickupLocation.latitude}");
        print("Longitude: ${task.pickupLocation.longitude}");

        return task;
      })
          .where((task) {
        final workerCategories =
        categories.map((e) => e.toLowerCase()).toList();

        if (!workerCategories.contains(task.category.toLowerCase())) {
          print("Rejected (category)");
          return false;
        }

        final distance = _distanceKm(
          workerLocation.latitude,
          workerLocation.longitude,
          task.pickupLocation.latitude,
          task.pickupLocation.longitude,
        );

        print("Distance: ${distance.toStringAsFixed(2)} km");

        if (distance > radiusKm) {
          print("Rejected (too far)");
          return false;
        }

        print("Accepted");

        return true;
      })
          .toList();

      print("==============================");
      print("TASKS RECEIVED: ${tasks.length}");
      print("==============================");

      return tasks;
    });
  }

  double _distanceKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadius = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degToRad(lat1)) *
                cos(_degToRad(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double degrees) {
    return degrees * pi / 180.0;
  }
}