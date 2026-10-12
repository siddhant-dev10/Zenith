import 'exposure_category.dart';
import 'risk_level.dart';

enum EpistemicLevel {
  corroboratedDeduction,
  contextualProbability,
  uncertainHypothesis;

  static EpistemicLevel fromString(String val) {
    switch (val.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'corroborateddeduction':
      case 'corroborated':
        return EpistemicLevel.corroboratedDeduction;
      case 'contextualprobability':
      case 'probable':
        return EpistemicLevel.contextualProbability;
      case 'uncertainhypothesis':
      case 'hypothesis':
      default:
        return EpistemicLevel.uncertainHypothesis;
    }
  }

  String get displayName {
    switch (this) {
      case EpistemicLevel.corroboratedDeduction:
        return 'Corroborated Deduction';
      case EpistemicLevel.contextualProbability:
        return 'Contextual Probability';
      case EpistemicLevel.uncertainHypothesis:
        return 'Uncertain Hypothesis';
    }
  }
}

class InferredInsight {
  final String id;
  final ExposureCategory category;
  final String directObservation; // What was directly seen
  final String inferredInsight; // What an attacker can deduce
  final String attackerThreatProfile; // How it can be weaponized
  final RiskLevel severity;
  final double confidence;

  // Architectural extensions for explainable evidence graph
  final List<String> supportingEvidenceIds;
  final EpistemicLevel epistemicLevel;
  final String uncertaintyAssessment;

  const InferredInsight({
    required this.id,
    required this.category,
    required this.directObservation,
    required this.inferredInsight,
    required this.attackerThreatProfile,
    required this.severity,
    this.confidence = 0.9,
    this.supportingEvidenceIds = const [],
    this.epistemicLevel = EpistemicLevel.contextualProbability,
    this.uncertaintyAssessment = 'Based on contextual visual cues.',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.id,
    'directObservation': directObservation,
    'inferredInsight': inferredInsight,
    'attackerThreatProfile': attackerThreatProfile,
    'severity': severity.name,
    'confidence': confidence,
    'supportingEvidenceIds': supportingEvidenceIds,
    'epistemicLevel': epistemicLevel.name,
    'uncertaintyAssessment': uncertaintyAssessment,
  };

  factory InferredInsight.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['supportingEvidenceIds'] as List<dynamic>? ?? [];
    final evidenceList = rawEvidence.map((e) => e.toString()).toList();

    return InferredInsight(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      category: ExposureCategory.fromString(json['category'] as String? ?? ''),
      directObservation:
          json['directObservation'] as String? ?? 'Identified item',
      inferredInsight:
          json['inferredInsight'] as String? ?? 'Inferred metadata',
      attackerThreatProfile:
          json['attackerThreatProfile'] as String? ?? 'Potential vector',
      severity: RiskLevel.fromString(json['severity'] as String? ?? 'moderate'),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.85).clamp(
        0.0,
        1.0,
      ),
      supportingEvidenceIds: evidenceList,
      epistemicLevel: EpistemicLevel.fromString(
        json['epistemicLevel'] as String? ?? 'contextualProbability',
      ),
      uncertaintyAssessment:
          json['uncertaintyAssessment'] as String? ??
          'Based on contextual visual cues.',
    );
  }
}
