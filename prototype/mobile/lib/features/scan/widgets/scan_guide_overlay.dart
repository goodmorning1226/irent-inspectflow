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

          return Stack(
            children: [
              Positioned.fromRect(
                rect: frame,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          event.phase == ScanPhase.detailRequired ||
                              event.anomalyBox != null
                          ? AppColors.warningOrange
                          : event.phase == ScanPhase.captured
                          ? AppColors.successGreen
                          : AppColors.captureCyan,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              if (event.anomalyBox case final NormalizedScanBox anomalyBox)
                Positioned(
                  left: constraints.maxWidth * anomalyBox.left,
                  top: constraints.maxHeight * anomalyBox.top,
                  width: constraints.maxWidth * anomalyBox.width,
                  height: constraints.maxHeight * anomalyBox.height,
                  child: DecoratedBox(
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
              Center(
                child: Icon(
                  event.phase == ScanPhase.captured
                      ? Icons.check_circle_rounded
                      : isInterior
                      ? Icons.event_seat_rounded
                      : Icons.directions_car_filled_rounded,
                  size: event.phase == ScanPhase.captured ? 60 : 76,
                  color: AppColors.white.withValues(
                    alpha: event.phase == ScanPhase.captured ? 0.94 : 0.38,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
