import 'rental_order.dart';
import 'vehicle.dart';

enum InspectionType { pickup, returnVehicle, completionReview }

class InspectionSession {
  const InspectionSession({
    required this.id,
    required this.type,
    required this.vehicle,
    required this.order,
    required this.isPrototype,
  });

  final String id;
  final InspectionType type;
  final Vehicle vehicle;
  final RentalOrder order;
  final bool isPrototype;
}
