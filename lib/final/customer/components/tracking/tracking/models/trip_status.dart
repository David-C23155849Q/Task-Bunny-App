enum TripStatus {
  pending,
  assigned,
  accepted,
  enrouteToPickup,
  arrivedAtPickup,
  pickedUp,
  enrouteToDropoff,
  completed,
  cancelled,
}

extension TripStatusX on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.pending:
        return "Pending";
      case TripStatus.assigned:
        return "Assigned";
      case TripStatus.accepted:
        return "Accepted";
      case TripStatus.enrouteToPickup:
        return "Going to pickup";
      case TripStatus.arrivedAtPickup:
        return "Arrived at pickup";
      case TripStatus.pickedUp:
        return "Picked up";
      case TripStatus.enrouteToDropoff:
        return "On the way";
      case TripStatus.completed:
        return "Completed";
      case TripStatus.cancelled:
        return "Cancelled";
    }
  }
}