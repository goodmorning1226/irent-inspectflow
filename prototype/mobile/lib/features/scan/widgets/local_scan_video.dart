import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../theme/app_colors.dart';
import '../controllers/local_scan_video_controller.dart';

class LocalScanVideo extends StatefulWidget {
  const LocalScanVideo({
    required this.assetPath,
    required this.controller,
    required this.onPositionChanged,
    this.fallbackAsset,
    super.key,
  });

  final String assetPath;
  final LocalScanVideoController controller;
  final ValueChanged<Duration> onPositionChanged;
  final String? fallbackAsset;

  @override
  State<LocalScanVideo> createState() => _LocalScanVideoState();
}

class _LocalScanVideoState extends State<LocalScanVideo> {
  late final VideoPlayerController _player;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.asset(widget.assetPath)
      ..addListener(_handlePlaybackUpdate);
    widget.controller.attach(_player);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _player.initialize();
      await _player.setLooping(false);
      await _player.setVolume(0);
      if (!mounted) return;
      setState(() {});
      await _player.play();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _handlePlaybackUpdate() {
    widget.onPositionChanged(_player.value.position);
  }

  @override
  void dispose() {
    widget.controller.detach(_player);
    _player
      ..removeListener(_handlePlaybackUpdate)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _VideoFallback(
        assetPath: widget.fallbackAsset,
        message: '影片無法播放，顯示擷取影格',
      );
    }

    if (!_player.value.isInitialized) {
      return _VideoFallback(
        assetPath: widget.fallbackAsset,
        showProgress: true,
      );
    }

    return ColoredBox(
      color: AppColors.scanSurface,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _player.value.size.width,
            height: _player.value.size.height,
            child: VideoPlayer(_player),
          ),
        ),
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback({
    required this.assetPath,
    this.message,
    this.showProgress = false,
  });

  final String? assetPath;
  final String? message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scanSurface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (assetPath != null)
            Image.asset(assetPath!, fit: BoxFit.cover)
          else
            const ColoredBox(color: AppColors.scanSurface),
          if (showProgress || message != null)
            ColoredBox(color: AppColors.ink.withValues(alpha: 0.34)),
          if (showProgress)
            const Center(
              child: CircularProgressIndicator(color: AppColors.captureCyan),
            ),
          if (message != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      message!,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
