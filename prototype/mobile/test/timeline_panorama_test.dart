import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/scan/models/scan_timeline.dart';
import 'package:inspectflow_mobile/features/scan/widgets/timeline_panorama.dart';

void main() {
  testWidgets('panorama interpolates one source image across the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const event = ScanTimelineEvent(
      at: Duration(milliseconds: 3500),
      phase: ScanPhase.aligning,
      prompt: '請向左移動一點',
      quality: 0.24,
      capture: false,
      previewAsset: 'assets/frames/vehicle_front_panorama.png',
      previewPanX: -1,
      previewPanToX: 1,
      previewMotionDelay: Duration(milliseconds: 250),
      previewMotionDuration: Duration(milliseconds: 1000),
      previewWalking: true,
      previewScale: 1,
      previewScaleTo: 1.4,
      previewTranslateToX: -0.2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: TimelinePanorama(
            assetPath: 'assets/frames/vehicle_front_panorama.png',
            event: event,
            position: Duration(milliseconds: 4250),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    final alignment = image.alignment as Alignment;
    final expectedMidpoint = -1 + 2 * Curves.easeInOutSine.transform(0.5);
    expect(alignment.x, closeTo(expectedMidpoint, 0.001));
    final scale = tester.widget<Transform>(
      find.byKey(const Key('panorama-scale')),
    );
    final expectedScale = 1 + 0.4 * Curves.easeInOutSine.transform(0.5);
    expect(scale.transform.storage[0], closeTo(expectedScale, 0.001));
    final viewportMotion = tester.widget<Transform>(
      find.byKey(const Key('panorama-viewport-motion')),
    );
    final expectedTranslateX = -0.2 * Curves.easeInOutSine.transform(0.5) * 844;
    expect(
      viewportMotion.transform.getTranslation().x,
      closeTo(expectedTranslateX, 0.1),
    );
  });
}
