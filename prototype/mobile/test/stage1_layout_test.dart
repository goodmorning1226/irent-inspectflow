import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/app/inspectflow_app.dart';

void main() {
  testWidgets('stage 1 entry fits a 390 by 844 viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InspectFlowApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('掃描'), findsOneWidget);
    expect(find.text('檢查車輛狀況'), findsOneWidget);
    expect(find.textContaining('Prototype 模擬流程'), findsNothing);
    expect(find.byKey(const Key('entry-vehicle-image')), findsNothing);
    expect(find.byKey(const Key('entry-vehicle-card')), findsOneWidget);
    expect(find.byKey(const Key('entry-coverage-card')), findsOneWidget);
    expect(find.text('確認還車車況'), findsNothing);
    expect(find.text('掃描車輛狀況'), findsOneWidget);
  });
}
