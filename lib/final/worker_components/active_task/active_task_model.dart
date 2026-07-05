import 'package:latlong2/latlong.dart';

class ActiveTaskModel {
  final String taskId;
  final String customerId;
  final String workerId;

  final String description;
  final String category;
  final String status;

  final double acceptedPrice;

  final LatLng pickupLocation;
  final String pickupAddress;

  final String customerName;
  final String customerPhone;

  final DateTime? assignedAt;

  const ActiveTaskModel({
    required this.taskId,
    required this.customerId,
    required this.workerId,
    required this.description,
    required this.category,
    required this.status,
    required this.acceptedPrice,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.customerName,
    required this.customerPhone,
    required this.assignedAt,
  });

  factory ActiveTaskModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      Map<String, dynamic>? customer,
      ) {
    final pickup = (data["pickup"] as Map<String, dynamic>? ?? {});

    return ActiveTaskModel(
      taskId: id,

      customerId: data["customerId"] ?? "",

      workerId: data["assignedWorkerId"] ?? "",

      description: data["description"] ?? "",

      category: data["category"] ?? "",

      status: data["status"] ?? "assigned",

      acceptedPrice:
      (data["acceptedPrice"] as num?)?.toDouble() ??
          (data["price"] as num?)?.toDouble() ??
          0,

      pickupLocation: LatLng(
        (pickup["lat"] as num?)?.toDouble() ?? 0,
        (pickup["lng"] as num?)?.toDouble() ?? 0,
      ),

      pickupAddress: pickup["address"] ?? "",

      customerName: customer?["name"] ?? "Customer",

      customerPhone: customer?["phone"] ?? "",

      assignedAt: data["assignedAt"] == null
          ? null
          : (data["assignedAt"]).toDate(),
    );
  }

  bool get isAssigned => status == "assigned";

  bool get isHeading => status == "heading_to_customer";

  bool get isArrived => status == "arrived";

  bool get isInProgress => status == "in_progress";

  bool get isCompleted => status == "completed";
}