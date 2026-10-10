import 'package:flutter/material.dart';

import '../../models/inspection_zone.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';

class ZoneSummaryPage extends StatelessWidget {
  const ZoneSummaryPage({required this.zone, super.key});

  final InspectionZone zone;

  @override
  Widget build(BuildContext context) {
    return IrentFlowScaffold(
      title: '${zone.type.label}影像',
      showBackButton: true,
      bottom: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('返回六區總覽'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      zone.type.icon,
                      size: 104,
                      color: const Color(0xFF9A9DA1),
                    ),
                  ),
                  const Positioned(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: _ImageLabel(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('影像品質合格', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryRow(label: '拍攝區域', value: zone.type.label),
          const Divider(height: 1),
          _SummaryRow(label: '完成時間', value: zone.completedAt ?? '固定示範時間'),
          const Divider(height: 1),
          _SummaryRow(
            label: '品質摘要',
            value: zone.qualitySummary ?? '位置與畫面品質符合標準',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '此頁使用固定假資料呈現已完成區域，不會播放掃描影片或執行 AI 判讀。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _ImageLabel extends StatelessWidget {
  const _ImageLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'Prototype 固定影像',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
