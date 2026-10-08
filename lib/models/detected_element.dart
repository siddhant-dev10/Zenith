import 'dart:ui';
import 'exposure_category.dart';
import 'risk_level.dart';

class BoundingBox {
  final double left; // 0.0 - 1.0 relative
  final double top;
  final double width;
  final double height;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Rect toRect(Size containerSize) {
    return Rect.fromLTWH(
      left * containerSize.width,
      top * containerSize.height,
      width * containerSize.width,
      height * containerSize.height,
    );
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      left: (json['left'] as num?)?.toDouble() ?? 0.1,
      top: (json['top'] as num?)?.toDouble() ?? 0.1,
      width: (json['width'] as num?)?.toDouble() ?? 0.2,
      height: (json['height'] as num?)?.toDouble() ?? 0.2,
    );
  }
}

class DetectedElement {
  final String id;
  final String name;
  final ExposureCategory category;
  final RiskLevel riskLevel;
  final double confidence; // 0.0 - 1.0
  final String description;
  final String opsecImpact;
  final BoundingBox? boundingBox;
  final bool isRedacted;

  const DetectedElement({
    required this.id,
    required this.name,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.description,
    required this.opsecImpact,
    this.boundingBox,
    this.isRedacted = false,
  });

  DetectedElement copyWith({
    String? id,
    String? name,
    ExposureCategory? category,
    RiskLevel? riskLevel,
    double? confidence,
    String? description,
    String? opsecImpact,
    BoundingBox? boundingBox,
    bool? isRedacted,
  }) {
    return DetectedElement(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      riskLevel: riskLevel ?? this.riskLevel,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      opsecImpact: opsecImpact ?? this.opsecImpact,
      boundingBox: boundingBox ?? this.boundingBox,
      isRedacted: isRedacted ?? this.isRedacted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.id,
        'riskLevel': riskLevel.name,
        'confidence': confidence,
        'description': description,
        'opsecImpact': opsecImpact,
        'boundingBox': boundingBox?.toJson(),
        'isRedacted': isRedacted,
      };

  factory DetectedElement.fromJson(Map<String, dynamic> json) {
    return DetectedElement(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Sensitive Feature',
      category: ExposureCategory.fromString(json['category'] as String? ?? ''),
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String? ?? 'high'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
      description: json['description'] as String? ?? '',
      opsecImpact: json['opsecImpact'] as String? ?? '',
      boundingBox: json['boundingBox'] != null
          ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : null,
      isRedacted: json['isRedacted'] as bool? ?? false,
    );
  }
}
