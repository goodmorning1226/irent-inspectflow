import 'package:flutter/material.dart';

import '../../mock/mock_inspection_data.dart';
import '../../models/inspection_session.dart';
import '../../models/inspection_zone.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';
import '../scan/models/scan_completion.dart';
import '../scan/scan_prototype_page.dart';
import '../scan/widgets/vehicle_coverage_map.dart';
import '../submission/inspection_summary_page.dart';

class InspectionEntryPage extends StatefulWidget {
  const InspectionEntryPage({super.key});

  @override
  State<InspectionEntryPage> createState() => _InspectionEntryPageState();
}

class _InspectionEntryPageState extends State<InspectionEntryPage> {
  late List<InspectionZone> _zones;
  bool _isOpeningScan = false;

  @override
  void initState() {
    super.initState();
    _resetInspection();
  }

  void _resetInspection() {
    _zones = List<InspectionZone>.of(MockInspectionData.currentSession.zones);
  }

  Future<void> _startScan() async {
    if (_isOpeningScan) return;
    setState(() => _isOpeningScan = true);
    final completion = await Navigator.of(context).push<ScanCompletion>(
      MaterialPageRoute<ScanCompletion>(
        builder: (_) => const ScanPrototypePage(),
      ),
    );
    if (!mounted) return;
    setState(() => _isOpeningScan = false);
    if (completion == null) return;

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

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InspectionSummaryPage(
          inspectionType: InspectionType.returnVehicle,
          zones: List.unmodifiable(_zones),
          onReset: () => setState(_resetInspection),
        ),
      ),
    );
    if (mounted) setState(_resetInspection);
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = MockInspectionData.currentSession.vehicle;

    return IrentFlowScaffold(
      title: '掃描',
      showBackButton: true,
      centerTitle: true,
      appBarProgress: 0.27,
      appBarActions: [
        IconButton(
          tooltip: '聯絡客服',
          onPressed: () {},
          icon: const Icon(Icons.headset_mic_outlined),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      bottomHasDivider: false,
      bottomColor: AppColors.surface,
      bottom: FilledButton(
        key: const Key('enter-inspection-button'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
        onPressed: _isOpeningScan ? null : _startScan,
        child: const Text('掃描車輛狀況'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                34,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Text(
                    '檢查車輛狀況',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '請仔細檢查有無損傷、凹陷等，\n完整掃描可保障自身權益。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _VehicleStrip(
                    plateNumber: vehicle.plateNumber,
                    modelName: vehicle.modelName,
                  ),
                  const SizedBox(height: 20),
                  _InitialCoverageCard(zones: _zones),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleStrip extends StatelessWidget {
  const _VehicleStrip({required this.plateNumber, required this.modelName});

  final String plateNumber;
  final String modelName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('entry-vehicle-card'),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
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
              '0 / 6 已完成',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialCoverageCard extends StatelessWidget {
  const _InitialCoverageCard({required this.zones});

  final List<InspectionZone> zones;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '車頭、左側、車尾、右側、前座及後座六區皆待掃描',
      child: Padding(
        key: const Key('entry-coverage-card'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 260,
            child: VehicleCoverageMap(
              zones: zones,
              activeZone: null,
              suggestedZone: null,
              light: true,
            ),
          ),
        ),
      ),
    );
  }
}
