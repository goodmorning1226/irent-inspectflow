import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../mock/mock_inspection_data.dart';
import '../../models/finding.dart';
import '../../models/inspection_zone.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/scan_scaffold.dart';
import 'controllers/local_scan_video_controller.dart';
import 'controllers/scan_timeline_controller.dart';
import 'damage_detail_flow.dart';
import 'models/scan_completion.dart';
import 'models/scan_timeline.dart';
import 'widgets/local_scan_video.dart';
import 'widgets/scan_guide_overlay.dart';

enum DemoScenario { exteriorClean, exteriorDamage, interiorDirty }

extension on DemoScenario {
  String get label => switch (this) {
    DemoScenario.exteriorClean => '左側無損',
    DemoScenario.exteriorDamage => '左側有損',
    DemoScenario.interiorDirty => '後座污損',
  };
}

class ScanPrototypePage extends StatefulWidget {
  const ScanPrototypePage({required this.zone, super.key});

  final InspectionZone zone;

  @override
  State<ScanPrototypePage> createState() => _ScanPrototypePageState();
}

class _ScanPrototypePageState extends State<ScanPrototypePage> {
  static const _cleanVideoAsset = 'assets/videos/exterior_clean.mp4';
  static const _cleanScriptAsset = 'assets/scripts/exterior_clean.json';
  static const _cleanBestFrameAsset = 'assets/frames/exterior_clean_best.png';
  static const _damageVideoAsset = 'assets/videos/exterior_damage.mp4';
  static const _damageScriptAsset = 'assets/scripts/exterior_damage.json';
  static const _damageWideFrameAsset = 'assets/frames/exterior_damage_wide.png';
  static const _interiorVideoAsset = 'assets/videos/interior_dirty.mp4';
  static const _interiorScriptAsset = 'assets/scripts/interior_dirty.json';
  static const _interiorBestFrameAsset =
      'assets/frames/interior_dirty_best.png';

  final LocalScanVideoController _videoController = LocalScanVideoController();
  ScanTimelineController? _timelineController;
  Object? _loadError;
  DemoScenario _scenario = DemoScenario.exteriorClean;
  bool _showDamageDetail = false;

  @override
  void initState() {
    super.initState();
    if (widget.zone.type == InspectionZoneType.leftSide) {
      _scenario = DemoScenario.exteriorClean;
    } else if (widget.zone.type == InspectionZoneType.rearSeat) {
      _scenario = DemoScenario.interiorDirty;
    }
    unawaited(_loadTimeline());
  }

  bool get _isCleanScenario => _scenario == DemoScenario.exteriorClean;
  bool get _isDamageScenario => _scenario == DemoScenario.exteriorDamage;
  bool get _isInteriorScenario => _scenario == DemoScenario.interiorDirty;
  String get _videoAsset => switch (_scenario) {
    DemoScenario.exteriorClean => _cleanVideoAsset,
    DemoScenario.exteriorDamage => _damageVideoAsset,
    DemoScenario.interiorDirty => _interiorVideoAsset,
  };
  String get _scriptAsset => switch (_scenario) {
    DemoScenario.exteriorClean => _cleanScriptAsset,
    DemoScenario.exteriorDamage => _damageScriptAsset,
    DemoScenario.interiorDirty => _interiorScriptAsset,
  };
  String? get _bestFrameAsset => switch (_scenario) {
    DemoScenario.exteriorClean => _cleanBestFrameAsset,
    DemoScenario.exteriorDamage => _damageWideFrameAsset,
    DemoScenario.interiorDirty => _interiorBestFrameAsset,
  };

  Future<void> _loadTimeline() async {
    try {
      final source = await rootBundle.loadString(_scriptAsset);
      final script = ScanTimelineScript.fromJsonString(source);
      if (!mounted) return;
      setState(() => _timelineController = ScanTimelineController(script));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _changeScenario(DemoScenario scenario) async {
    if (scenario == _scenario) return;
    _timelineController?.dispose();
    setState(() {
      _scenario = scenario;
      _timelineController = null;
      _loadError = null;
      _showDamageDetail = false;
    });
    await _loadTimeline();
  }

  @override
  void dispose() {
    _timelineController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _replay() async {
    _timelineController?.reset();
    await _videoController.replay();
  }

  Future<void> _jumpToNextEvent() async {
    final timeline = _timelineController;
    if (timeline == null) return;
    final next = timeline.script.nextEventAfter(timeline.position);
    if (next == null) {
      await _replay();
      return;
    }
    await _videoController.seekTo(next.at);
  }

  Future<void> _reset() async {
    _timelineController?.reset();
    await _videoController.reset();
  }

  void _showDemoController() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.scanSurface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demo 控制器',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    '長按 Prototype 標示可再次開啟。正式使用者不會看到此面板。',
                    style: TextStyle(color: Color(0xFFB7BCC2)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownMenu<DemoScenario>(
                    initialSelection: _scenario,
                    label: const Text('展示案例'),
                    width: 260,
                    dropdownMenuEntries: [
                      for (final scenario in DemoScenario.values)
                        DropdownMenuEntry(
                          value: scenario,
                          label: scenario.label,
                        ),
                    ],
                    onSelected: (scenario) {
                      if (scenario == null) return;
                      Navigator.of(context).pop();
                      unawaited(_changeScenario(scenario));
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _replay,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('重播'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _jumpToNextEvent,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('跳到下一事件'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('重設'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timelineController;
    final zoneNumber =
        MockInspectionData.currentSession.zones.indexWhere(
          (zone) => zone.type == widget.zone.type,
        ) +
        1;
    return ScanScaffold(
      title: '${widget.zone.type.label}掃描　$zoneNumber/6',
      onPrototypeLongPress: _showDemoController,
      body: _showDamageDetail
          ? DamageDetailFlow(
              finding: MockFindings.leftRearDoorScratch,
              onBackToWide: () => setState(() => _showDamageDetail = false),
              onComplete: () =>
                  Navigator.of(context).pop(ScanCompletion.evidenceCaptured),
            )
          : _buildScanBody(timeline),
    );
  }

  Widget _buildScanBody(ScanTimelineController? timeline) {
    return switch ((timeline, _loadError)) {
      (_, final Object error) => _LoadFailure(error: error),
      (null, _) => const Center(
        child: CircularProgressIndicator(color: AppColors.captureCyan),
      ),
      (final ScanTimelineController timeline, _) => AnimatedBuilder(
        animation: timeline,
        builder: (context, _) => _ScanWorkspace(
          zone: widget.zone,
          event: timeline.event,
          scenario: _scenario,
          isInterior: _isInteriorScenario,
          bestFrameAsset: _bestFrameAsset,
          resultLabel: _isInteriorScenario
              ? '已記錄車內污損'
              : _isCleanScenario
              ? '未發現明顯異常'
              : null,
          resultDetail: _isInteriorScenario
              ? '${MockFindings.rearSeatDrinkStain.location}，等待後續處理'
              : null,
          resultIsAnomaly: _isInteriorScenario,
          video: LocalScanVideo(
            key: ValueKey(_videoAsset),
            assetPath: _videoAsset,
            fallbackAsset: _bestFrameAsset,
            controller: _videoController,
            onPositionChanged: timeline.updatePosition,
          ),
          onReplay: _replay,
          onComplete: _isCleanScenario
              ? () => Navigator.of(context).pop(ScanCompletion.clean)
              : _isInteriorScenario
              ? () => Navigator.of(
                  context,
                ).pop(ScanCompletion.interiorEvidenceCaptured)
              : null,
          onStartDetail: _isDamageScenario
              ? () => setState(() => _showDamageDetail = true)
              : null,
        ),
      ),
    };
  }
}

class _ScanWorkspace extends StatelessWidget {
  const _ScanWorkspace({
    required this.zone,
    required this.event,
    required this.scenario,
    required this.isInterior,
    required this.bestFrameAsset,
    required this.resultLabel,
    required this.resultDetail,
    required this.resultIsAnomaly,
    required this.video,
    required this.onReplay,
    required this.onComplete,
    required this.onStartDetail,
  });

  final InspectionZone zone;
  final ScanTimelineEvent event;
  final DemoScenario scenario;
  final bool isInterior;
  final String? bestFrameAsset;
  final String? resultLabel;
  final String? resultDetail;
  final bool resultIsAnomaly;
  final Widget video;
  final VoidCallback onReplay;
  final VoidCallback? onComplete;
  final VoidCallback? onStartDetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(width: 112, child: _ZoneRail(activeZone: zone.type)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  video,
                  ScanGuideOverlay(event: event, isInterior: isInterior),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: _CaptureStrip(
                      event: event,
                      bestFrameAsset: bestFrameAsset,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 184,
            child: _QualityPanel(
              event: event,
              scenario: scenario,
              resultLabel: resultLabel,
              resultDetail: resultDetail,
              resultIsAnomaly: resultIsAnomaly,
              onReplay: onReplay,
              onComplete: onComplete,
              onStartDetail: onStartDetail,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneRail extends StatelessWidget {
  const _ZoneRail({required this.activeZone});

  final InspectionZoneType activeZone;

  @override
  Widget build(BuildContext context) {
    final zones = MockInspectionData.currentSession.zones;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.scanSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final zone in zones)
              _RailItem(zone: zone, isActive: zone.type == activeZone),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.zone, required this.isActive});

  final InspectionZone zone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          color: isActive ? AppColors.captureCyan : Colors.transparent,
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(
          zone.status == ZoneStatus.completed
              ? Icons.check_circle_rounded
              : zone.type.icon,
          color: isActive
              ? AppColors.captureCyan
              : zone.status == ZoneStatus.completed
              ? AppColors.successGreen
              : const Color(0xFF92989E),
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            zone.type.label,
            style: TextStyle(
              color: isActive ? AppColors.white : const Color(0xFFB7BCC2),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _QualityPanel extends StatelessWidget {
  const _QualityPanel({
    required this.event,
    required this.scenario,
    required this.resultLabel,
    required this.resultDetail,
    required this.resultIsAnomaly,
    required this.onReplay,
    required this.onComplete,
    required this.onStartDetail,
  });

  final ScanTimelineEvent event;
  final DemoScenario scenario;
  final String? resultLabel;
  final String? resultDetail;
  final bool resultIsAnomaly;
  final VoidCallback onReplay;
  final VoidCallback? onComplete;
  final VoidCallback? onStartDetail;

  @override
  Widget build(BuildContext context) {
    final captured = event.phase == ScanPhase.captured;
    final detailRequired = event.phase == ScanPhase.detailRequired;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.scanSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: event.quality,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFF34383D),
                    color: detailRequired || (captured && resultIsAnomaly)
                        ? AppColors.warningOrange
                        : captured
                        ? AppColors.successGreen
                        : AppColors.captureCyan,
                  ),
                  Text(
                    '${(event.quality * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              event.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _phaseLabel(event.phase),
              style: TextStyle(
                color: detailRequired || (captured && resultIsAnomaly)
                    ? AppColors.warningOrange
                    : captured
                    ? AppColors.successGreen
                    : AppColors.captureCyan,
                fontSize: 13,
              ),
            ),
            if (captured && onComplete != null && resultLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    resultIsAnomaly
                        ? Icons.report_problem_rounded
                        : Icons.check_circle_rounded,
                    color: resultIsAnomaly
                        ? AppColors.warningOrange
                        : AppColors.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      resultLabel!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (resultDetail != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  resultDetail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB7BCC2),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
            if (detailRequired && onStartDetail != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                '疑似異常，需要補掃',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.warningOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const Spacer(),
            Text(
              scenario.label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8F969D), fontSize: 11),
            ),
            if (captured || detailRequired) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: '重播掃描',
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay_rounded),
                  ),
                  if (onComplete != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton(
                      onPressed: onComplete,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: AppColors.successGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: const Text('完成'),
                    ),
                  ],
                  if (detailRequired && onStartDetail != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton(
                      onPressed: onStartDetail,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: AppColors.warningOrange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: const Text('開始補掃'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _phaseLabel(ScanPhase phase) => switch (phase) {
    ScanPhase.waiting => '等待定位',
    ScanPhase.aligning => '調整位置',
    ScanPhase.stable => '品質鎖定',
    ScanPhase.captured => '自動擷取完成',
    ScanPhase.detailRequired => '疑似異常',
  };
}

class _CaptureStrip extends StatelessWidget {
  const _CaptureStrip({required this.event, required this.bestFrameAsset});

  final ScanTimelineEvent event;
  final String? bestFrameAsset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              _FrameThumbnail(
                isCaptured: event.capture && index == 0,
                index: index + 1,
                imageAsset: event.capture && index == 0 ? bestFrameAsset : null,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Icon(
              event.capture ? Icons.photo_rounded : Icons.photo_outlined,
              color: event.capture
                  ? AppColors.successGreen
                  : const Color(0xFFB7BCC2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                event.capture ? '最佳影格已保存' : '最佳影格將在品質穩定後自動保存',
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('手動備援')),
          ],
        ),
      ),
    );
  }
}

class _FrameThumbnail extends StatelessWidget {
  const _FrameThumbnail({
    required this.isCaptured,
    required this.index,
    required this.imageAsset,
  });

  final bool isCaptured;
  final int index;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCaptured ? AppColors.successGreen : const Color(0xFF454A50),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCaptured ? AppColors.white : const Color(0xFF666C72),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageAsset == null
          ? Text(
              '$index',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          : Image.asset(imageAsset!, fit: BoxFit.cover),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '無法載入掃描腳本。請確認本機素材是否完整。\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.white),
        ),
      ),
    );
  }
}
