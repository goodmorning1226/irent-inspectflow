import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';
import '../../widgets/scan_scaffold.dart';
import '../scan/controllers/local_scan_video_controller.dart';
import '../scan/controllers/scan_timeline_controller.dart';
import '../scan/models/scan_timeline.dart';
import '../scan/widgets/local_scan_video.dart';
import '../scan/widgets/scan_guide_overlay.dart';

enum CompletionReviewResult { passed, needsMoreWork }

class CompletionReviewPage extends StatefulWidget {
  const CompletionReviewPage({super.key});

  @override
  State<CompletionReviewPage> createState() => _CompletionReviewPageState();
}

class _CompletionReviewPageState extends State<CompletionReviewPage> {
  CompletionReviewResult? _result;

  Future<void> _startRescan() async {
    final shouldStart =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.screen_rotation_rounded,
              color: AppColors.brandRed,
              size: 42,
            ),
            title: const Text('請將手機橫放'),
            content: const Text(
              '請對準原異常區域，系統會使用相同視角留下完工影像。',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('稍後再掃描'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('已橫放，開始'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted || !shouldStart) return;
    final result = await Navigator.of(context).push<CompletionReviewResult>(
      MaterialPageRoute<CompletionReviewResult>(
        builder: (_) => const CompletionRescanPage(),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return IrentFlowScaffold(
      title: '完工複檢',
      showBackButton: true,
      bottom: FilledButton.icon(
        onPressed: _startRescan,
        icon: const Icon(Icons.center_focus_strong_rounded),
        label: Text(_result == null ? '開始同區域重掃' : '重新掃描'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text('左後車門刮痕處理確認', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '員工完成處理後，依原異常位置與視角重新掃描。通過後才更新車輛狀態並保存新的可信基準。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/frames/exterior_damage_wide.png',
                    fit: BoxFit.cover,
                  ),
                  const Positioned(
                    left: AppSpacing.md,
                    top: AppSpacing.md,
                    child: _OriginalFindingLabel(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _CaseDetails(),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ReviewResultPanel(result: _result!),
          ],
        ],
      ),
    );
  }
}

class CompletionRescanPage extends StatefulWidget {
  const CompletionRescanPage({super.key});

  @override
  State<CompletionRescanPage> createState() => _CompletionRescanPageState();
}

class _CompletionRescanPageState extends State<CompletionRescanPage> {
  final LocalScanVideoController _videoController = LocalScanVideoController();
  ScanTimelineController? _timelineController;
  Object? _error;
  bool _passes = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTimeline());
  }

  Future<void> _loadTimeline() async {
    try {
      final source = await rootBundle.loadString(
        'assets/scripts/exterior_clean.json',
      );
      if (!mounted) return;
      setState(() {
        _timelineController = ScanTimelineController(
          ScanTimelineScript.fromJsonString(source),
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _toggleResult() {
    setState(() => _passes = !_passes);
  }

  Future<void> _replay() async {
    _timelineController?.reset();
    await _videoController.replay();
  }

  @override
  void dispose() {
    _timelineController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScanScaffold(
      title: '左側完工重掃',
      onPrototypeLongPress: _toggleResult,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Text(
          '完工素材載入失敗\n$_error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.white),
        ),
      );
    }
    final timeline = _timelineController;
    if (timeline == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.captureCyan),
      );
    }
    return AnimatedBuilder(
      animation: timeline,
      builder: (context, _) {
        final event = timeline.event;
        final captured = event.phase == ScanPhase.captured;
        final resultColor = _passes
            ? AppColors.successGreen
            : AppColors.warningOrange;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LocalScanVideo(
                        assetPath: 'assets/videos/exterior_clean.mp4',
                        fallbackAsset: 'assets/frames/exterior_clean_best.png',
                        controller: _videoController,
                        onPositionChanged: timeline.updatePosition,
                      ),
                      ScanGuideOverlay(event: event),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.scanSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          captured
                              ? _passes
                                    ? Icons.verified_rounded
                                    : Icons.build_circle_outlined
                              : Icons.center_focus_strong_rounded,
                          color: captured ? resultColor : AppColors.captureCyan,
                          size: 54,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          captured
                              ? _passes
                                    ? '複檢通過'
                                    : '仍需補充處理'
                              : event.prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          captured
                              ? _passes
                                    ? '已取得同區域完工影像，可更新車輛狀態。'
                                    : '保留目前車輛狀態並返回任務繼續處理。'
                              : '請對準原異常區域並保持穩定',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB7BCC2),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (captured) ...[
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(
                              _passes
                                  ? CompletionReviewResult.passed
                                  : CompletionReviewResult.needsMoreWork,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: resultColor,
                            ),
                            child: const Text('確認複檢結果'),
                          ),
                          TextButton.icon(
                            onPressed: _replay,
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('重新播放'),
                          ),
                        ] else
                          const Text(
                            '長按 Prototype 標示可切換複檢結果',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8F969D),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OriginalFindingLabel extends StatelessWidget {
  const _OriginalFindingLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '處理前影像・左後車門',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CaseDetails extends StatelessWidget {
  const _CaseDetails();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.divider),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            _CaseRow(label: '任務編號', value: 'TASK-DEMO-018'),
            Divider(height: AppSpacing.lg),
            _CaseRow(label: '處理區域', value: '左後車門下半部'),
            Divider(height: AppSpacing.lg),
            _CaseRow(label: '目前狀態', value: '等待完工複檢'),
          ],
        ),
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: AppColors.mutedInk)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ReviewResultPanel extends StatelessWidget {
  const _ReviewResultPanel({required this.result});

  final CompletionReviewResult result;

  @override
  Widget build(BuildContext context) {
    final passed = result == CompletionReviewResult.passed;
    final color = passed ? AppColors.successGreen : AppColors.warningOrange;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFF0F8F4) : const Color(0xFFFFF5EC),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              passed ? Icons.verified_rounded : Icons.pending_actions_rounded,
              color: color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                passed ? '複檢通過；完工影像可保存為下一次檢查基準。' : '仍需補充處理；任務保持開啟，車輛狀態暫不變更。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
