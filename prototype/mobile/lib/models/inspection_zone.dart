import 'package:flutter/material.dart';

enum InspectionZoneType {
  front,
  leftSide,
  rear,
  rightSide,
  frontSeat,
  rearSeat,
}

enum ZoneStatus { notStarted, selected, completed, rescanRequired }

class InspectionZone {
  const InspectionZone({
    required this.type,
    required this.status,
    this.completedAt,
    this.qualitySummary,
  });

  final InspectionZoneType type;
  final ZoneStatus status;
  final String? completedAt;
  final String? qualitySummary;

  bool get hasRecordedImage => status == ZoneStatus.completed;

  bool get hasInteractiveScan =>
      type == InspectionZoneType.leftSide ||
      type == InspectionZoneType.rearSeat;

  InspectionZone copyWith({
    ZoneStatus? status,
    String? completedAt,
    String? qualitySummary,
  }) {
    return InspectionZone(
      type: type,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      qualitySummary: qualitySummary ?? this.qualitySummary,
    );
  }
}

extension InspectionZoneTypeLabel on InspectionZoneType {
  String get label => switch (this) {
    InspectionZoneType.front => '車頭',
    InspectionZoneType.leftSide => '左側',
    InspectionZoneType.rear => '車尾',
    InspectionZoneType.rightSide => '右側',
    InspectionZoneType.frontSeat => '前座',
    InspectionZoneType.rearSeat => '後座',
  };

  IconData get icon => switch (this) {
    InspectionZoneType.front => Icons.directions_car_filled_rounded,
    InspectionZoneType.leftSide => Icons.airport_shuttle_rounded,
    InspectionZoneType.rear => Icons.directions_car_filled_outlined,
    InspectionZoneType.rightSide => Icons.airport_shuttle_outlined,
    InspectionZoneType.frontSeat => Icons.airline_seat_recline_normal_rounded,
    InspectionZoneType.rearSeat => Icons.event_seat_rounded,
  };
}

extension ZoneStatusLabel on ZoneStatus {
  String get label => switch (this) {
    ZoneStatus.notStarted => '待掃描',
    ZoneStatus.selected => '已選取',
    ZoneStatus.completed => '已完成',
    ZoneStatus.rescanRequired => '需補掃',
  };
}
