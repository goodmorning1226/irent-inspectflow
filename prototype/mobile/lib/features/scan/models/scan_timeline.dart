import 'dart:convert';

enum ScanPhase { waiting, aligning, stable, captured, detailRequired }

class NormalizedScanBox {
  const NormalizedScanBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory NormalizedScanBox.fromJson(Map<String, dynamic> json) {
    return NormalizedScanBox(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  final double left;
  final double top;
  final double width;
  final double height;
}

class ScanTimelineEvent {
  const ScanTimelineEvent({
    required this.at,
    required this.phase,
    required this.prompt,
    required this.quality,
    required this.capture,
    this.box,
    this.anomalyBox,
  });

  factory ScanTimelineEvent.fromJson(Map<String, dynamic> json) {
    final phaseName = json['phase'] as String;
    return ScanTimelineEvent(
      at: Duration(milliseconds: json['atMs'] as int),
      phase: ScanPhase.values.byName(phaseName),
      prompt: json['prompt'] as String,
      quality: (json['quality'] as num).toDouble().clamp(0, 1),
      capture: json['capture'] as bool? ?? false,
      box: switch (json['box']) {
        final Map<String, dynamic> box => NormalizedScanBox.fromJson(box),
        _ => null,
      },
      anomalyBox: switch (json['anomalyBox']) {
        final Map<String, dynamic> box => NormalizedScanBox.fromJson(box),
        _ => null,
      },
    );
  }

  final Duration at;
  final ScanPhase phase;
  final String prompt;
  final double quality;
  final bool capture;
  final NormalizedScanBox? box;
  final NormalizedScanBox? anomalyBox;
}

class ScanTimelineScript {
  ScanTimelineScript({
    required this.scenarioId,
    required this.duration,
    required List<ScanTimelineEvent> events,
  }) : events = List.unmodifiable(
         events..sort((a, b) => a.at.compareTo(b.at)),
       ) {
    if (this.events.isEmpty) {
      throw const FormatException('A scan timeline needs at least one event.');
    }
  }

  factory ScanTimelineScript.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>;
    return ScanTimelineScript(
      scenarioId: json['scenarioId'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      events: rawEvents
          .map(
            (event) => ScanTimelineEvent.fromJson(
              Map<String, dynamic>.from(event as Map),
            ),
          )
          .toList(),
    );
  }

  factory ScanTimelineScript.fromJsonString(String source) {
    return ScanTimelineScript.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  final String scenarioId;
  final Duration duration;
  final List<ScanTimelineEvent> events;

  ScanTimelineEvent eventAt(Duration position) {
    var result = events.first;
    for (final event in events) {
      if (event.at > position) break;
      result = event;
    }
    return result;
  }

  ScanTimelineEvent? nextEventAfter(Duration position) {
    for (final event in events) {
      if (event.at > position) return event;
    }
    return null;
  }
}
