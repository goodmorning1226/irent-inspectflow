import 'package:flutter/material.dart';

import '../../models/mobile_inspection_result.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';

class SubmissionCompletePage extends StatelessWidget {
  const SubmissionCompletePage({
    required this.result,
    required this.onReset,
    super.key,
  });

  final MobileInspectionResult result;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return IrentFlowScaffold(
      title: '車況紀錄完成',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                onReset();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('返回 iRent 還車流程'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: AppColors.successGreen,
            size: 76,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '車況影像已完成記錄',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '系統將在背景完成歷史影像比對與車況判讀。您不需要留在原地等待，後續若需要補充資料，將再透過既有 iRent 流程通知。',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _CompleteRow(label: '檢查編號', value: result.session.id),
                  const Divider(height: AppSpacing.lg),
                  _CompleteRow(
                    label: '影像區域',
                    value: '${result.zones.length} / 6',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _CompleteRow(
                    label: '後續確認',
                    value: result.findings.isEmpty
                        ? '目前無待確認項目'
                        : '${result.findings.length} 項，將由系統處理',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteRow extends StatelessWidget {
  const _CompleteRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
