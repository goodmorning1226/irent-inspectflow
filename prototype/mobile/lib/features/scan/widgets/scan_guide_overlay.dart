import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/scan_timeline.dart';

class ScanGuideOverlay extends StatelessWidget {
  const ScanGuideOverlay({
    required this.event,
    this.isInterior = false,
    super.key,
  });

  final ScanTimelineEvent event;
  final bool isInterior;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final box = event.box;
          final frame = box == null
              ? Rect.fromLTWH(
                  constraints.maxWidth * 0.12,
                  constraints.maxHeight * 0.2,
                  constraints.maxWidth * 0.76,
                  constraints.maxHeight * 0.58,
                )
              : Rect.fromLTWH(
                  constraints.maxWidth * box.left,
                  constraints.maxHeight * box.top,
                  constraints.maxWidth * box.width,
                  constraints.maxHeight * box.height,
                );
          final visibleAnomalyBox = event.previewScaleTo == null
              ? event.anomalyBox
              : null;
          final visibleAdjustmentDirection = event.adjustmentSatisfied
              ? null
              : event.adjustmentDirection;

          return Stack(
            children: [
              if ((event.phase != ScanPhase.moving || event.box != null) &&
                  event.phase != ScanPhase.interiorTransition &&
                  event.phase != ScanPhase.completed)
                Positioned.fromRect(
                  rect: frame,
                  child: DecoratedBox(
                    key: const Key('scan-guide-frame'),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: event.capture
                            ? AppColors.successGreen
                            : event.previewScaleTo == null &&
                                  (event.phase == ScanPhase.detailRequired ||
                                      event.anomalyBox != null)
                            ? AppColors.warningOrange
                            : AppColors.captureCyan,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              if (visibleAnomalyBox case final NormalizedScanBox anomalyBox)
                Positioned(
                  left: constraints.maxWidth * anomalyBox.left,
                  top: constraints.maxHeight * anomalyBox.top,
                  width: constraints.maxWidth * anomalyBox.width,
                  height: constraints.maxHeight * anomalyBox.height,
                  child: DecoratedBox(
                    key: const Key('scan-anomaly-box'),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.warningOrange,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.search_rounded,
                          color: AppColors.warningOrange,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              if (visibleAdjustmentDirection case final direction?)
                Align(
                  alignment: Alignment.center,
                  child: _AdjustmentCue(direction: direction),
                ),
              if (visibleAdjustmentDirection == null &&
                  event.phase != ScanPhase.moving &&
                  event.phase != ScanPhase.interiorTransition)
                Center(
                  child: Icon(
                    event.capture ||
                            event.phase == ScanPhase.captured ||
                            event.phase == ScanPhase.completed
                        ? Icons.check_circle_rounded
                        : event.phase == ScanPhase.evidenceCapturing ||
                              event.phase == ScanPhase.detailRequired
                        ? Icons.search_rounded
                        : isInterior
                        ? Icons.event_seat_rounded
                        : Icons.directions_car_filled_rounded,
                    key: const Key('scan-status-icon'),
                    size: event.capture ? 60 : 76,
                    color: event.capture
                        ? AppColors.successGreen.withValues(alpha: 0.94)
                        : AppColors.white.withValues(alpha: 0.38),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdjustmentCue extends StatefulWidget {
  const _AdjustmentCue({required this.direction});

  final ScanAdjustmentDirection direction;

  @override
  State<_AdjustmentCue> createState() => _AdjustmentCueState();
}

class _AdjustmentCueState extends State<_AdjustmentCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AdjustmentCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction) {
      _controller.value = 0;
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
      return;
    }
    _controller
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (unitOffset, icon, label) = switch (widget.direction) {
      ScanAdjustmentDirection.left => (
        const Offset(-1, 0),
        Icons.arrow_back_rounded,
        '向左移動',
      ),
      ScanAdjustmentDirection.right => (
        const Offset(1, 0),
        Icons.arrow_forward_rounded,
        '向右移動',
      ),
      ScanAdjustmentDirection.upLeft => (
        const Offset(-0.707, -0.707),
        Icons.north_west_rounded,
        '向左上移動',
      ),
      ScanAdjustmentDirection.downRight => (
        const Offset(0.707, 0.707),
        Icons.south_east_rounded,
        '向右下移動',
      ),
      ScanAdjustmentDirection.forward => (
        const Offset(0, -1),
        Icons.arrow_upward_rounded,
        '向前移動',
      ),
    };
    const accent = AppColors.captureCyan;

    return Semantics(
      label: label,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(_controller.value);
          final motionDistance =
              widget.direction == ScanAdjustmentDirection.forward ? 24.0 : 38.0;
          final movingArrow =
              widget.direction == ScanAdjustmentDirection.forward
              ? Transform.scale(
                  scale: 1 - (0.14 * progress),
                  child: CustomPaint(
                    key: const Key('forward-adjustment-arrow'),
                    size: const Size(92, 104),
                    painter: _FloorForwardArrowPainter(color: accent),
                  ),
                )
              : Icon(
                  icon,
                  key: const Key('adjustment-arrow'),
                  color: accent,
                  size: 76,
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                );
          return Opacity(
            opacity: 0.62,
            child: Transform.translate(
              key: const Key('adjustment-motion'),
              offset: unitOffset * (motionDistance * progress),
              child: movingArrow,
            ),
          );
        },
      ),
    );
  }
}

class _FloorForwardArrowPainter extends CustomPainter {
  const _FloorForwardArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(size.width * 0.66, size.height * 0.42)
      ..lineTo(size.width * 0.72, size.height)
      ..lineTo(size.width * 0.28, size.height)
      ..lineTo(size.width * 0.34, size.height * 0.42)
      ..lineTo(0, size.height * 0.42)
      ..close();
    canvas.drawShadow(path, const Color(0xCC000000), 8, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.86),
    );
  }

  @override
  bool shouldRepaint(covariant _FloorForwardArrowPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
