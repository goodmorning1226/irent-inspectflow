import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/scan/controllers/full_vehicle_scan_controller.dart';
import 'package:inspectflow_mobile/mock/mock_inspection_data.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';

void main() {
  test('full vehicle scan completes six unique zones in one session', () {
    final controller = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(controller.dispose);

    expect(controller.phase, FullVehicleScanPhase.searchingVehicle);
    expect(controller.completedCount, 0);
    expect(controller.suggestedZone, InspectionZoneType.rightSide);
    expect(
      controller.zones.every((zone) => zone.status == ZoneStatus.notStarted),
      isTrue,
    );

    controller.updateDetection(
      vehicleDetected: true,
      zone: InspectionZoneType.rightSide,
    );
    controller.updateQualityLock(0.75);
    expect(controller.phase, FullVehicleScanPhase.qualityLocking);
    expect(controller.lockProgress, 0.75);

    expect(controller.completeZone(), isTrue);
    expect(controller.completedCount, 1);
    expect(controller.suggestedZone, InspectionZoneType.front);
    expect(
      controller.completeZone(zone: InspectionZoneType.rightSide),
      isFalse,
    );
    expect(controller.completedCount, 1);

    const remaining = [
      InspectionZoneType.front,
      InspectionZoneType.leftSide,
      InspectionZoneType.rear,
      InspectionZoneType.frontSeat,
      InspectionZoneType.rearSeat,
    ];
    for (final zone in remaining) {
      controller.updateDetection(vehicleDetected: true, zone: zone);
      controller.updateQualityLock(1);
      if (zone == InspectionZoneType.leftSide) {
        controller.beginDamageDetail(zone);
      }
      expect(
        controller.completeZone(
          kind: zone == InspectionZoneType.leftSide
              ? ZoneCaptureKind.damageEvidence
              : zone == InspectionZoneType.rearSeat
              ? ZoneCaptureKind.interiorEvidence
              : ZoneCaptureKind.normal,
        ),
        isTrue,
      );
    }

    expect(controller.isComplete, isTrue);
    expect(controller.completedCount, 6);
    expect(controller.suggestedZone, isNull);
    expect(controller.phase, FullVehicleScanPhase.completed);
    expect(
      controller.zones.every((zone) => zone.status == ZoneStatus.completed),
      isTrue,
    );
  });
}
