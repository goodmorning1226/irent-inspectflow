import 'package:flutter/foundation.dart';

import '../models/scan_timeline.dart';

class ScanTimelineController extends ChangeNotifier {
  ScanTimelineController(this.script) : _event = script.events.first;

  final ScanTimelineScript script;
  late ScanTimelineEvent _event;
  Duration _position = Duration.zero;

  ScanTimelineEvent get event => _event;
  Duration get position => _position;

  void updatePosition(Duration position) {
    _position = position;
    final next = script.eventAt(position);
    if (identical(next, _event)) return;
    _event = next;
    notifyListeners();
  }

  void reset() {
    _position = Duration.zero;
    _event = script.events.first;
    notifyListeners();
  }
}
