import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inspectflow_mobile/features/scan/controllers/scan_timeline_controller.dart';
import 'package:inspectflow_mobile/features/scan/models/scan_timeline.dart';
import 'package:inspectflow_mobile/models/inspection_zone.dart';

void main() {
  test('timeline controller refreshes motion within the same event', () {
    final script = ScanTimelineScript.fromJson({
      'scenarioId': 'motion-test',
      'durationMs': 2000,
      'events': [
        {'atMs': 0, 'phase': 'aligning', 'prompt': '移動', 'quality': 0.4},
      ],
    });
    final controller = ScanTimelineController(script);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.updatePosition(const Duration(milliseconds: 200));
    controller.updatePosition(const Duration(milliseconds: 400));

    expect(notifications, 2);
    expect(controller.position, const Duration(milliseconds: 400));
  });

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

  test('full vehicle timeline covers six zones in one continuous session', () {
    final script = ScanTimelineScript.fromJsonString(
      File('assets/scripts/full_vehicle_scan.json').readAsStringSync(),
    );
    final completedZones = script.events
        .where(
          (event) =>
              event.phase == ScanPhase.captured ||
              (event.phase == ScanPhase.evidenceCapturing &&
                  event.capture &&
                  event.evidenceStep == event.evidenceTotal),
        )
        .map((event) => event.zone)
        .toSet();
    final evidenceCaptures = script.events.where(
      (event) => event.phase == ScanPhase.evidenceCapturing && event.capture,
    );

    expect(completedZones, InspectionZoneType.values.toSet());
    expect(
      script.events.any(
        (event) =>
            event.phase == ScanPhase.detailRequired &&
            event.zone == InspectionZoneType.leftSide &&
            event.anomalyBox != null,
      ),
      isTrue,
    );
    expect(evidenceCaptures.length, 3);
    expect(evidenceCaptures.map((event) => event.evidenceView), [
      EvidenceView.center,
      EvidenceView.left,
      EvidenceView.right,
    ]);
    final rearSeatFinding = script.events.singleWhere(
      (event) => event.finding == ScanFindingKind.stain,
    );
    expect(rearSeatFinding.zone, InspectionZoneType.rearSeat);
    expect(rearSeatFinding.capture, isTrue);
    expect(rearSeatFinding.anomalyBox, isNotNull);
    expect(
      script.events.any(
        (event) =>
            event.zone == InspectionZoneType.rearSeat && event.deferCompletion,
      ),
      isTrue,
    );
    expect(script.events.last.phase, ScanPhase.completed);
    expect(script.duration, const Duration(milliseconds: 28950));

    final frontAdjustment = script.events.firstWhere(
      (event) => event.adjustmentDirection != null,
    );
    expect(frontAdjustment.adjustmentDirection, ScanAdjustmentDirection.left);
    expect(frontAdjustment.previewOffsetX, 0);
    expect(
      frontAdjustment.previewAsset,
      'assets/frames/vehicle_front_panorama_v2.png',
    );
    expect(frontAdjustment.prompt, '請向左移動一點');
    expect(frontAdjustment.at, const Duration(milliseconds: 2600));
    expect(script.events.any((event) => event.adjustmentSatisfied), isFalse);
    final completedAdjustment = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 4400),
    );
    expect(completedAdjustment.at, const Duration(milliseconds: 4400));
    expect(completedAdjustment.previewAsset, frontAdjustment.previewAsset);
    expect(completedAdjustment.adjustmentDirection, isNull);
    expect(completedAdjustment.prompt, '保持手機穩定');

    expect(frontAdjustment.previewPanX, 0.4);
    expect(frontAdjustment.previewPanToX, -1);
    expect(
      frontAdjustment.previewMotionDelay,
      const Duration(milliseconds: 400),
    );
    expect(
      frontAdjustment.previewMotionDuration,
      const Duration(milliseconds: 1400),
    );
    expect(frontAdjustment.previewWalking, isTrue);
    expect(
      script.events
          .where((event) => event.zone == InspectionZoneType.front)
          .every(
            (event) =>
                event.previewAsset ==
                'assets/frames/vehicle_front_panorama_v2.png',
          ),
      isTrue,
    );
    final moveToLeftSide = script.events.firstWhere(
      (event) =>
          event.zone == InspectionZoneType.leftSide &&
          event.phase == ScanPhase.moving,
    );
    expect(moveToLeftSide.previewAsset, frontAdjustment.previewAsset);
    expect(moveToLeftSide.previewPanX, -1);
    expect(moveToLeftSide.at, const Duration(milliseconds: 6500));
    expect(moveToLeftSide.box, isNotNull);
    final frontCaptured = script.events.firstWhere(
      (event) =>
          event.zone == InspectionZoneType.front &&
          event.phase == ScanPhase.captured,
    );
    expect(
      moveToLeftSide.at - frontCaptured.at,
      const Duration(milliseconds: 800),
    );

    final anomalyHold = script.events.firstWhere(
      (event) =>
          event.zone == InspectionZoneType.leftSide &&
          event.phase == ScanPhase.detailRequired,
    );
    expect(anomalyHold.at, const Duration(milliseconds: 7700));
    expect(anomalyHold.anomalyBox, isNotNull);
    expect(anomalyHold.anomalyBox!.left, 0.575);
    expect(anomalyHold.anomalyBox!.top, 0.55);
    expect(anomalyHold.anomalyBox!.width, 0.155);
    expect(anomalyHold.anomalyBox!.height, 0.14);
    expect(anomalyHold.adjustmentDirection, isNull);
    expect(
      anomalyHold.previewAsset,
      'assets/frames/exterior_damage_source.png',
    );

    final forwardCueHold = script.events.firstWhere(
      (event) =>
          event.adjustmentDirection == ScanAdjustmentDirection.forward &&
          event.anomalyBox != null,
    );
    expect(forwardCueHold.at, const Duration(milliseconds: 8300));
    expect(forwardCueHold.previewAsset, anomalyHold.previewAsset);
    expect(forwardCueHold.previewScale, 1);
    expect(forwardCueHold.previewScaleTo, isNull);

    final forwardAdjustment = script.events.firstWhere(
      (event) =>
          event.adjustmentDirection == ScanAdjustmentDirection.forward &&
          event.previewScaleTo != null,
    );
    expect(forwardAdjustment.at, const Duration(milliseconds: 8900));
    expect(forwardAdjustment.anomalyBox, isNull);
    expect(forwardAdjustment.previewScale, 1);
    expect(forwardAdjustment.previewScaleTo, 2.3);
    expect(forwardAdjustment.previewTranslateToX, -0.29);
    expect(forwardAdjustment.previewTranslateToY, -0.3);
    expect(forwardAdjustment.previewMotionDelay, Duration.zero);
    expect(
      forwardAdjustment.previewMotionDuration,
      const Duration(milliseconds: 1000),
    );

    final upLeftAdjustment = script.events.firstWhere(
      (event) => event.adjustmentDirection == ScanAdjustmentDirection.upLeft,
    );
    expect(upLeftAdjustment.evidenceView, EvidenceView.left);
    expect(upLeftAdjustment.prompt, '請向左上移動一點');
    expect(upLeftAdjustment.previewTranslateToX, -0.23);
    expect(upLeftAdjustment.previewTranslateToY, -0.24);

    final upLeftReached = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 12850),
    );
    expect(upLeftReached.at, const Duration(milliseconds: 12850));
    expect(upLeftReached.adjustmentDirection, isNull);
    expect(upLeftReached.prompt, '保持手機穩定');
    final secondViewHold = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 13100),
    );
    expect(secondViewHold.adjustmentDirection, isNull);
    expect(secondViewHold.capture, isFalse);
    final secondViewCaptured = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 13950),
    );
    expect(secondViewCaptured.capture, isTrue);

    final downRightAdjustment = script.events.firstWhere(
      (event) => event.adjustmentDirection == ScanAdjustmentDirection.downRight,
    );
    expect(downRightAdjustment.evidenceView, EvidenceView.right);
    expect(downRightAdjustment.prompt, '請向右下移動一點');
    expect(downRightAdjustment.previewTranslateToX, -0.33);
    expect(downRightAdjustment.previewTranslateToY, -0.34);

    final downRightReached = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 15850),
    );
    expect(downRightReached.at, const Duration(milliseconds: 15850));
    expect(downRightReached.adjustmentDirection, isNull);
    expect(downRightReached.prompt, '保持手機穩定');
    final thirdViewHold = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 16100),
    );
    expect(thirdViewHold.adjustmentDirection, isNull);
    expect(thirdViewHold.capture, isFalse);
    final thirdViewCaptured = script.events.firstWhere(
      (event) => event.at == const Duration(milliseconds: 16950),
    );
    expect(thirdViewCaptured.capture, isTrue);

    final delayedDirectionalMovements = script.events.where(
      (event) =>
          (event.adjustmentDirection == ScanAdjustmentDirection.upLeft ||
              event.adjustmentDirection == ScanAdjustmentDirection.downRight) &&
          !event.adjustmentSatisfied,
    );
    expect(
      delayedDirectionalMovements.every(
        (event) =>
            event.previewMotionDelay >= const Duration(milliseconds: 350),
      ),
      isTrue,
    );
    expect(
      forwardAdjustment.at - forwardCueHold.at,
      const Duration(milliseconds: 600),
    );

    final moveToRear = script.events.firstWhere(
      (event) =>
          event.at > thirdViewCaptured.at && event.phase == ScanPhase.moving,
    );
    expect(moveToRear.prompt, '移動至車尾');
    expect(moveToRear.previewAsset, 'assets/frames/exterior_damage_source.png');
    expect(
      script.events
          .where(
            (event) =>
                event.at >= const Duration(milliseconds: 7100) &&
                event.at <= const Duration(milliseconds: 17450),
          )
          .every(
            (event) =>
                event.previewAsset ==
                'assets/frames/exterior_damage_source.png',
          ),
      isTrue,
    );
    final rearAlignment = script.events.firstWhere(
      (event) =>
          event.zone == InspectionZoneType.rear &&
          event.phase == ScanPhase.aligning,
    );
    expect(rearAlignment.previewAsset, isNull);
  });

  test('each full vehicle scan instruction stays visible long enough', () {
    final script = ScanTimelineScript.fromJsonString(
      File('assets/scripts/full_vehicle_scan.json').readAsStringSync(),
    );

    var promptStartedAt = script.events.first.at;
    var activePrompt = script.events.first.prompt;
    final promptDurations = <Duration>[];

    for (final event in script.events.skip(1)) {
      if (event.prompt == activePrompt) continue;
      promptDurations.add(event.at - promptStartedAt);
      promptStartedAt = event.at;
      activePrompt = event.prompt;
    }
    promptDurations.add(script.duration - promptStartedAt);

    expect(
      promptDurations.every(
        (duration) => duration >= const Duration(milliseconds: 600),
      ),
      isTrue,
    );
  });
}
