import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PrototypeBanner extends StatelessWidget {
  const PrototypeBanner({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? AppColors.white : AppColors.brandRedDark;
    final background = dark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.brandRed.withValues(alpha: 0.08);

    return Semantics(
      label: 'Prototype 模擬結果，非正式 AI 判讀',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: foreground.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Text(
            'Prototype 模擬結果',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
