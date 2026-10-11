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
      showIrentBrand: true,
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
          Text('還車階段', style: Theme.of(context).textTheme.headlineMedium),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.mutedInk),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
