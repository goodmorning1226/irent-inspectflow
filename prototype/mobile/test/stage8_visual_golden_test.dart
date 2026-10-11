import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/app/inspectflow_app.dart';
import 'package:inspectflow_mobile/features/completion_review/completion_review_page.dart';
import 'package:inspectflow_mobile/features/scan/controllers/full_vehicle_scan_controller.dart';
import 'package:inspectflow_mobile/features/scan/models/scan_timeline.dart';
import 'package:inspectflow_mobile/features/scan/scan_prototype_page.dart';
import 'package:inspectflow_mobile/features/scan/widgets/full_vehicle_scan_hud.dart';
import 'package:inspectflow_mobile/mock/mock_inspection_data.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';
import 'package:inspectflow_mobile/theme/app_theme.dart';
import 'package:inspectflow_mobile/widgets/scan_scaffold.dart';

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('portrait entry and overview visual references', (tester) async {
    _setSize(tester, const Size(390, 844));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InspectFlowApp());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage8_entry_390x844.png'),
    );

    await tester.tap(find.byKey(const Key('enter-inspection-button')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage8_overview_390x844.png'),
    );
  });

  testWidgets('completion review portrait visual reference', (tester) async {
    _setSize(tester, const Size(390, 844));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const CompletionReviewPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage8_completion_review_390x844.png'),
    );
  });

  testWidgets('landscape continuous scan visual reference', (tester) async {
    _setSize(tester, const Size(844, 390));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const ScanPrototypePage(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage6_continuous_scan_844x390.png'),
    );
  });

  testWidgets('landscape movement cue visual reference', (tester) async {
    _setSize(tester, const Size(844, 390));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(controller.dispose);
    controller.completeZone(zone: InspectionZoneType.rightSide);
    controller.showMoveGuidance();

    const event = ScanTimelineEvent(
      at: Duration(milliseconds: 2600),
      phase: ScanPhase.moving,
      prompt: '請沿車身向前移動至車頭',
      quality: 0,
      capture: false,
      zone: InspectionZoneType.front,
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ScanScaffold(
          title: '全車連續掃描',
          body: FullVehicleScanHud(
            session: controller,
            event: event,
            isInterior: false,
            video: Image.asset(
              'assets/frames/vehicle_front.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byIcon(Icons.directions_walk_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage6_movement_cue_844x390.png'),
    );
  });

  testWidgets('landscape damage evidence visual reference', (tester) async {
    _setSize(tester, const Size(844, 390));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(controller.dispose);
    controller.completeZone(zone: InspectionZoneType.rightSide);
    controller.completeZone(zone: InspectionZoneType.front);
    controller.beginDamageDetail(InspectionZoneType.leftSide);

    const event = ScanTimelineEvent(
      at: Duration(milliseconds: 9800),
      phase: ScanPhase.evidenceCapturing,
      prompt: '將刮痕置於畫面中央',
      quality: 1,
      capture: true,
      zone: InspectionZoneType.leftSide,
      evidenceView: EvidenceView.center,
      evidenceStep: 1,
      evidenceTotal: 3,
      box: NormalizedScanBox(left: 0.34, top: 0.28, width: 0.34, height: 0.42),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ScanScaffold(
          title: '全車連續掃描',
          body: FullVehicleScanHud(
            session: controller,
            event: event,
            isInterior: false,
            video: Image.asset(
              'assets/frames/exterior_damage_detail_center.png',
              fit: BoxFit.cover,
            ),
            anomalyZones: const {InspectionZoneType.leftSide},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage6_damage_evidence_844x390.png'),
    );
  });

  testWidgets('landscape completed scan visual reference', (tester) async {
    _setSize(tester, const Size(844, 390));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(controller.dispose);
    for (final zone in InspectionZoneType.values) {
      controller.completeZone(
        zone: zone,
        kind: zone == InspectionZoneType.leftSide
            ? ZoneCaptureKind.damageEvidence
            : zone == InspectionZoneType.rearSeat
            ? ZoneCaptureKind.interiorEvidence
            : ZoneCaptureKind.normal,
      );
    }

    const event = ScanTimelineEvent(
      at: Duration(milliseconds: 22800),
      phase: ScanPhase.completed,
      prompt: '保持手機穩定',
      quality: 1,
      capture: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ScanScaffold(
          title: '全車連續掃描',
          body: FullVehicleScanHud(
            session: controller,
            event: event,
            isInterior: true,
            video: Image.asset(
              'assets/frames/interior_dirty_best.png',
              fit: BoxFit.cover,
            ),
            anomalyZones: const {
              InspectionZoneType.leftSide,
              InspectionZoneType.rearSeat,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('完成'), findsNothing);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/stage6_completed_scan_844x390.png'),
    );
  });
}
