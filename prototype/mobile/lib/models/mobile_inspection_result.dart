import 'finding.dart';
import 'inspection_session.dart';
import 'inspection_zone.dart';

class MobileInspectionResult {
  const MobileInspectionResult({
    required this.session,
    required this.inspectionType,
    required this.zones,
    required this.findings,
  });

  final InspectionSession session;
  final InspectionType inspectionType;
  final List<InspectionZone> zones;
  final List<Finding> findings;

  Map<String, Object?> toJson() => {
    'schemaVersion': 'prototype-1.0',
    'generatedAt': '2026-10-10T18:12:00+08:00',
    'session': {
      'id': session.id,
      'type': inspectionType.name,
      'isPrototype': session.isPrototype,
    },
    'vehicle': {
      'plateNumber': session.vehicle.plateNumber,
      'modelName': session.vehicle.modelName,
      'colorName': session.vehicle.colorName,
    },
    'order': {
      'id': session.order.id,
      'returnLocation': session.order.returnLocation,
      'returnTimeLabel': session.order.returnTimeLabel,
    },
    'zoneCaptures': zones.map(_zoneToJson).toList(growable: false),
    'findings': findings.map(_findingToJson).toList(growable: false),
  };

  Map<String, Object?> _zoneToJson(InspectionZone zone) => {
    'zone': zone.type.name,
    'status': zone.status.name,
    'completedAt': zone.completedAt,
    'qualitySummary': zone.qualitySummary,
    'sourceImages': _sourceImages(zone),
    'isPrototype': true,
  };

  Map<String, Object?> _findingToJson(Finding finding) => {
    'id': finding.id,
    'location': finding.location,
    'type': finding.type.name,
    'severity': finding.severity.name,
    'possiblyNew': finding.possiblyNew,
    'confidence': finding.confidence,
    'sourceImages': finding.sourceImages,
    'isPrototype': finding.isPrototype,
  };

  List<String> _sourceImages(InspectionZone zone) => switch (zone.type) {
    InspectionZoneType.leftSide
        when zone.qualitySummary?.contains('補充影像') ?? false =>
      const [
        'assets/frames/exterior_damage_wide.png',
        'assets/frames/exterior_damage_detail_center.png',
        'assets/frames/exterior_damage_detail_left.png',
        'assets/frames/exterior_damage_detail_right.png',
      ],
    InspectionZoneType.leftSide => const [
      'assets/frames/exterior_clean_best.png',
    ],
    InspectionZoneType.rearSeat => const [
      'assets/frames/interior_dirty_best.png',
    ],
    InspectionZoneType.front => const ['mock://fixed/front.jpg'],
    InspectionZoneType.rear => const ['mock://fixed/rear.jpg'],
    InspectionZoneType.rightSide => const ['mock://fixed/right-side.jpg'],
    InspectionZoneType.frontSeat => const ['mock://fixed/front-seat.jpg'],
  };
}

abstract final class MockInspectionOutput {
  static MobileInspectionResult build({
    required InspectionSession session,
    required InspectionType inspectionType,
    required List<InspectionZone> zones,
  }) {
    final findings = <Finding>[];
    final leftSide = zones.where(
      (zone) => zone.type == InspectionZoneType.leftSide,
    );
    if (leftSide.isNotEmpty &&
        (leftSide.first.qualitySummary?.contains('補充影像') ?? false)) {
      findings.add(MockFindings.leftRearDoorScratch);
    }
    final rearSeat = zones.where(
      (zone) => zone.type == InspectionZoneType.rearSeat,
    );
    if (rearSeat.isNotEmpty &&
        rearSeat.first.status == ZoneStatus.completed &&
        (rearSeat.first.qualitySummary?.contains('污漬') ?? false)) {
      findings.add(MockFindings.rearSeatDrinkStain);
    }
    return MobileInspectionResult(
      session: session,
      inspectionType: inspectionType,
      zones: List.unmodifiable(zones),
      findings: List.unmodifiable(findings),
    );
  }
}
