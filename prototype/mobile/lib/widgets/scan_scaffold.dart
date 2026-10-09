import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'prototype_banner.dart';

class ScanScaffold extends StatefulWidget {
  const ScanScaffold({
    required this.title,
    required this.body,
    super.key,
    this.bottom,
  });

  final String title;
  final Widget body;
  final Widget? bottom;

  @override
  State<ScanScaffold> createState() => _ScanScaffoldState();
}

class _ScanScaffoldState extends State<ScanScaffold> {
  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.scanBackground,
        systemNavigationBarColor: AppColors.scanBackground,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scanBackground,
        appBar: AppBar(
          backgroundColor: AppColors.scanBackground,
          foregroundColor: AppColors.white,
          surfaceTintColor: AppColors.scanBackground,
          title: Text(widget.title),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Center(child: PrototypeBanner(dark: true)),
            ),
          ],
        ),
        body: SafeArea(top: false, child: widget.body),
        bottomNavigationBar: widget.bottom,
      ),
    );
  }
}
