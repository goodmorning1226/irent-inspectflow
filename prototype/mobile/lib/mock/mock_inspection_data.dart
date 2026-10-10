import '../models/inspection_session.dart';
import '../models/inspection_zone.dart';
import '../models/rental_order.dart';
import '../models/vehicle.dart';

abstract final class MockInspectionData {
  static const currentSession = InspectionSession(
    id: 'INS-DEMO-001',
    type: InspectionType.returnVehicle,
    isPrototype: true,
    vehicle: Vehicle(
      plateNumber: 'ABC-1234',
      modelName: 'TOYOTA YARIS',
      colorName: '極光銀',
    ),
    order: RentalOrder(
      id: 'RNT-20261010-001',
      returnLocation: '台北市信義區・市府停車場',
      returnTimeLabel: '今日 18:30 前',
    ),
    zones: [
      InspectionZone(
        type: InspectionZoneType.front,
        status: ZoneStatus.notStarted,
      ),
      InspectionZone(
        type: InspectionZoneType.leftSide,
        status: ZoneStatus.notStarted,
      ),
      InspectionZone(
        type: InspectionZoneType.rear,
        status: ZoneStatus.notStarted,
      ),
      InspectionZone(
        type: InspectionZoneType.rightSide,
        status: ZoneStatus.notStarted,
      ),
      InspectionZone(
        type: InspectionZoneType.frontSeat,
        status: ZoneStatus.notStarted,
      ),
      InspectionZone(
        type: InspectionZoneType.rearSeat,
        status: ZoneStatus.notStarted,
      ),
    ],
  );
}
