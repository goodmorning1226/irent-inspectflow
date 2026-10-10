import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/inspection/inspection_overview_page.dart';
import 'package:inspectflow_mobile/mock/mock_inspection_data.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';
import 'package:inspectflow_mobile/theme/app_theme.dart';

List<InspectionZone> _completedZones() {
  return MockInspectionData.currentSession.zones.map((zone) {
    return switch (zone.type) {
      InspectionZoneType.leftSide => zone.copyWith(
        status: ZoneStatus.completed,
        completedAt: '剛剛完成',
        qualitySummary: '位置、清晰度與曝光均符合標準',
      ),
      InspectionZoneType.rearSeat => zone.copyWith(
        status: ZoneStatus.completed,
        completedAt: '剛剛完成',
        qualitySummary: '已記錄後座污漬，等待後續處理',
      ),
      _ => zone,
    };
  }).toList();
}

Future<void> _advanceUpload(WidgetTester tester, {int steps = 8}) async {
  for (var index = 0; index < steps; index++) {
    await tester.pump(const Duration(milliseconds: 320));
  }
}

void main() {
  testWidgets('summary, retry, completion and reset form a repeatable flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: '/inspection',
        routes: {
          '/inspection': (_) =>
              InspectionOverviewPage(initialZones: _completedZones()),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6 / 6 已完成'), findsOneWidget);
    await tester.tap(find.text('查看六區檢查摘要'));
    await tester.pumpAndSettle();
    expect(find.text('六個區域均已留下可判讀影像'), findsOneWidget);
    expect(find.textContaining('等待後續處理'), findsWidgets);

    await tester.tap(find.text('確認並上傳車況紀錄'));
    await tester.pump();
    await _advanceUpload(tester, steps: 3);
    expect(find.text('重試未完成項目'), findsOneWidget);
    expect(find.text('需要重試'), findsOneWidget);

    await tester.tap(find.text('重試未完成項目'));
    await _advanceUpload(tester);
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();
    expect(find.text('車況影像已完成記錄'), findsOneWidget);
    expect(find.text('1 項，將由系統處理'), findsOneWidget);

    await tester.tap(find.text('重設 Prototype，再次展示'));
    await tester.pumpAndSettle();
    expect(find.text('4 / 6 已完成'), findsOneWidget);
    expect(find.text('選擇要確認的區域'), findsOneWidget);
  });
}
