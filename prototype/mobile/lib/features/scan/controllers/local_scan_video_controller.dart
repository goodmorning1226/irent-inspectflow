import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class LocalScanVideoController extends ChangeNotifier {
  VideoPlayerController? _player;

  VideoPlayerController? get player => _player;

  void attach(VideoPlayerController player) {
    _player = player;
    notifyListeners();
  }

  void detach(VideoPlayerController player) {
    if (!identical(_player, player)) return;
    _player = null;
  }

  Future<void> replay() async {
    final player = _player;
    if (player == null) return;
    await player.seekTo(Duration.zero);
    await player.play();
  }

  Future<void> seekTo(Duration position) async {
    final player = _player;
    if (player == null) return;
    await player.seekTo(position);
    if (!player.value.isPlaying) await player.play();
  }

  Future<void> reset() async {
    final player = _player;
    if (player == null) return;
    await player.pause();
    await player.seekTo(Duration.zero);
  }

  void play() {
    final player = _player;
    if (player != null) unawaited(player.play());
  }

  void pause() {
    final player = _player;
    if (player != null) unawaited(player.pause());
  }
}
