import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/scan/models/scan_timeline.dart';

void main() {
  test('timeline parser returns the event active at a playback position', () {
    final script = ScanTimelineScript.fromJson({
      'scenarioId': 'test',
      'durationMs': 3000,
      'events': [
        {'atMs': 0, 'phase': 'waiting', 'prompt': '等待', 'quality': 0},
        {'atMs': 1000, 'phase': 'aligning', 'prompt': '對準', 'quality': 0.4},
        {
          'atMs': 2000,
          'phase': 'captured',
          'prompt': '完成',
          'quality': 1,
          'capture': true,
        },
      ],
    });

    expect(
      script.eventAt(const Duration(milliseconds: 1500)).phase,
      ScanPhase.aligning,
    );
    expect(script.eventAt(const Duration(milliseconds: 2500)).capture, isTrue);
    expect(
      script.nextEventAfter(const Duration(milliseconds: 1500))?.at,
      const Duration(milliseconds: 2000),
    );
  });

  test('all demonstration scripts expose the expected final evidence', () {
    final clean = ScanTimelineScript.fromJsonString(
      File('assets/scripts/exterior_clean.json').readAsStringSync(),
    );
    final damage = ScanTimelineScript.fromJsonString(
      File('assets/scripts/exterior_damage.json').readAsStringSync(),
    );
    final interior = ScanTimelineScript.fromJsonString(
      File('assets/scripts/interior_dirty.json').readAsStringSync(),
    );

    expect(clean.events.last.phase, ScanPhase.captured);
    expect(clean.events.last.anomalyBox, isNull);
    expect(
      damage.events.any(
        (event) =>
            event.phase == ScanPhase.detailRequired && event.anomalyBox != null,
      ),
      isTrue,
    );
    expect(interior.events.last.phase, ScanPhase.captured);
    expect(interior.events.last.anomalyBox, isNotNull);
    expect(interior.events.last.capture, isTrue);
  });
}
