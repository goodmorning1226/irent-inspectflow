import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../mock/mock_inspection_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';

class InspectionEntryPage extends StatelessWidget {
  const InspectionEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = MockInspectionData.currentSession;

    return IrentFlowScaffold(
      title: '確認還車車況',
      bottom: FilledButton(
        key: const Key('enter-inspection-button'),
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.inspection),
        child: const Text('進入車況檢查'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            '還車前，先留下清楚的車況紀錄',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '開啟一次掃描後，InspectFlow 會自動辨識車外四側與車內前後座，逐區確認品質並保存影像。',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xl),
          _VehiclePanel(
            plateNumber: session.vehicle.plateNumber,
            modelName: session.vehicle.modelName,
            colorName: session.vehicle.colorName,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReturnDetails(
            location: session.order.returnLocation,
            timeLabel: session.order.returnTimeLabel,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _InspectionNotice(),
        ],
      ),
    );
  }
}

class _VehiclePanel extends StatelessWidget {
  const _VehiclePanel({
    required this.plateNumber,
    required this.modelName,
    required this.colorName,
  });

  final String plateNumber;
  final String modelName;
  final String colorName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '車輛 $plateNumber，$modelName，$colorName',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 48,
                    color: AppColors.brandRed,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          plateNumber,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(letterSpacing: 0.6),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '$modelName・$colorName',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.mutedInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandRed,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnDetails extends StatelessWidget {
  const _ReturnDetails({required this.location, required this.timeLabel});

  final String location;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: '還車地點',
              value: location,
            ),
            const Divider(height: 1, indent: 44),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: '還車時間',
              value: timeLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Icon(icon, size: 20, color: AppColors.mutedInk),
          ),
          SizedBox(
            width: 72,
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

class _InspectionNotice extends StatelessWidget {
  const _InspectionNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: AppColors.mutedInk,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '目前為 Prototype 模擬流程。還車掃描會依序展示車頭、車尾、左右側與前後座六區。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
          ),
        ),
      ],
    );
  }
}
