import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ScanScaffold extends StatefulWidget {
  const ScanScaffold({
    required this.title,
    required this.body,
    super.key,
    this.bottom,
    this.onPrototypeLongPress,
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final VoidCallback? onPrototypeLongPress;

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
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            widget.body,
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              left: AppSpacing.md,
              child: GestureDetector(
                key: const Key('scan-back-long-press-target'),
                onLongPress: widget.onPrototypeLongPress,
                child: const _FloatingBackButton(),
              ),
            ),
            if (widget.bottom != null)
              Positioned(left: 0, right: 0, bottom: 0, child: widget.bottom!),
          ],
        ),
      ),
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  const _FloatingBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        key: const Key('scan-back-button'),
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded, semanticLabel: '返回上一步'),
        color: AppColors.white,
      ),
    );
  }
}
