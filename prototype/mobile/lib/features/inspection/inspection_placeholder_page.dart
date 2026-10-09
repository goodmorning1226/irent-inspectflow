import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/irent_flow_scaffold.dart';

class InspectionPlaceholderPage extends StatelessWidget {
  const InspectionPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return IrentFlowScaffold(
      title: '車況檢查',
      showBackButton: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                size: 64,
                color: AppColors.brandRed,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '準備建立六區車況總覽',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '本階段只完成應用程式骨架；六區選擇將在第 2 階段實作。',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
