import '../models/inspection_session.dart';
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
  );
}
