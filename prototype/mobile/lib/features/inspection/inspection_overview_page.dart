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
  const InspectionOverviewPage({
    this.inspectionType = InspectionType.returnVehicle,
    this.initialZones,
    super.key,
  });

  final InspectionType inspectionType;
  final List<InspectionZone>? initialZones;

  @override
  State<InspectionOverviewPage> createState() => _InspectionOverviewPageState();
}

class _InspectionOverviewPageState extends State<InspectionOverviewPage> {
  late List<InspectionZone> _zones;
  InspectionZoneType? _selectedType;

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
      _selectedType = null;
    });
  }

  void _openSummary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InspectionSummaryPage(
          inspectionType: widget.inspectionType,
          zones: List.unmodifiable(_zones),
          onReset: _resetDemo,
        ),
      ),
    );
  }

  InspectionZone? get _selectedZone {
    if (_selectedType == null) return null;
    return _zones.firstWhere((zone) => zone.type == _selectedType);
  }

  void _selectZone(InspectionZone zone) {
    setState(() {
      _selectedType = zone.type;
      for (var index = 0; index < _zones.length; index++) {
        final current = _zones[index];
        if (current.status == ZoneStatus.selected) {
          _zones[index] = current.copyWith(status: ZoneStatus.notStarted);
        }
      }
      if (zone.status == ZoneStatus.notStarted) {
        final index = _zones.indexWhere((item) => item.type == zone.type);
        _zones[index] = zone.copyWith(status: ZoneStatus.selected);
      }
    });
  }

  Future<void> _openSelectedZone() async {
    final zone = _selectedZone;
    if (zone == null) return;

    if (zone.hasRecordedImage) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ZoneSummaryPage(zone: zone)),
      );
      return;
    }

    final shouldStart = await _showOrientationPrompt(zone);
    if (!mounted || !shouldStart) return;
    final completion = await Navigator.of(context).push<ScanCompletion>(
      MaterialPageRoute<ScanCompletion>(
        builder: (_) => ScanPrototypePage(zone: zone),
      ),
    );
    if (!mounted || completion == null) return;
    final index = _zones.indexWhere((item) => item.type == zone.type);
    setState(() {
      _zones[index] = _zones[index].copyWith(
        status: ZoneStatus.completed,
        completedAt: '剛剛完成',
        qualitySummary: switch (completion) {
          ScanCompletion.clean => '位置、清晰度與曝光均符合標準',
          ScanCompletion.evidenceCaptured => '已取得廣角與三個近距離補充影像',
          ScanCompletion.interiorEvidenceCaptured => '已記錄後座污漬，等待後續處理',
        },
      );
      _selectedType = zone.type;
    });
  }

  Future<bool> _showOrientationPrompt(InspectionZone zone) async {
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
              '接下來將以橫向畫面掃描${zone.type.label}，較寬的取景範圍能完整保留車況。',
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
    final selectedZone = _selectedZone;
    final allCompleted = completedCount == _zones.length;

    return IrentFlowScaffold(
      title: widget.inspectionType == InspectionType.pickup
          ? '確認取車車況'
          : '確認還車車況',
      showBackButton: true,
      bottom: FilledButton(
        key: const Key('zone-primary-action'),
        onPressed: allCompleted
            ? _openSummary
            : selectedZone == null
            ? null
            : _openSelectedZone,
        child: Text(allCompleted ? '查看六區檢查摘要' : _actionLabel(selectedZone)),
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
          Text('選擇要確認的區域', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.inspectionType == InspectionType.pickup
                ? '取車前確認六個區域，建立本次租借的車況基準；左側與後座等待本次掃描。'
                : '六個區域都會留下標準化影像。已完成的區域可回看；左側與後座等待本次掃描。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ZoneTrack(
            zones: _zones,
            selectedType: _selectedType,
            onSelected: _selectZone,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ScanExplanation(),
        ],
      ),
    );
  }

  String _actionLabel(InspectionZone? zone) {
    if (zone == null) return '請先選擇區域';
    if (zone.hasRecordedImage) return '查看${zone.type.label}影像';
    return '開始${zone.type.label}掃描';
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
                color: AppColors.successGreen,
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
  const _ZoneTrack({
    required this.zones,
    required this.selectedType,
    required this.onSelected,
  });

  final List<InspectionZone> zones;
  final InspectionZoneType? selectedType;
  final ValueChanged<InspectionZone> onSelected;

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
                  isSelected: selectedType == zone.type,
                  onTap: () => onSelected(zone),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.zone,
    required this.isSelected,
    required this.onTap,
  });

  final InspectionZone zone;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visualStatus = isSelected && zone.status == ZoneStatus.notStarted
        ? ZoneStatus.selected
        : zone.status;
    final colors = _ZoneColors.fromStatus(visualStatus);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${zone.type.label}，${visualStatus.label}',
      child: Material(
        color: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.border, width: isSelected ? 2 : 1),
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
                      : Icons.chevron_right_rounded,
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
