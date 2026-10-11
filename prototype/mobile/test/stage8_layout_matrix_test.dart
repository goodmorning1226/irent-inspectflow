import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/app/inspectflow_app.dart';
import 'package:inspectflow_mobile/features/completion_review/completion_review_page.dart';
import 'package:inspectflow_mobile/features/inspection/inspection_overview_page.dart';
import 'package:inspectflow_mobile/features/scan/scan_prototype_page.dart';
import 'package:inspectflow_mobile/theme/app_theme.dart';

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  const portraitSizes = [Size(360, 800), Size(390, 844), Size(430, 932)];
  const landscapeSizes = [Size(800, 360), Size(844, 390), Size(932, 430)];

  for (final size in portraitSizes) {
    testWidgets('entry and overview fit ${size.width}x${size.height}', (
      tester,
    ) async {
      _setSize(tester, size);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const InspectFlowApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('enter-inspection-button')));
      await tester.pumpAndSettle();
      expect(find.byType(InspectionOverviewPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('completion review fits ${size.width}x${size.height}', (
      tester,
    ) async {
      _setSize(tester, size);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const CompletionReviewPage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('左後車門刮痕處理確認'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in landscapeSizes) {
    testWidgets('continuous scan fits ${size.width}x${size.height}', (
      tester,
    ) async {
      _setSize(tester, size);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ScanPrototypePage()),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('scan-back-button')), findsOneWidget);
      expect(find.text('Prototype 模擬結果'), findsOneWidget);
      expect(find.text('全車進度'), findsNothing);
      expect(find.byKey(const Key('quality-lock-progress')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
