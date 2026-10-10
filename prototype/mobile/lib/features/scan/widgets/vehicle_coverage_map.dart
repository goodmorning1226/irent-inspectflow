import 'package:flutter/material.dart';

import '../../../models/inspection_zone.dart';
import '../../../theme/app_colors.dart';

class VehicleCoverageMap extends StatelessWidget {
  const VehicleCoverageMap({
    required this.zones,
    required this.activeZone,
    required this.suggestedZone,
    this.anomalyZones = const {},
    super.key,
  });

  final List<InspectionZone> zones;
  final InspectionZoneType? activeZone;
  final InspectionZoneType? suggestedZone;
  final Set<InspectionZoneType> anomalyZones;

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
        aspectRatio: 148 / 96,
        child: CustomPaint(
          key: const Key('vehicle-coverage-map'),
          painter: _VehicleCoveragePainter(
            zones: zones,
            activeZone: activeZone,
            suggestedZone: suggestedZone,
            anomalyZones: anomalyZones,
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
  });

  final List<InspectionZone> zones;
  final InspectionZoneType? activeZone;
  final InspectionZoneType? suggestedZone;
  final Set<InspectionZoneType> anomalyZones;

  static const _designSize = Size(148, 96);
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
        ..moveTo(42, 18)
        ..quadraticBezierTo(46, 2, 74, 2)
        ..quadraticBezierTo(102, 2, 106, 18)
        ..close(),
      InspectionZoneType.leftSide: Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 20, 28, 56),
            const Radius.circular(12),
          ),
        ),
      InspectionZoneType.rightSide: Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(112, 20, 28, 56),
            const Radius.circular(12),
          ),
        ),
      InspectionZoneType.frontSeat: Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 21, 68, 26),
            const Radius.circular(6),
          ),
        ),
      InspectionZoneType.rearSeat: Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 49, 68, 26),
            const Radius.circular(6),
          ),
        ),
      InspectionZoneType.rear: Path()
        ..moveTo(42, 78)
        ..lineTo(106, 78)
        ..quadraticBezierTo(102, 94, 74, 94)
        ..quadraticBezierTo(46, 94, 42, 78)
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
          : _pending;
      final stroke = active
          ? AppColors.white
          : suggested
          ? AppColors.captureCyan
          : completed
          ? const Color(0xFF8ED3B0)
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
      _drawLabel(canvas, type, completed || active);
      if (anomalyZones.contains(type)) _drawAnomalyDot(canvas, type);
    }
    canvas.restore();
  }

  void _drawLabel(Canvas canvas, InspectionZoneType type, bool emphasized) {
    final centers = <InspectionZoneType, Offset>{
      InspectionZoneType.front: const Offset(74, 12),
      InspectionZoneType.leftSide: const Offset(22, 48),
      InspectionZoneType.rear: const Offset(74, 85),
      InspectionZoneType.rightSide: const Offset(126, 48),
      InspectionZoneType.frontSeat: const Offset(74, 34),
      InspectionZoneType.rearSeat: const Offset(74, 62),
    };
    final painter = TextPainter(
      text: TextSpan(
        text: type.label,
        style: TextStyle(
          color: emphasized ? AppColors.white : const Color(0xFFD0D4D7),
          fontSize: 9,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
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
      InspectionZoneType.front: const Offset(101, 8),
      InspectionZoneType.leftSide: const Offset(29, 27),
      InspectionZoneType.rear: const Offset(101, 87),
      InspectionZoneType.rightSide: const Offset(133, 27),
      InspectionZoneType.frontSeat: const Offset(101, 27),
      InspectionZoneType.rearSeat: const Offset(101, 55),
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
        oldDelegate.anomalyZones != anomalyZones;
  }
}
