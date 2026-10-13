import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/scan_timeline.dart';

class TimelinePanorama extends StatelessWidget {
  const TimelinePanorama({
    required this.assetPath,
    required this.event,
    required this.position,
    super.key,
  });

  final String assetPath;
  final ScanTimelineEvent event;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final motionDuration = event.previewMotionDuration.inMilliseconds;
    final motionDelay = event.previewMotionDelay.inMilliseconds;
    final elapsed = (position - event.at).inMilliseconds - motionDelay;
    final linearProgress = motionDuration <= 0
        ? 1.0
        : (elapsed / motionDuration).clamp(0.0, 1.0);
    final progress = Curves.easeInOutSine.transform(linearProgress);
    final panX = _lerp(
      event.previewPanX,
      event.previewPanToX ?? event.previewPanX,
      progress,
    );
    final panY = _lerp(
      event.previewPanY,
      event.previewPanToY ?? event.previewPanY,
      progress,
    );
    final scale = _lerp(
      event.previewScale,
      event.previewScaleTo ?? event.previewScale,
      progress,
    );
    final translateX = _lerp(
      event.previewTranslateX,
      event.previewTranslateToX ?? event.previewTranslateX,
      progress,
    );
    final translateY = _lerp(
      event.previewTranslateY,
      event.previewTranslateToY ?? event.previewTranslateY,
      progress,
    );

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final walkingOffset = event.previewWalking
              ? math.sin(linearProgress * math.pi * 4) * 1.2
              : 0.0;
          return Transform.translate(
            key: const Key('panorama-viewport-motion'),
            offset: Offset(
              translateX * constraints.maxWidth,
              (-panY + translateY) * constraints.maxHeight + walkingOffset,
            ),
            child: Transform.scale(
              key: const Key('panorama-scale'),
              scale: scale,
              child: Image.asset(
                assetPath,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.cover,
                alignment: Alignment(panX, 0),
                gaplessPlayback: true,
              ),
            ),
          );
        },
      ),
    );
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }
}
