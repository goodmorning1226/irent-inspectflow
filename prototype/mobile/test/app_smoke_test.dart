import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/app/inspectflow_app.dart';
import 'package:inspectflow_mobile/features/scan/scan_prototype_page.dart';

void main() {
  testWidgets('entry opens the continuous scan directly', (tester) async {
    await tester.pumpWidget(const InspectFlowApp());

    expect(find.text('掃描'), findsOneWidget);
    expect(find.text('檢查車輛狀況'), findsOneWidget);
    expect(find.text('ABC-1234'), findsOneWidget);
    expect(find.text('0 / 6 已完成'), findsOneWidget);
    expect(find.byKey(const Key('entry-vehicle-card')), findsOneWidget);
    expect(find.byKey(const Key('entry-coverage-card')), findsOneWidget);
    expect(find.byKey(const Key('vehicle-coverage-map')), findsOneWidget);
    expect(find.byKey(const Key('enter-inspection-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('enter-inspection-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ScanPrototypePage), findsOneWidget);
    expect(find.text('開始全車掃描'), findsNothing);
    expect(find.byKey(const Key('scan-back-button')), findsOneWidget);
  });
}
