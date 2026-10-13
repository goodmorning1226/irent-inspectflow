import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class IrentFlowScaffold extends StatelessWidget {
  const IrentFlowScaffold({
    required this.title,
    required this.body,
    super.key,
    this.bottom,
    this.showBackButton = false,
    this.showIrentBrand = false,
    this.centerTitle = false,
    this.appBarActions,
    this.appBarProgress,
    this.bottomHasDivider = true,
    this.bottomColor = AppColors.white,
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final bool showBackButton;
  final bool showIrentBrand;
  final bool centerTitle;
  final List<Widget>? appBarActions;
  final double? appBarProgress;
  final bool bottomHasDivider;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.white,
        systemNavigationBarColor: AppColors.white,
      ),
      child: ColoredBox(
        color: AppColors.canvas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.white,
                surfaceTintColor: AppColors.white,
                elevation: 0,
                leading: showBackButton
                    ? IconButton(
                        tooltip: '返回',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      )
                    : null,
                titleSpacing: showBackButton ? 0 : AppSpacing.lg,
                centerTitle: centerTitle,
                title: showIrentBrand ? const _IrentBrandTitle() : Text(title),
                actions: appBarActions,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(
                    appBarProgress == null ? 1 : 4,
                  ),
                  child: appBarProgress == null
                      ? const Divider(height: 1)
                      : _FlowProgress(value: appBarProgress!),
                ),
              ),
              body: SafeArea(top: false, child: body),
              bottomNavigationBar: bottom == null
                  ? null
                  : SafeArea(
                      top: false,
                      child: ColoredBox(
                        color: bottomColor,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: bottomHasDivider
                                ? const Border(
                                    top: BorderSide(color: AppColors.divider),
                                  )
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                            ),
                            child: bottom,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowProgress extends StatelessWidget {
  const _FlowProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.divider),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: const ColoredBox(color: AppColors.brandRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _IrentBrandTitle extends StatelessWidget {
  const _IrentBrandTitle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'iRent',
      child: FittedBox(
        key: const Key('irent-brand-title'),
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              size: 24,
              color: AppColors.brandRed,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'iRent',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
