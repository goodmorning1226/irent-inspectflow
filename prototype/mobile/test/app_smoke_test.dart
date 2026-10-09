import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/app/inspectflow_app.dart';

void main() {
  testWidgets('app starts and opens the inspection placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const InspectFlowApp());

    expect(find.text('確認還車車況'), findsOneWidget);
    expect(find.text('ABC-1234'), findsOneWidget);
    expect(find.text('Prototype 模擬結果'), findsOneWidget);
    expect(find.byKey(const Key('enter-inspection-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('enter-inspection-button')));
    await tester.pumpAndSettle();

    expect(find.text('車況檢查'), findsOneWidget);
    expect(find.text('準備建立六區車況總覽'), findsOneWidget);
  });
}
