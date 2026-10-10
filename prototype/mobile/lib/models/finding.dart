enum FindingType { scratch, dent, crack, stain, litter, leftItem }

enum FindingSeverity { low, medium, high }

class Finding {
  const Finding({
    required this.id,
    required this.location,
    required this.type,
    required this.severity,
    required this.possiblyNew,
    required this.confidence,
    required this.sourceImages,
    required this.isPrototype,
  });

  final String id;
  final String location;
  final FindingType type;
  final FindingSeverity severity;
  final bool possiblyNew;
  final double confidence;
  final List<String> sourceImages;
  final bool isPrototype;
}

abstract final class MockFindings {
  static const leftRearDoorScratch = Finding(
    id: 'FND-DEMO-LEFT-001',
    location: '左後車門下半部',
    type: FindingType.scratch,
    severity: FindingSeverity.medium,
    possiblyNew: true,
    confidence: 0.87,
    sourceImages: [
      'assets/frames/exterior_damage_wide.png',
      'assets/frames/exterior_damage_detail_center.png',
      'assets/frames/exterior_damage_detail_left.png',
      'assets/frames/exterior_damage_detail_right.png',
    ],
    isPrototype: true,
  );

  static const rearSeatDrinkStain = Finding(
    id: 'FND-DEMO-INTERIOR-001',
    location: '後座右側座墊',
    type: FindingType.stain,
    severity: FindingSeverity.medium,
    possiblyNew: true,
    confidence: 0.91,
    sourceImages: ['assets/frames/interior_dirty_best.png'],
    isPrototype: true,
  );
}
