import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/scan/controllers/full_vehicle_scan_controller.dart';
import 'package:inspectflow_mobile/features/scan/models/scan_timeline.dart';
import 'package:inspectflow_mobile/features/scan/widgets/full_vehicle_scan_hud.dart';
import 'package:inspectflow_mobile/mock/mock_inspection_data.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';
import 'package:inspectflow_mobile/theme/app_colors.dart';

void main() {
  testWidgets('front alignment shows a repeating left adjustment cue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(session.dispose);

    Widget buildHud({required bool satisfied}) {
      return MaterialApp(
        home: Scaffold(
          body: FullVehicleScanHud(
            session: session,
            event: ScanTimelineEvent(
              at: const Duration(milliseconds: 3500),
              phase: ScanPhase.aligning,
              prompt: '請向左移動一點',
              quality: 0.24,
              capture: false,
              zone: InspectionZoneType.front,
              adjustmentDirection: ScanAdjustmentDirection.left,
              adjustmentSatisfied: satisfied,
              box: const NormalizedScanBox(
                left: 0.2,
                top: 0.14,
                width: 0.6,
                height: 0.7,
              ),
            ),
            isInterior: false,
            video: Image.asset(
              'assets/frames/vehicle_front_yaw_right.png',
              key: const Key('test-yaw-preview'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHud(satisfied: false));
    await tester.pump(const Duration(milliseconds: 400));

    final arrow = tester.widget<Icon>(
      find.byKey(const Key('adjustment-arrow')),
    );
    final arrowMotion = tester.widget<Transform>(
      find.byKey(const Key('adjustment-motion')),
    );
    final preview = tester.widget<Transform>(
      find.byKey(const Key('preview-alignment-offset')),
    );
    expect(arrow.color, AppColors.captureCyan);
    expect(arrowMotion.transform.getTranslation().x, lessThan(0));
    expect(preview.transform.getTranslation().x, 0);

    await tester.pumpWidget(buildHud(satisfied: true));
    await tester.pump();
    final correctedPreview = tester.widget<Transform>(
      find.byKey(const Key('preview-alignment-offset')),
    );
    expect(find.byKey(const Key('adjustment-arrow')), findsNothing);
    final scanIcon = tester.widget<Icon>(
      find.byKey(const Key('scan-status-icon')),
    );
    expect(scanIcon.icon, Icons.directions_car_filled_rounded);
    expect(scanIcon.color, AppColors.white.withValues(alpha: 0.38));
    expect(correctedPreview.transform.getTranslation().x, 0);
  });

  testWidgets('damage evidence cue follows the required diagonal direction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(session.dispose);

    Widget buildHud(ScanAdjustmentDirection direction) {
      return MaterialApp(
        home: Scaffold(
          body: FullVehicleScanHud(
            session: session,
            event: ScanTimelineEvent(
              at: const Duration(milliseconds: 10100),
              phase: ScanPhase.evidenceCapturing,
              prompt: direction == ScanAdjustmentDirection.upLeft
                  ? '向左上移動一點'
                  : '向右下移動一點',
              quality: 0.74,
              capture: false,
              zone: InspectionZoneType.leftSide,
              adjustmentDirection: direction,
              evidenceView: direction == ScanAdjustmentDirection.upLeft
                  ? EvidenceView.left
                  : EvidenceView.right,
              evidenceStep: 2,
              evidenceTotal: 3,
              box: const NormalizedScanBox(
                left: 0.34,
                top: 0.28,
                width: 0.34,
                height: 0.42,
              ),
            ),
            isInterior: false,
            video: const ColoredBox(color: Colors.black),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHud(ScanAdjustmentDirection.upLeft));
    await tester.pump(const Duration(milliseconds: 400));
    var arrow = tester.widget<Icon>(find.byKey(const Key('adjustment-arrow')));
    var motion = tester.widget<Transform>(
      find.byKey(const Key('adjustment-motion')),
    );
    expect(arrow.icon, Icons.north_west_rounded);
    expect(motion.transform.getTranslation().x, lessThan(0));
    expect(motion.transform.getTranslation().y, lessThan(0));

    await tester.pumpWidget(buildHud(ScanAdjustmentDirection.downRight));
    await tester.pump(const Duration(milliseconds: 400));
    arrow = tester.widget<Icon>(find.byKey(const Key('adjustment-arrow')));
    motion = tester.widget<Transform>(
      find.byKey(const Key('adjustment-motion')),
    );
    expect(arrow.icon, Icons.south_east_rounded);
    expect(motion.transform.getTranslation().x, greaterThan(0));
    expect(motion.transform.getTranslation().y, greaterThan(0));
  });

  testWidgets('guide frame remains visible while moving from front to left', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FullVehicleScanHud(
            session: session,
            event: const ScanTimelineEvent(
              at: Duration(milliseconds: 6500),
              phase: ScanPhase.moving,
              prompt: '繞過車頭並移動至左側',
              quality: 0,
              capture: false,
              zone: InspectionZoneType.leftSide,
              box: NormalizedScanBox(
                left: 0.2,
                top: 0.14,
                width: 0.6,
                height: 0.7,
              ),
            ),
            isInterior: false,
            video: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('scan-guide-frame')), findsOneWidget);
  });

  testWidgets('forward cue uses a floor-plane arrow and moves toward horizon', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FullVehicleScanHud(
            session: session,
            event: const ScanTimelineEvent(
              at: Duration(milliseconds: 8000),
              phase: ScanPhase.detailRequired,
              prompt: '向前靠近刮痕',
              quality: 0.72,
              capture: false,
              zone: InspectionZoneType.leftSide,
              adjustmentDirection: ScanAdjustmentDirection.forward,
              evidenceView: EvidenceView.center,
              evidenceStep: 1,
              evidenceTotal: 3,
              box: NormalizedScanBox(
                left: 0.34,
                top: 0.28,
                width: 0.34,
                height: 0.42,
              ),
            ),
            isInterior: false,
            video: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('forward-adjustment-arrow')), findsOneWidget);
    expect(find.byKey(const Key('adjustment-arrow')), findsNothing);
    expect(
      tester.getCenter(find.byKey(const Key('forward-adjustment-arrow'))).dy,
      closeTo(195, 2),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final motion = tester.widget<Transform>(
      find.byKey(const Key('adjustment-motion')),
    );
    expect(motion.transform.getTranslation().y, lessThan(0));
  });

  testWidgets('evidence frame returns to blue before capture turns it green', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(session.dispose);

    Widget buildHud({required bool capture}) {
      return MaterialApp(
        home: Scaffold(
          body: FullVehicleScanHud(
            session: session,
            event: ScanTimelineEvent(
              at: const Duration(milliseconds: 11100),
              phase: ScanPhase.evidenceCapturing,
              prompt: '保持手機穩定',
              quality: capture ? 1 : 0.9,
              capture: capture,
              zone: InspectionZoneType.leftSide,
              evidenceView: EvidenceView.left,
              evidenceStep: 2,
              evidenceTotal: 3,
              box: const NormalizedScanBox(
                left: 0.34,
                top: 0.28,
                width: 0.34,
                height: 0.42,
              ),
            ),
            isInterior: false,
            video: const ColoredBox(color: Colors.black),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHud(capture: false));
    var frame = tester.widget<DecoratedBox>(
      find.byKey(const Key('scan-guide-frame')),
    );
    var decoration = frame.decoration as BoxDecoration;
    expect(decoration.border!.top.color, AppColors.captureCyan);

    await tester.pumpWidget(buildHud(capture: true));
    frame = tester.widget<DecoratedBox>(
      find.byKey(const Key('scan-guide-frame')),
    );
    decoration = frame.decoration as BoxDecoration;
    expect(decoration.border!.top.color, AppColors.successGreen);
    final statusIcon = tester.widget<Icon>(
      find.byKey(const Key('scan-status-icon')),
    );
    expect(statusIcon.icon, Icons.check_circle_rounded);
    expect(statusIcon.color, AppColors.successGreen.withValues(alpha: 0.94));
  });

  testWidgets('anomaly box clears before forward zoom while arrow remains', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    addTearDown(session.dispose);

    Widget buildHud({required bool moving}) {
      return MaterialApp(
        home: Scaffold(
          body: FullVehicleScanHud(
            session: session,
            event: ScanTimelineEvent(
              at: Duration(milliseconds: moving ? 8400 : 7800),
              phase: ScanPhase.evidenceCapturing,
              prompt: '請向前靠近刮痕',
              quality: 0.72,
              capture: false,
              zone: InspectionZoneType.leftSide,
              adjustmentDirection: ScanAdjustmentDirection.forward,
              previewScale: 1,
              previewScaleTo: moving ? 1.22 : null,
              anomalyBox: const NormalizedScanBox(
                left: 0.61,
                top: 0.48,
                width: 0.2,
                height: 0.2,
              ),
              box: const NormalizedScanBox(
                left: 0.08,
                top: 0.18,
                width: 0.84,
                height: 0.62,
              ),
            ),
            isInterior: false,
            video: const ColoredBox(color: Colors.black),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHud(moving: false));
    expect(find.byKey(const Key('scan-anomaly-box')), findsOneWidget);
    expect(find.byKey(const Key('forward-adjustment-arrow')), findsOneWidget);

    await tester.pumpWidget(buildHud(moving: true));
    await tester.pump();
    expect(find.byKey(const Key('scan-anomaly-box')), findsNothing);
    expect(find.byKey(const Key('forward-adjustment-arrow')), findsOneWidget);
    final frame = tester.widget<DecoratedBox>(
      find.byKey(const Key('scan-guide-frame')),
    );
    final decoration = frame.decoration as BoxDecoration;
    expect(decoration.border!.top.color, AppColors.captureCyan);
  });
}
