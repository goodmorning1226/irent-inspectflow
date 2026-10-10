import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/mock/mock_inspection_data.dart';
import 'package:inspectflow_mobile/models/inspection_session.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';
import 'package:inspectflow_mobile/models/mobile_inspection_result.dart';

void main() {
  test('mobile result contains stable session, captures and findings', () {
    final zones = MockInspectionData.currentSession.zones
        .map(
          (zone) => zone.type == InspectionZoneType.rearSeat
              ? zone.copyWith(
                  status: ZoneStatus.completed,
                  completedAt: '剛剛完成',
                  qualitySummary: '已記錄後座污漬，等待後續處理',
                )
              : zone,
        )
        .toList();
    final result = MockInspectionOutput.build(
      session: MockInspectionData.currentSession,
      inspectionType: InspectionType.returnVehicle,
      zones: zones,
    ).toJson();

    expect(result['schemaVersion'], 'prototype-1.0');
    expect((result['session']! as Map<String, Object?>)['isPrototype'], isTrue);
    expect((result['zoneCaptures']! as List<Object?>), hasLength(6));
    final findings = result['findings']! as List<Object?>;
    expect(findings, hasLength(1));
    expect((findings.first! as Map<String, Object?>)['type'], 'stain');
  });
}
