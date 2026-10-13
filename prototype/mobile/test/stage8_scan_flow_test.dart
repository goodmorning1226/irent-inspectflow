import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/scan/damage_detail_flow.dart';
import 'package:inspectflow_mobile/features/scan/scan_prototype_page.dart';
import 'package:inspectflow_mobile/mock/mock_inspection_data.dart';
import 'package:inspectflow_mobile/models/finding.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';
import 'package:inspectflow_mobile/theme/app_theme.dart';
import 'package:inspectflow_mobile/widgets/scan_scaffold.dart';

void _setLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(844, 390);
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('damage evidence flow captures three views and completes', (
    tester,
  ) async {
    _setLandscape(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ScanScaffold(
          title: '左側補掃',
          body: DamageDetailFlow(
            finding: MockFindings.leftRearDoorScratch,
            onBackToWide: () {},
            onComplete: () => completed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['中央視角', '左側視角', '右側視角']) {
      expect(find.text(label), findsWidgets);
      await tester.tap(find.text('擷取此角度'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('補充影像已完成'), findsOneWidget);
    expect(find.text('已取得補充證據'), findsOneWidget);

    await tester.tap(find.text('完成左側檢查'));
    expect(completed, isTrue);
  });

  testWidgets('hidden controller exposes repeatable continuous scan controls', (
    tester,
  ) async {
    _setLandscape(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final leftZone = MockInspectionData.currentSession.zones.firstWhere(
      (zone) => zone.type == InspectionZoneType.leftSide,
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ScanPrototypePage(zone: leftZone),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.longPress(
      find.byKey(const Key('scan-back-long-press-target')),
    );
    await tester.pumpAndSettle();

    expect(find.text('全車掃描 Demo 控制器'), findsOneWidget);
    expect(find.text('重播完整流程'), findsOneWidget);
    expect(find.text('下一事件'), findsOneWidget);
    expect(find.text('重設'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
