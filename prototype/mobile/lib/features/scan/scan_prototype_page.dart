import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../mock/mock_inspection_data.dart';
import '../../models/inspection_zone.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/scan_scaffold.dart';
import 'controllers/full_vehicle_scan_controller.dart';
import 'controllers/local_scan_video_controller.dart';
import 'controllers/scan_timeline_controller.dart';
import 'models/scan_completion.dart';
import 'models/scan_timeline.dart';
import 'widgets/full_vehicle_scan_hud.dart';
import 'widgets/local_scan_video.dart';

class ScanPrototypePage extends StatefulWidget {
  const ScanPrototypePage({this.zone, super.key});

  // Kept optional so older prototype deep links remain source-compatible.
  // The continuous scan no longer asks the user to choose a zone.
  final InspectionZone? zone;

  @override
  State<ScanPrototypePage> createState() => _ScanPrototypePageState();
}

class _ScanPrototypePageState extends State<ScanPrototypePage> {
  static const _videoAsset = 'assets/videos/full_vehicle_scan.mp4';
  static const _scriptAsset = 'assets/scripts/full_vehicle_scan.json';
  static const _fallbackAsset = 'assets/frames/exterior_clean_best.png';

  final LocalScanVideoController _videoController = LocalScanVideoController();
  late final FullVehicleScanController _scanSession;
  ScanTimelineController? _timelineController;
  Timer? _fastLockTimer;
  Timer? _automaticCompletionTimer;
  Object? _loadError;
  ScanTimelineEvent? _handledEvent;
  bool _didReturnCompletion = false;
  final Set<InspectionZoneType> _anomalyZones = {};

  @override
  void initState() {
    super.initState();
    _scanSession = FullVehicleScanController(
      initialZones: MockInspectionData.currentSession.zones,
    );
    unawaited(_loadTimeline());
  }

  Future<void> _loadTimeline() async {
    try {
      final source = await rootBundle.loadString(_scriptAsset);
      final script = ScanTimelineScript.fromJsonString(source);
      if (!mounted) return;
      final timeline = ScanTimelineController(script)
        ..addListener(_syncTimelineToSession);
      setState(() => _timelineController = timeline);
      _syncTimelineToSession();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _syncTimelineToSession() {
    final event = _timelineController?.event;
    if (event == null || identical(event, _handledEvent)) return;
    _handledEvent = event;

    switch (event.phase) {
      case ScanPhase.waiting:
        _cancelQualityLock();
        _scanSession.updateDetection(vehicleDetected: false);
      case ScanPhase.moving:
        _cancelQualityLock();
        _scanSession.showMoveGuidance();
      case ScanPhase.aligning:
        _cancelQualityLock();
        _scanSession.updateDetection(vehicleDetected: true, zone: event.zone);
      case ScanPhase.stable:
        _startFastQualityLock(
          event.zone,
          completeAfterLock: !event.requiresDetail && !event.deferCompletion,
        );
      case ScanPhase.captured:
        if (event.finding != null && event.zone != null) {
          _anomalyZones.add(event.zone!);
        }
        _finishZone(event.zone, finding: event.finding);
      case ScanPhase.interiorTransition:
        _cancelQualityLock();
        _scanSession.beginInteriorTransition();
      case ScanPhase.detailRequired:
        _cancelQualityLock();
        if (event.zone case final InspectionZoneType zone) {
          _anomalyZones.add(zone);
          _scanSession.beginDamageDetail(zone);
        }
      case ScanPhase.evidenceCapturing:
        _cancelQualityLock();
        if (event.zone case final InspectionZoneType zone) {
          _anomalyZones.add(zone);
          _scanSession.beginDamageDetail(zone);
          if (event.capture && event.evidenceStep == event.evidenceTotal) {
            _scanSession.completeZone(
              zone: zone,
              kind: ZoneCaptureKind.damageEvidence,
            );
          }
        }
      case ScanPhase.completed:
        _cancelQualityLock();
        _scheduleAutomaticCompletion();
    }
  }

  void _scheduleAutomaticCompletion() {
    if (_didReturnCompletion || _automaticCompletionTimer?.isActive == true) {
      return;
    }
    _automaticCompletionTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _didReturnCompletion || !_scanSession.isComplete) return;
      _didReturnCompletion = true;
      Navigator.of(context).pop(ScanCompletion.evidenceAndInteriorCaptured);
    });
  }

  void _startFastQualityLock(
    InspectionZoneType? zone, {
    required bool completeAfterLock,
  }) {
    if (zone == null || _scanSession.isZoneComplete(zone)) return;
    _cancelQualityLock();
    _scanSession.updateDetection(vehicleDetected: true, zone: zone);
    _scanSession.updateQualityLock(0);
    var step = 0;
    _fastLockTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step += 1;
      _scanSession.updateQualityLock(step / 10);
      if (step < 10) return;
      timer.cancel();
      if (completeAfterLock) _finishZone(zone);
    });
  }

  void _finishZone(InspectionZoneType? zone, {ScanFindingKind? finding}) {
    if (zone == null) return;
    _scanSession.completeZone(
      zone: zone,
      kind: finding == ScanFindingKind.stain
          ? ZoneCaptureKind.interiorEvidence
          : ZoneCaptureKind.normal,
    );
  }

  void _cancelQualityLock() {
    _fastLockTimer?.cancel();
    _fastLockTimer = null;
  }

  @override
  void dispose() {
    _cancelQualityLock();
    _automaticCompletionTimer?.cancel();
    _timelineController?.dispose();
    _scanSession.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _replay() async {
    _cancelQualityLock();
    _automaticCompletionTimer?.cancel();
    _automaticCompletionTimer = null;
    _didReturnCompletion = false;
    _handledEvent = null;
    _scanSession.reset();
    _anomalyZones.clear();
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

  void _showDemoController() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.scanSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
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
                '全車掃描 Demo 控制器',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                '同一段本機影片會依時間軸自動完成六區；長按 Prototype 標示可再次開啟控制器。',
                style: TextStyle(color: Color(0xFFB7BCC2)),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _replay,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('重播完整流程'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _jumpToNextEvent,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('下一事件'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timelineController;
    return ScanScaffold(
      title: '全車連續掃描',
      onPrototypeLongPress: _showDemoController,
      body: switch ((timeline, _loadError)) {
        (_, final Object error) => _LoadFailure(error: error),
        (null, _) => const Center(
          child: CircularProgressIndicator(color: AppColors.captureCyan),
        ),
        (final ScanTimelineController timeline, _) => AnimatedBuilder(
          animation: timeline,
          builder: (context, _) {
            final event = timeline.event;
            final currentZone = event.zone ?? _scanSession.detectedZone;
            final isInterior =
                currentZone == InspectionZoneType.frontSeat ||
                currentZone == InspectionZoneType.rearSeat;
            return FullVehicleScanHud(
              session: _scanSession,
              event: event,
              isInterior: isInterior,
              resultLabel: _scanSession.isComplete
                  ? '掃描完成，已記錄 2 處待確認影像'
                  : event.phase == ScanPhase.evidenceCapturing && event.capture
                  ? '已保存${_evidenceViewLabel(event.evidenceView)}視角'
                  : event.finding == ScanFindingKind.stain && event.capture
                  ? '已記錄後座污漬'
                  : event.phase == ScanPhase.captured && currentZone != null
                  ? '${currentZone.label}已自動擷取'
                  : null,
              resultDetail: _scanSession.isComplete
                  ? '左側疑似刮痕與後座污漬將在背景進行後續比對，正在開啟摘要'
                  : event.finding == ScanFindingKind.stain
                  ? '後座右側座墊，等待後續處理'
                  : null,
              resultIsAnomaly:
                  currentZone != null && _anomalyZones.contains(currentZone),
              video: LocalScanVideo(
                assetPath: _videoAsset,
                fallbackAsset: _fallbackAsset,
                controller: _videoController,
                onPositionChanged: timeline.updatePosition,
              ),
              onReplay: _replay,
              onStartDetail: null,
              anomalyZones: _anomalyZones,
            );
          },
        ),
      },
    );
  }

  String _evidenceViewLabel(EvidenceView? view) => switch (view) {
    EvidenceView.center => '中央',
    EvidenceView.left => '左側',
    EvidenceView.right => '右側',
    null => '補充',
  };
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
          '無法載入全車掃描腳本。請確認本機素材是否完整。\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.white),
        ),
      ),
    );
  }
}
