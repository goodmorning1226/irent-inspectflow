import 'package:flutter/material.dart';

import '../../../models/inspection_zone.dart';
import '../../../theme/app_colors.dart';

class VehicleCoverageMap extends StatelessWidget {
  const VehicleCoverageMap({
    required this.zones,
    required this.activeZone,
    required this.suggestedZone,
    this.anomalyZones = const {},
    this.light = false,
    super.key,
  });

  final List<InspectionZone> zones;
  final InspectionZoneType? activeZone;
  final InspectionZoneType? suggestedZone;
  final Set<InspectionZoneType> anomalyZones;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final completed = zones
        .where((zone) => zone.status == ZoneStatus.completed)
        .map((zone) => zone.type.label)
        .join('、');
    return Semantics(
      label:
          '六區掃描進度。${completed.isEmpty ? '尚未完成任何區域' : '已完成$completed'}。'
          '${activeZone == null ? '' : '目前掃描${activeZone!.label}。'}'
          '${suggestedZone == null ? '' : '下一區建議${suggestedZone!.label}。'}',
      child: AspectRatio(
        aspectRatio: 110 / 128,
        child: CustomPaint(
          key: const Key('vehicle-coverage-map'),
          painter: _VehicleCoveragePainter(
            zones: zones,
            activeZone: activeZone,
            suggestedZone: suggestedZone,
            anomalyZones: anomalyZones,
            light: light,
          ),
        ),
      ),
    );
  }
}

class _VehicleCoveragePainter extends CustomPainter {
  const _VehicleCoveragePainter({
    required this.zones,
    required this.activeZone,
    required this.suggestedZone,
    required this.anomalyZones,
    required this.light,
  });

  final List<InspectionZone> zones;
  final InspectionZoneType? activeZone;
  final InspectionZoneType? suggestedZone;
  final Set<InspectionZoneType> anomalyZones;
  final bool light;

  static const _designSize = Size(110, 128);
  static const _pending = Color(0xFF555C62);
  static const _pendingBorder = Color(0xFF7C848B);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / _designSize.width,
      size.height / _designSize.height,
    );

    final shapes = <InspectionZoneType, Path>{
      InspectionZoneType.front: Path()
        ..moveTo(17, 32)
        ..lineTo(17, 16)
        ..cubicTo(17, 8, 34, 4, 55, 4)
        ..cubicTo(76, 4, 93, 8, 93, 16)
        ..lineTo(93, 32)
        ..close(),
      InspectionZoneType.leftSide: Path()
        ..addRect(const Rect.fromLTWH(17, 34, 17, 66)),
      InspectionZoneType.rightSide: Path()
        ..addRect(const Rect.fromLTWH(76, 34, 17, 66)),
      InspectionZoneType.frontSeat: Path()
        ..addRect(const Rect.fromLTWH(36, 34, 38, 32)),
      InspectionZoneType.rearSeat: Path()
        ..addRect(const Rect.fromLTWH(36, 68, 38, 32)),
      InspectionZoneType.rear: Path()
        ..moveTo(17, 102)
        ..lineTo(93, 102)
        ..lineTo(93, 115)
        ..quadraticBezierTo(93, 124, 84, 124)
        ..lineTo(26, 124)
        ..quadraticBezierTo(17, 124, 17, 115)
        ..close(),
    };

    for (final type in InspectionZoneType.values) {
      final path = shapes[type]!;
      final completed = zones.any(
        (zone) => zone.type == type && zone.status == ZoneStatus.completed,
      );
      final active = activeZone == type;
      final suggested = !active && suggestedZone == type;
      final fill = completed
          ? AppColors.successGreen
          : active
          ? AppColors.captureCyan
          : light
          ? const Color(0xFFF7F8F8)
          : _pending;
      final stroke = active
          ? AppColors.white
          : suggested
          ? AppColors.captureCyan
          : completed
          ? const Color(0xFF8ED3B0)
          : light
          ? const Color(0xFF9CA1A5)
          : _pendingBorder;

      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active
              ? 2.4
              : suggested
              ? 2.2
              : 1.1
          ..color = stroke,
      );
      _drawLabel(canvas, type, completed || active, light);
      if (anomalyZones.contains(type)) _drawAnomalyDot(canvas, type);
    }
    canvas.restore();
  }

  void _drawLabel(
    Canvas canvas,
    InspectionZoneType type,
    bool emphasized,
    bool light,
  ) {
    final centers = <InspectionZoneType, Offset>{
      InspectionZoneType.front: const Offset(55, 20),
      InspectionZoneType.leftSide: const Offset(25.5, 67),
      InspectionZoneType.rear: const Offset(55, 113),
      InspectionZoneType.rightSide: const Offset(84.5, 67),
      InspectionZoneType.frontSeat: const Offset(55, 50),
      InspectionZoneType.rearSeat: const Offset(55, 84),
    };
    final isSide =
        type == InspectionZoneType.leftSide ||
        type == InspectionZoneType.rightSide;
    final painter = TextPainter(
      text: TextSpan(
        text: isSide ? type.label.split('').join('\n') : type.label,
        style: TextStyle(
          color: emphasized
              ? AppColors.white
              : light
              ? AppColors.mutedInk
              : const Color(0xFFD0D4D7),
          fontSize: 8.5,
          height: isSide ? 1.05 : 1,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final center = centers[type]!;
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawAnomalyDot(Canvas canvas, InspectionZoneType type) {
    final centers = <InspectionZoneType, Offset>{
      InspectionZoneType.front: const Offset(82, 12),
      InspectionZoneType.leftSide: const Offset(28, 43),
      InspectionZoneType.rear: const Offset(82, 112),
      InspectionZoneType.rightSide: const Offset(87, 43),
      InspectionZoneType.frontSeat: const Offset(68, 43),
      InspectionZoneType.rearSeat: const Offset(68, 78),
    };
    final center = centers[type]!;
    canvas.drawCircle(center, 5, Paint()..color = AppColors.scanSurface);
    canvas.drawCircle(center, 3.6, Paint()..color = AppColors.warningOrange);
  }

  @override
  bool shouldRepaint(covariant _VehicleCoveragePainter oldDelegate) {
    return oldDelegate.zones != zones ||
        oldDelegate.activeZone != activeZone ||
        oldDelegate.suggestedZone != suggestedZone ||
        oldDelegate.anomalyZones != anomalyZones ||
        oldDelegate.light != light;
  }
}
