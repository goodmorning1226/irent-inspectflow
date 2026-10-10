import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/app/inspectflow_app.dart';

void main() {
  testWidgets('app starts and opens the six-zone overview', (tester) async {
    await tester.pumpWidget(const InspectFlowApp());

    expect(find.text('確認還車車況'), findsOneWidget);
    expect(find.text('ABC-1234'), findsOneWidget);
    expect(find.text('Prototype 模擬結果'), findsOneWidget);
    expect(find.byKey(const Key('enter-inspection-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('enter-inspection-button')));
    await tester.pumpAndSettle();

    expect(find.text('選擇要確認的區域'), findsOneWidget);
    expect(find.byKey(const Key('zone-front')), findsOneWidget);
    expect(find.byKey(const Key('zone-leftSide')), findsOneWidget);
    expect(find.byKey(const Key('zone-rear')), findsOneWidget);
    expect(find.byKey(const Key('zone-rightSide')), findsOneWidget);
    expect(find.byKey(const Key('zone-frontSeat')), findsOneWidget);
    expect(find.byKey(const Key('zone-rearSeat')), findsOneWidget);
  });
}
