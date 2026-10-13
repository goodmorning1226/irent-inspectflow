import 'package:flutter/material.dart';

import '../../mock/mock_inspection_data.dart';
import '../../models/inspection_session.dart';
import '../../models/inspection_zone.dart';
import '../../models/mobile_inspection_result.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';
import 'inspection_upload_page.dart';

class InspectionSummaryPage extends StatelessWidget {
  const InspectionSummaryPage({
    required this.inspectionType,
    required this.zones,
    required this.onReset,
    super.key,
  });

  final InspectionType inspectionType;
  final List<InspectionZone> zones;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final result = MockInspectionOutput.build(
      session: MockInspectionData.currentSession,
      inspectionType: inspectionType,
      zones: zones,
    );
    return IrentFlowScaffold(
      title: '檢查摘要',
      showBackButton: true,
      bottom: FilledButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                InspectionUploadPage(result: result, onReset: onReset),
          ),
        ),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('確認並上傳車況紀錄'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            '六個區域均已留下可判讀影像',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < zones.length; index++) ...[
                  _ZoneSummaryRow(zone: zones[index]),
                  if (index != zones.length - 1)
                    const Divider(height: 1, indent: 54),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneSummaryRow extends StatelessWidget {
  const _ZoneSummaryRow({required this.zone});

  final InspectionZone zone;

  bool get _needsFollowUp => zone.qualitySummary?.contains('等待後續處理') ?? false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _needsFollowUp
        ? AppColors.warningOrange
        : AppColors.successGreen;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(zone.type.icon, color: AppColors.ink, size: 24),
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
                  zone.qualitySummary ?? '影像品質符合標準',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            _needsFollowUp
                ? Icons.pending_actions_rounded
                : Icons.check_circle_rounded,
            color: statusColor,
            size: 22,
          ),
        ],
      ),
    );
  }
}
