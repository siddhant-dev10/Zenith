import 'exposure_category.dart';
import 'risk_level.dart';

class InferredInsight {
  final String id;
  final ExposureCategory category;
  final String directObservation; // What was directly seen
  final String inferredInsight; // What an attacker can deduce
  final String attackerThreatProfile; // How it can be weaponized
  final RiskLevel severity;
  final double confidence;

  const InferredInsight({
    required this.id,
    required this.category,
    required this.directObservation,
    required this.inferredInsight,
    required this.attackerThreatProfile,
    required this.severity,
    this.confidence = 0.9,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.id,
        'directObservation': directObservation,
        'inferredInsight': inferredInsight,
        'attackerThreatProfile': attackerThreatProfile,
        'severity': severity.name,
        'confidence': confidence,
      };

  factory InferredInsight.fromJson(Map<String, dynamic> json) {
    return InferredInsight(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      category: ExposureCategory.fromString(json['category'] as String? ?? ''),
      directObservation: json['directObservation'] as String? ?? 'Identified item',
      inferredInsight: json['inferredInsight'] as String? ?? 'Inferred metadata',
      attackerThreatProfile: json['attackerThreatProfile'] as String? ?? 'Potential vector',
      severity: RiskLevel.fromString(json['severity'] as String? ?? 'moderate'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
