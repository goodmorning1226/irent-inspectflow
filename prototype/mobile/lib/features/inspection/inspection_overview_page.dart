import 'package:flutter/material.dart';

import '../../mock/mock_inspection_data.dart';
import '../../models/inspection_zone.dart';
import '../../models/inspection_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';
import '../scan/models/scan_completion.dart';
import '../scan/scan_prototype_page.dart';
import '../submission/inspection_summary_page.dart';
import 'zone_summary_page.dart';

class InspectionOverviewPage extends StatefulWidget {
  const InspectionOverviewPage({this.initialZones, super.key});

  final List<InspectionZone>? initialZones;

  @override
  State<InspectionOverviewPage> createState() => _InspectionOverviewPageState();
}

class _InspectionOverviewPageState extends State<InspectionOverviewPage> {
  late List<InspectionZone> _zones;

  @override
  void initState() {
    super.initState();
    _zones = List<InspectionZone>.of(
      widget.initialZones ?? MockInspectionData.currentSession.zones,
    );
  }

  void _resetDemo() {
    setState(() {
      _zones = List<InspectionZone>.of(MockInspectionData.currentSession.zones);
    });
  }

  void _openSummary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InspectionSummaryPage(
          inspectionType: InspectionType.returnVehicle,
          zones: List.unmodifiable(_zones),
          onReset: _resetDemo,
        ),
      ),
    );
  }

  Future<void> _openFullScan() async {
    final shouldStart = await _showOrientationPrompt();
    if (!mounted || !shouldStart) return;
    final completion = await Navigator.of(context).push<ScanCompletion>(
      MaterialPageRoute<ScanCompletion>(
        builder: (_) => const ScanPrototypePage(),
      ),
    );
    if (!mounted || completion == null) return;
    setState(() {
      _zones = _zones
          .map(
            (zone) => zone.copyWith(
              status: ZoneStatus.completed,
              completedAt: '剛剛完成',
              qualitySummary:
                  (completion == ScanCompletion.evidenceCaptured ||
                          completion ==
                              ScanCompletion.evidenceAndInteriorCaptured) &&
                      zone.type == InspectionZoneType.leftSide
                  ? '發現疑似刮痕，已取得廣角與三個補充影像，等待後續處理'
                  : (completion == ScanCompletion.interiorEvidenceCaptured ||
                            completion ==
                                ScanCompletion.evidenceAndInteriorCaptured) &&
                        zone.type == InspectionZoneType.rearSeat
                  ? '已記錄後座右側座墊污漬，等待後續處理'
                  : '位置、清晰度與曝光均符合標準',
            ),
          )
          .toList(growable: false);
    });
    await Future<void>.delayed(Duration.zero);
    if (mounted) _openSummary();
  }

  Future<void> _openZoneSummary(InspectionZone zone) async {
    if (!zone.hasRecordedImage) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ZoneSummaryPage(zone: zone)),
    );
  }

  Future<bool> _showOrientationPrompt() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.screen_rotation_rounded,
              color: AppColors.brandRed,
              size: 42,
            ),
            title: const Text('請將手機橫放'),
            content: Text(
              '接下來會以橫向畫面連續掃描全車。系統會自動辨識目前區域，完成後直接引導您移動到下一區。',
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
  }

  @override
  Widget build(BuildContext context) {
    final session = MockInspectionData.currentSession;
    final completedCount = _zones
        .where((zone) => zone.status == ZoneStatus.completed)
        .length;
    final allCompleted = completedCount == _zones.length;

    return IrentFlowScaffold(
      title: '確認還車車況',
      showBackButton: true,
      bottom: FilledButton(
        key: const Key('zone-primary-action'),
        onPressed: allCompleted ? _openSummary : _openFullScan,
        child: Text(allCompleted ? '查看六區檢查摘要' : '開始全車掃描'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _VehicleStrip(
            plateNumber: session.vehicle.plateNumber,
            modelName: session.vehicle.modelName,
            completedCount: completedCount,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('一次掃描，系統自動辨識六區', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '開啟掃描後直接繞車並查看車內，系統會自動辨識六個區域、鎖定品質並逐區保存影像。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ZoneTrack(zones: _zones, onOpenSummary: _openZoneSummary),
          const SizedBox(height: AppSpacing.lg),
          const _ScanExplanation(),
        ],
      ),
    );
  }
}

class _VehicleStrip extends StatelessWidget {
  const _VehicleStrip({
    required this.plateNumber,
    required this.modelName,
    required this.completedCount,
  });

  final String plateNumber;
  final String modelName;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.brandRed,
              size: 34,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plateNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    modelName,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
                  ),
                ],
              ),
            ),
            Text(
              '$completedCount / 6 已完成',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: completedCount == 0
                    ? AppColors.mutedInk
                    : AppColors.successGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneTrack extends StatelessWidget {
  const _ZoneTrack({required this.zones, required this.onOpenSummary});

  final List<InspectionZone> zones;
  final ValueChanged<InspectionZone> onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final zone in zones)
              SizedBox(
                width: itemWidth,
                child: _ZoneTile(
                  zone: zone,
                  onTap: zone.hasRecordedImage
                      ? () => onOpenSummary(zone)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.zone, required this.onTap});

  final InspectionZone zone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visualStatus = zone.status;
    final colors = _ZoneColors.fromStatus(visualStatus);

    return Semantics(
      button: onTap != null,
      label: '${zone.type.label}，${visualStatus.label}',
      child: Material(
        color: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('zone-${zone.type.name}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(zone.type.icon, color: colors.foreground, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.type.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        visualStatus.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  visualStatus == ZoneStatus.completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: colors.foreground,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneColors {
  const _ZoneColors(this.background, this.border, this.foreground);

  final Color background;
  final Color border;
  final Color foreground;

  factory _ZoneColors.fromStatus(ZoneStatus status) => switch (status) {
    ZoneStatus.notStarted => const _ZoneColors(
      AppColors.white,
      AppColors.divider,
      AppColors.mutedInk,
    ),
    ZoneStatus.selected => const _ZoneColors(
      Color(0xFFFFF4F4),
      AppColors.brandRed,
      AppColors.brandRed,
    ),
    ZoneStatus.completed => const _ZoneColors(
      Color(0xFFF0F8F4),
      Color(0xFFB9DDCC),
      AppColors.successGreen,
    ),
    ZoneStatus.rescanRequired => const _ZoneColors(
      Color(0xFFFFF5EC),
      Color(0xFFF3C59E),
      AppColors.warningOrange,
    ),
  };
}

class _ScanExplanation extends StatelessWidget {
  const _ScanExplanation();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.center_focus_strong, color: AppColors.brandRed),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '掃描會即時確認位置與影像品質，符合標準後自動保存；只有發現疑似異常時才會要求補掃。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
