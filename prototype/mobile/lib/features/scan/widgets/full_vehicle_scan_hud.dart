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
    required this.resultLabel,
    required this.resultDetail,
    required this.resultIsAnomaly,
    required this.onReplay,
    required this.onStartDetail,
    this.anomalyZones = const {},
    super.key,
  });

  final FullVehicleScanController session;
  final ScanTimelineEvent event;
  final bool isInterior;
  final Widget video;
  final String? resultLabel;
  final String? resultDetail;
  final bool resultIsAnomaly;
  final VoidCallback onReplay;
  final VoidCallback? onStartDetail;
  final Set<InspectionZoneType> anomalyZones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedBuilder(
          animation: session,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              video,
              ScanGuideOverlay(event: event, isInterior: isInterior),
              const Positioned.fill(child: _CameraShade()),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: _DetectionBadge(session: session),
              ),
              if (event.phase == ScanPhase.moving ||
                  event.phase == ScanPhase.interiorTransition)
                Positioned(
                  top: AppSpacing.md,
                  left: 0,
                  right: 0,
                  child: _MovementCue(label: event.prompt),
                ),
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _ScanStatusCard(
                  session: session,
                  event: event,
                  resultLabel: resultLabel,
                  resultDetail: resultDetail,
                  resultIsAnomaly: resultIsAnomaly,
                  onReplay: onReplay,
                  onStartDetail: onStartDetail,
                ),
              ),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _CoverageCard(
                  session: session,
                  anomalyZones: anomalyZones,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementCue extends StatefulWidget {
  const _MovementCue({required this.label});

  final String label;

  @override
  State<_MovementCue> createState() => _MovementCueState();
}

class _MovementCueState extends State<_MovementCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat(reverse: true);
    _offset = Tween<double>(
      begin: -5,
      end: 7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.captureCyan.withValues(alpha: 0.62),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _offset,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(_offset.value, 0),
                    child: child,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.captureCyan,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraShade extends StatelessWidget {
  const _CameraShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.38),
            ],
            stops: const [0, 0.56, 1],
          ),
        ),
      ),
    );
  }
}

class _DetectionBadge extends StatelessWidget {
  const _DetectionBadge({required this.session});

  final FullVehicleScanController session;

  @override
  Widget build(BuildContext context) {
    final detected = session.vehicleDetected;
    final zone = session.detectedZone;
    final color = detected ? AppColors.captureCyan : AppColors.warningOrange;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              detected
                  ? Icons.center_focus_strong_rounded
                  : Icons.directions_car_outlined,
              color: color,
              size: 17,
            ),
            const SizedBox(width: 7),
            Text(
              detected
                  ? zone == null
                        ? '已偵測車輛・辨識區域中'
                        : '已辨識：${zone.label}'
                  : '未偵測到車輛',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({
    required this.session,
    required this.event,
    required this.resultLabel,
    required this.resultDetail,
    required this.resultIsAnomaly,
    required this.onReplay,
    required this.onStartDetail,
  });

  final FullVehicleScanController session;
  final ScanTimelineEvent event;
  final String? resultLabel;
  final String? resultDetail;
  final bool resultIsAnomaly;
  final VoidCallback onReplay;
  final VoidCallback? onStartDetail;

  @override
  Widget build(BuildContext context) {
    final captured = event.phase == ScanPhase.captured;
    final detailRequired = event.phase == ScanPhase.detailRequired;
    final evidenceCapturing = event.phase == ScanPhase.evidenceCapturing;
    final scanCompleted = session.isComplete;
    final locking = session.phase == FullVehicleScanPhase.qualityLocking;
    final accent = detailRequired || evidenceCapturing || resultIsAnomaly
        ? AppColors.warningOrange
        : session.phase == FullVehicleScanPhase.zoneCaptured
        ? AppColors.successGreen
        : AppColors.captureCyan;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 365),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.58)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    scanCompleted
                        ? Icons.check_circle_rounded
                        : detailRequired || evidenceCapturing
                        ? Icons.search_rounded
                        : captured
                        ? Icons.check_circle_rounded
                        : Icons.motion_photos_auto_rounded,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      detailRequired || evidenceCapturing
                          ? event.prompt
                          : session.prompt,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (locking) ...[
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: const Key('quality-lock-progress'),
                    value: session.lockProgress,
                    minHeight: 6,
                    color: AppColors.captureCyan,
                    backgroundColor: const Color(0xFF4B5157),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  session.lockProgress >= 1 ? '品質已鎖定' : '對準後 1 秒內自動擷取',
                  style: const TextStyle(
                    color: Color(0xFFD1D5D8),
                    fontSize: 11,
                  ),
                ),
              ],
              if (evidenceCapturing && event.evidenceStep != null) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '多角度補掃 ${event.evidenceStep} / ${event.evidenceTotal ?? 3}',
                        style: const TextStyle(
                          color: Color(0xFFD1D5D8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (event.capture)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.successGreen,
                        size: 17,
                      ),
                  ],
                ),
              ],
              if ((captured || evidenceCapturing || scanCompleted) &&
                  resultLabel != null) ...[
                const SizedBox(height: 7),
                Text(
                  resultLabel!,
                  style: TextStyle(
                    color: resultIsAnomaly
                        ? AppColors.warningOrange
                        : AppColors.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (resultDetail != null)
                  Text(
                    resultDetail!,
                    style: const TextStyle(
                      color: Color(0xFFCBD0D3),
                      fontSize: 11,
                    ),
                  ),
              ],
              if (detailRequired && onStartDetail != null) ...[
                const SizedBox(height: 9),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('重播'),
                    ),
                    FilledButton(
                      onPressed: onStartDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warningOrange,
                        minimumSize: const Size(112, 40),
                      ),
                      child: const Text('靠近補掃'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.session, required this.anomalyZones});

  final FullVehicleScanController session;
  final Set<InspectionZoneType> anomalyZones;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF50565C)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '全車進度',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${session.completedCount} / 6',
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              VehicleCoverageMap(
                zones: session.zones,
                activeZone: session.detectedZone,
                suggestedZone: session.suggestedZone,
                anomalyZones: anomalyZones,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
