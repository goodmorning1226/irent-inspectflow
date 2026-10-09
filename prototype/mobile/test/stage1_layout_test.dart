import 'dart:ui';

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
    expect(find.text('還車前，先留下清楚的車況紀錄'), findsOneWidget);
    expect(find.text('進入車況檢查'), findsOneWidget);
  });
}
