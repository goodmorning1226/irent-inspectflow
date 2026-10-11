import 'package:flutter/material.dart';

import '../../../models/inspection_zone.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../controllers/full_vehicle_scan_controller.dart';
import '../models/scan_timeline.dart';
import 'scan_guide_overlay.dart';
import 'vehicle_coverage_map.dart';

class FullVehicleScanHud extends StatelessWidget {
  const FullVehicleScanHud({
    required this.session,
    required this.event,
    required this.isInterior,
    required this.video,
    this.anomalyZones = const {},
    super.key,
  });

  final FullVehicleScanController session;
  final ScanTimelineEvent event;
  final bool isInterior;
  final Widget video;
  final Set<InspectionZoneType> anomalyZones;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          video,
          ScanGuideOverlay(event: event, isInterior: isInterior),
          Positioned(
            left: AppSpacing.md,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
            child: _ScanInstruction(event: event),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
            child: _CoverageCard(session: session, anomalyZones: anomalyZones),
          ),
        ],
      ),
    );
  }
}

class _ScanInstruction extends StatelessWidget {
  const _ScanInstruction({required this.event});

  final ScanTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final satisfied =
        event.phase == ScanPhase.captured ||
        event.phase == ScanPhase.completed ||
        (event.phase == ScanPhase.evidenceCapturing && event.capture);
    final accent = satisfied ? AppColors.successGreen : AppColors.captureCyan;

    return SizedBox(
      key: const Key('scan-single-instruction'),
      width: 350,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.82), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(_instructionIcon(event.phase), color: accent, size: 21),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    event.prompt,
                    key: ValueKey(event.prompt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _instructionIcon(ScanPhase phase) => switch (phase) {
    ScanPhase.moving ||
    ScanPhase.interiorTransition => Icons.directions_walk_rounded,
    ScanPhase.detailRequired ||
    ScanPhase.evidenceCapturing => Icons.search_rounded,
    _ => Icons.center_focus_strong_rounded,
  };
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.session, required this.anomalyZones});

  final FullVehicleScanController session;
  final Set<InspectionZoneType> anomalyZones;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF50565C)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: VehicleCoverageMap(
            zones: session.zones,
            activeZone: session.detectedZone,
            suggestedZone: session.suggestedZone,
            anomalyZones: anomalyZones,
          ),
        ),
      ),
    );
  }
}
