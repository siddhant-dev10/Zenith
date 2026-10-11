import 'dart:math' as math;
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

  /// Calculates the Intersection over Union (IoU) between this box and [other].
  double intersectionOverUnion(BoundingBox other) {
    final x1 = math.max(left, other.left);
    final y1 = math.max(top, other.top);
    final x2 = math.min(left + width, other.left + other.width);
    final y2 = math.min(top + height, other.top + other.height);

    final intersectionWidth = math.max(0.0, x2 - x1);
    final intersectionHeight = math.max(0.0, y2 - y1);
    final intersectionArea = intersectionWidth * intersectionHeight;

    final areaA = width * height;
    final areaB = other.width * other.height;
    final unionArea = areaA + areaB - intersectionArea;

    if (unionArea <= 0.0) return 0.0;
    return (intersectionArea / unionArea).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      left: ((json['left'] as num?)?.toDouble() ?? 0.1).clamp(0.0, 1.0),
      top: ((json['top'] as num?)?.toDouble() ?? 0.1).clamp(0.0, 1.0),
      width: ((json['width'] as num?)?.toDouble() ?? 0.2).clamp(0.0, 1.0),
      height: ((json['height'] as num?)?.toDouble() ?? 0.2).clamp(0.0, 1.0),
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

  // Architectural extensions for deterministic intelligence engine
  final String informationType;
  final String detectionSource;
  final String? evidenceText;
  final int baseSensitivity; // 1 - 100
  final double exploitability; // 0.2 - 1.0
  final double visibilityScore; // 0.1 - 1.0
  final bool isDirectExposure;
  final String actionableMitigation;

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
    this.informationType = '',
    this.detectionSource = 'ai_vision',
    this.evidenceText,
    this.baseSensitivity = 50,
    this.exploitability = 0.7,
    this.visibilityScore = 0.9,
    this.isDirectExposure = true,
    this.actionableMitigation = '',
  });

  /// Computes the standalone risk contribution R(f_k) = S * E * V * C
  double get calculatedRiskContribution {
    final s = baseSensitivity.toDouble().clamp(1.0, 100.0);
    final e = exploitability.clamp(0.2, 1.0);
    final v = visibilityScore.clamp(0.1, 1.0);
    final c = confidence.clamp(0.0, 1.0);
    return (s * e * v * c).clamp(0.0, 100.0);
  }

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
    String? informationType,
    String? detectionSource,
    String? evidenceText,
    int? baseSensitivity,
    double? exploitability,
    double? visibilityScore,
    bool? isDirectExposure,
    String? actionableMitigation,
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
      informationType: informationType ?? this.informationType,
      detectionSource: detectionSource ?? this.detectionSource,
      evidenceText: evidenceText ?? this.evidenceText,
      baseSensitivity: baseSensitivity ?? this.baseSensitivity,
      exploitability: exploitability ?? this.exploitability,
      visibilityScore: visibilityScore ?? this.visibilityScore,
      isDirectExposure: isDirectExposure ?? this.isDirectExposure,
      actionableMitigation: actionableMitigation ?? this.actionableMitigation,
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
    'informationType': informationType.isNotEmpty ? informationType : name,
    'detectionSource': detectionSource,
    'evidenceText': evidenceText,
    'baseSensitivity': baseSensitivity,
    'exploitability': exploitability,
    'visibilityScore': visibilityScore,
    'isDirectExposure': isDirectExposure,
    'actionableMitigation': actionableMitigation,
  };

  factory DetectedElement.fromJson(Map<String, dynamic> json) {
    final cat = ExposureCategory.fromString(json['category'] as String? ?? '');
    final nameStr = json['name'] as String? ?? 'Sensitive Feature';
    final rawConf = (json['confidence'] as num?)?.toDouble() ?? 0.85;

    // Derive or extract base sensitivity based on risk level or json
    final rawSensitivity = (json['baseSensitivity'] as num?)?.toInt();
    final sensitivity =
        rawSensitivity ??
        _defaultSensitivityForRisk(json['riskLevel'] as String? ?? 'high');

    return DetectedElement(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameStr,
      category: cat,
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String? ?? 'high'),
      confidence: rawConf.clamp(0.0, 1.0),
      description: json['description'] as String? ?? '',
      opsecImpact: json['opsecImpact'] as String? ?? '',
      boundingBox: json['boundingBox'] != null
          ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : null,
      isRedacted: json['isRedacted'] as bool? ?? false,
      informationType: json['informationType'] as String? ?? nameStr,
      detectionSource: json['detectionSource'] as String? ?? 'ai_vision',
      evidenceText: json['evidenceText'] as String?,
      baseSensitivity: sensitivity,
      exploitability: ((json['exploitability'] as num?)?.toDouble() ?? 0.75)
          .clamp(0.2, 1.0),
      visibilityScore: ((json['visibilityScore'] as num?)?.toDouble() ?? 0.9)
          .clamp(0.1, 1.0),
      isDirectExposure: json['isDirectExposure'] as bool? ?? true,
      actionableMitigation: json['actionableMitigation'] as String? ?? '',
    );
  }

  static int _defaultSensitivityForRisk(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 20;
      case 'moderate':
      case 'medium':
        return 45;
      case 'high':
        return 70;
      case 'critical':
      default:
        return 90;
    }
  }
}
