import 'package:flutter/foundation.dart';

import '../../../models/inspection_zone.dart';

enum FullVehicleScanPhase {
  searchingVehicle,
  trackingZone,
  qualityLocking,
  zoneCaptured,
  moveGuidance,
  damageDetail,
  interiorTransition,
  completed,
}

enum ZoneCaptureKind { normal, damageEvidence, interiorEvidence }

class FullVehicleScanController extends ChangeNotifier {
  FullVehicleScanController({required List<InspectionZone> initialZones})
    : _zones = _normalizeZones(initialZones),
      _suggestedZone = recommendedOrder.first;

  static const recommendedOrder = <InspectionZoneType>[
    InspectionZoneType.rightSide,
    InspectionZoneType.front,
    InspectionZoneType.leftSide,
    InspectionZoneType.rear,
    InspectionZoneType.frontSeat,
    InspectionZoneType.rearSeat,
  ];

  List<InspectionZone> _zones;
  FullVehicleScanPhase _phase = FullVehicleScanPhase.searchingVehicle;
  bool _vehicleDetected = false;
  InspectionZoneType? _detectedZone;
  InspectionZoneType? _suggestedZone;
  double _lockProgress = 0;

  List<InspectionZone> get zones => List.unmodifiable(_zones);
  FullVehicleScanPhase get phase => _phase;
  bool get vehicleDetected => _vehicleDetected;
  InspectionZoneType? get detectedZone => _detectedZone;
  InspectionZoneType? get suggestedZone => _suggestedZone;
  double get lockProgress => _lockProgress;
  int get completedCount =>
      _zones.where((zone) => zone.status == ZoneStatus.completed).length;
  bool get isComplete => completedCount == InspectionZoneType.values.length;

  String get prompt => switch (_phase) {
    FullVehicleScanPhase.searchingVehicle => '尚未偵測到車輛，請將鏡頭對準車身',
    FullVehicleScanPhase.trackingZone =>
      _detectedZone == null ? '正在辨識目前掃描區域' : '已辨識${_detectedZone!.label}，請調整位置',
    FullVehicleScanPhase.qualityLocking =>
      '已辨識${_detectedZone?.label ?? '車輛'}，請保持穩定',
    FullVehicleScanPhase.zoneCaptured => '${_detectedZone?.label ?? '此區域'}掃描完成',
    FullVehicleScanPhase.moveGuidance =>
      _suggestedZone == null ? '六區掃描完成' : '請移動至${_suggestedZone!.label}繼續掃描',
    FullVehicleScanPhase.damageDetail => '請靠近疑似異常位置完成補充掃描',
    FullVehicleScanPhase.interiorTransition => '請開啟車門，接著掃描前座與後座',
    FullVehicleScanPhase.completed => '六區掃描完成，可以查看檢查摘要',
  };

  void updateDetection({
    required bool vehicleDetected,
    InspectionZoneType? zone,
  }) {
    if (!vehicleDetected) {
      _vehicleDetected = false;
      _detectedZone = null;
      _lockProgress = 0;
      _phase = FullVehicleScanPhase.searchingVehicle;
      notifyListeners();
      return;
    }

    _vehicleDetected = true;
    _detectedZone = zone;
    _lockProgress = 0;

    if (zone != null && isZoneComplete(zone)) {
      _suggestedZone = _nextIncompleteAfter(zone);
      _phase = FullVehicleScanPhase.moveGuidance;
    } else {
      _phase = FullVehicleScanPhase.trackingZone;
    }
    notifyListeners();
  }

  void updateQualityLock(double progress) {
    final zone = _detectedZone;
    if (!_vehicleDetected || zone == null || isZoneComplete(zone)) return;
    _lockProgress = progress.clamp(0, 1);
    _phase = FullVehicleScanPhase.qualityLocking;
    notifyListeners();
  }

  void beginDamageDetail(InspectionZoneType zone) {
    if (isZoneComplete(zone)) return;
    _vehicleDetected = true;
    _detectedZone = zone;
    _lockProgress = 0;
    _phase = FullVehicleScanPhase.damageDetail;
    notifyListeners();
  }

  void beginInteriorTransition() {
    if (isComplete) return;
    _vehicleDetected = false;
    _detectedZone = null;
    _lockProgress = 0;
    _phase = FullVehicleScanPhase.interiorTransition;
    notifyListeners();
  }

  bool completeZone({
    InspectionZoneType? zone,
    ZoneCaptureKind kind = ZoneCaptureKind.normal,
    String completedAt = '剛剛完成',
  }) {
    final target = zone ?? _detectedZone;
    if (target == null || isZoneComplete(target)) return false;

    final index = _zones.indexWhere((item) => item.type == target);
    _zones[index] = InspectionZone(
      type: target,
      status: ZoneStatus.completed,
      completedAt: completedAt,
      qualitySummary: switch (kind) {
        ZoneCaptureKind.normal => '位置、清晰度與曝光均符合標準',
        ZoneCaptureKind.damageEvidence => '已取得廣角與多角度補充影像',
        ZoneCaptureKind.interiorEvidence => '已記錄車內污損，等待後續處理',
      },
    );
    _detectedZone = target;
    _lockProgress = 1;
    _suggestedZone = _nextIncompleteAfter(target);
    _phase = isComplete
        ? FullVehicleScanPhase.completed
        : FullVehicleScanPhase.zoneCaptured;
    notifyListeners();
    return true;
  }

  void showMoveGuidance() {
    if (isComplete) {
      _phase = FullVehicleScanPhase.completed;
    } else {
      _vehicleDetected = false;
      _detectedZone = null;
      _lockProgress = 0;
      _phase = FullVehicleScanPhase.moveGuidance;
    }
    notifyListeners();
  }

  bool isZoneComplete(InspectionZoneType type) => _zones.any(
    (zone) => zone.type == type && zone.status == ZoneStatus.completed,
  );

  void reset() {
    _zones = _zones
        .map(
          (zone) =>
              InspectionZone(type: zone.type, status: ZoneStatus.notStarted),
        )
        .toList(growable: false);
    _phase = FullVehicleScanPhase.searchingVehicle;
    _vehicleDetected = false;
    _detectedZone = null;
    _suggestedZone = recommendedOrder.first;
    _lockProgress = 0;
    notifyListeners();
  }

  InspectionZoneType? _nextIncompleteAfter(InspectionZoneType current) {
    final start = recommendedOrder.indexOf(current);
    for (var offset = 1; offset <= recommendedOrder.length; offset++) {
      final candidate =
          recommendedOrder[(start + offset) % recommendedOrder.length];
      if (!isZoneComplete(candidate)) return candidate;
    }
    return null;
  }

  static List<InspectionZone> _normalizeZones(
    List<InspectionZone> initialZones,
  ) {
    final types = initialZones.map((zone) => zone.type).toSet();
    if (initialZones.length != InspectionZoneType.values.length ||
        types.length != InspectionZoneType.values.length ||
        !types.containsAll(InspectionZoneType.values)) {
      throw ArgumentError(
        'Full vehicle scanning requires exactly six unique zones.',
      );
    }
    return initialZones
        .map(
          (zone) =>
              InspectionZone(type: zone.type, status: ZoneStatus.notStarted),
        )
        .toList(growable: false);
  }
}
