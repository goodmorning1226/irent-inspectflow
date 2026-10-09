import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'prototype_banner.dart';

class IrentFlowScaffold extends StatelessWidget {
  const IrentFlowScaffold({
    required this.title,
    required this.body,
    super.key,
    this.bottom,
    this.showBackButton = false,
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final bool showBackButton;

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
                title: Text(title),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Center(child: PrototypeBanner()),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1),
                ),
              ),
              body: SafeArea(top: false, child: body),
              bottomNavigationBar: bottom == null
                  ? null
                  : SafeArea(
                      top: false,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            top: BorderSide(color: AppColors.divider),
                          ),
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
    );
  }
}
