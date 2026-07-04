import 'package:latlong2/latlong.dart';

class TaskModel {
  final String id;
  final String description;
  final String category;
  final String city;
  final String customerId;
  final String status;
  final double price;

  final LatLng pickupLocation;
  final String pickupAddress;

  TaskModel({
    required this.id,
    required this.description,
    required this.category,
    required this.city,
    required this.customerId,
    required this.status,
    required this.price,
    required this.pickupLocation,
    required this.pickupAddress,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    final pickup = (data['pickup'] as Map<String, dynamic>?) ?? {};

    return TaskModel(
      id: id,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      city: pickup['city'] ?? '',
      customerId: data['customerId'] ?? '',
      status: data['status'] ?? 'open',
      price: double.tryParse(data['price'].toString()) ?? 0,

      pickupLocation: LatLng(
        (pickup['lat'] as num?)?.toDouble() ?? 0.0,
        (pickup['lng'] as num?)?.toDouble() ?? 0.0,
      ),

      pickupAddress: pickup['address'] ?? '',
    );
  }
}