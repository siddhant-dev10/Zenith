import 'dart:math' as math;

import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/inferred_insight.dart';
import '../../../models/risk_level.dart';

/// Explainable risk contribution for an individual detected element.
class FindingRiskContribution {
  final String findingId;
  final String findingName;
  final ExposureCategory category;
  final int baseSensitivity;
  final double exploitability;
  final double visibilityScore;
  final double confidence;
  final double calculatedRiskContribution; // R(f_k) = S * E * V * C
  final String severityReason;

  const FindingRiskContribution({
    required this.findingId,
    required this.findingName,
    required this.category,
    required this.baseSensitivity,
    required this.exploitability,
    required this.visibilityScore,
    required this.confidence,
    required this.calculatedRiskContribution,
    required this.severityReason,
  });

  Map<String, dynamic> toJson() => {
    'findingId': findingId,
    'findingName': findingName,
    'category': category.id,
    'baseSensitivity': baseSensitivity,
    'exploitability': exploitability,
    'visibilityScore': visibilityScore,
    'confidence': confidence,
    'calculatedRiskContribution': calculatedRiskContribution,
    'severityReason': severityReason,
  };

  factory FindingRiskContribution.fromJson(Map<String, dynamic> json) {
    return FindingRiskContribution(
      findingId: json['findingId'] as String? ?? '',
      findingName: json['findingName'] as String? ?? '',
      category: ExposureCategory.fromString(
        json['category'] as String? ?? 'identity',
      ),
      baseSensitivity: (json['baseSensitivity'] as num?)?.toInt() ?? 50,
      exploitability: (json['exploitability'] as num?)?.toDouble() ?? 0.7,
      visibilityScore: (json['visibilityScore'] as num?)?.toDouble() ?? 0.9,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      calculatedRiskContribution:
          (json['calculatedRiskContribution'] as num?)?.toDouble() ?? 0.0,
      severityReason: json['severityReason'] as String? ?? '',
    );
  }
}

/// Calibrated baseline metrics for an individual detected visual feature.
class CalibratedElementMetrics {
  final int baseSensitivity;
  final double exploitability;
  final double visibilityScore;
  final String severityReason;

  const CalibratedElementMetrics({
    required this.baseSensitivity,
    required this.exploitability,
    required this.visibilityScore,
    required this.severityReason,
  });
}

/// Detailed breakdown and audit trail of deterministic risk calculation.
class RiskScoreBreakdown {
  final int overallScore; // 0 - 100
  final RiskLevel riskLevel;
  final Map<ExposureCategory, int> categoryScores;
  final ExposureCategory peakCategory;
  final int peakCategoryScore;
  final double meanCategoryScore;
  final double synergyPenalty;
  final int rawFindingsCount;
  final int deduplicatedFindingsCount;
  final List<String> auditTrail;
  final List<FindingRiskContribution> findingContributions;
  final String severityReason;

  const RiskScoreBreakdown({
    required this.overallScore,
    required this.riskLevel,
    required this.categoryScores,
    required this.peakCategory,
    required this.peakCategoryScore,
    required this.meanCategoryScore,
    required this.synergyPenalty,
    required this.rawFindingsCount,
    required this.deduplicatedFindingsCount,
    required this.auditTrail,
    this.findingContributions = const [],
    this.severityReason = '',
  });
}

/// Pure, deterministic, and independently testable mathematical risk scoring engine.
///
/// Implements the multi-factor calculus specified in ZENITH_SYSTEM_SPECIFICATION.md.
/// Prevents arbitrary LLM scoring, eliminates duplicate penalties, and guarantees
/// mathematical bounds in [0, 100].
class DeterministicRiskEngine {
  /// Dominance coefficient (alpha = 0.70) weighting the most vulnerable category.
  static const double alpha = 0.70;

  /// Spatial IoU threshold above which overlapping detections are merged.
  static const double iouDeduplicationThreshold = 0.50;

  /// Critical credential threshold: any finding with R >= 90 guarantees overall score >= 90.
  static const double criticalCredentialFloor = 90.0;

  /// Computes the complete deterministic risk assessment for a collection of findings and inferences.
  static RiskScoreBreakdown calculateScore({
    required List<DetectedElement> findings,
    List<InferredInsight> inferences = const [],
  }) {
    final audit = <String>[];
    audit.add(
      'Beginning deterministic risk evaluation for ${findings.length} raw findings.',
    );

    if (findings.isEmpty) {
      audit.add('Zero findings detected. Emitting baseline zero-risk score.');
      final emptyCategoryScores = {
        for (final cat in ExposureCategory.values) cat: 0,
      };
      return RiskScoreBreakdown(
        overallScore: 0,
        riskLevel: RiskLevel.low,
        categoryScores: emptyCategoryScores,
        peakCategory: ExposureCategory.identity,
        peakCategoryScore: 0,
        meanCategoryScore: 0.0,
        synergyPenalty: 0.0,
        rawFindingsCount: 0,
        deduplicatedFindingsCount: 0,
        auditTrail: audit,
        severityReason:
            'Zero findings detected: Baseline minimal privacy risk.',
      );
    }

    // 1. Spatial and semantic deduplication
    final deduplicated = deduplicateFindings(findings, auditTrail: audit);

    // 2. Compute individual risk contributions and group by category
    final categoryFindings = <ExposureCategory, List<DetectedElement>>{
      for (final cat in ExposureCategory.values) cat: [],
    };

    bool hasCriticalCredential = false;

    for (final f in deduplicated) {
      categoryFindings[f.category]?.add(f);
      final r = f.calculatedRiskContribution;
      if (r >= criticalCredentialFloor) {
        hasCriticalCredential = true;
        audit.add(
          'Critical credential detected: "${f.name}" with impact ${r.toStringAsFixed(1)}.',
        );
      }
    }

    // 3. Category Score Formulation using bounded probabilistic sum
    // CS_c = 100 * (1 - PROD(1 - R(f_k) / 100))
    final categoryScores = <ExposureCategory, int>{};
    int peakCatScore = 0;
    ExposureCategory peakCategory = ExposureCategory.identity;

    for (final cat in ExposureCategory.values) {
      final catList = categoryFindings[cat] ?? [];
      if (catList.isEmpty) {
        categoryScores[cat] = 0;
        continue;
      }

      double productComplement = 1.0;
      for (final f in catList) {
        final r = f.calculatedRiskContribution;
        final normalizedRisk = (r / 100.0).clamp(0.0, 0.999);
        productComplement *= (1.0 - normalizedRisk);
      }

      final computedScore = (100.0 * (1.0 - productComplement)).round().clamp(
        0,
        100,
      );
      categoryScores[cat] = computedScore;

      audit.add(
        'Category [${cat.id}]: ${catList.length} finding(s) aggregated to score $computedScore.',
      );

      if (computedScore >= peakCatScore) {
        peakCatScore = computedScore;
        peakCategory = cat;
      }
    }

    // 4. Compute mean category score across all 5 domains
    final sumScores = categoryScores.values.fold<int>(0, (prev, s) => prev + s);
    final meanCatScore = sumScores / ExposureCategory.values.length;

    // 5. Compute Inference Synergy Amplifier Gamma(I)
    // Gamma(I) = min(15, SUM(5.0 * confidence_j)), scaled to never exceed peakCatScore * 0.35
    double rawSynergy = 0.0;
    for (final inf in inferences) {
      rawSynergy += 5.0 * inf.confidence.clamp(0.0, 1.0);
    }
    final boundedSynergy = math.min(15.0, rawSynergy);
    final synergyPenalty = (peakCatScore > 0)
        ? math.min(boundedSynergy, peakCatScore * 0.35)
        : 0.0;
    if (synergyPenalty > 0) {
      audit.add(
        'Inference synergy amplifier added +${synergyPenalty.toStringAsFixed(1)} from ${inferences.length} inference(s).',
      );
    }

    // 6. Unified Overall Risk Score Omega Formulation:
    // A system's exposure risk is at minimum the severity of its most critical
    // vulnerability (peakCatScore), plus compound breadth from secondary domains,
    // plus contextual inference synergy Gamma(I).
    final secondaryCategoriesSum = categoryScores.entries
        .where((e) => e.key != peakCategory)
        .fold<int>(0, (prev, e) => prev + e.value);

    const breadthCoefficient =
        0.12; // Modest compound penalty for diffuse exposure
    final compoundBreadth = breadthCoefficient * secondaryCategoriesSum;

    double rawOmega = peakCatScore + compoundBreadth + synergyPenalty;

    // Apply critical credential guarantee if unmasked secret was detected
    if (hasCriticalCredential && rawOmega < criticalCredentialFloor) {
      rawOmega = criticalCredentialFloor;
      audit.add(
        'Overall score elevated to $criticalCredentialFloor due to critical credential presence.',
      );
    }

    final finalScore = rawOmega.round().clamp(0, 100);
    final finalRiskLevel = RiskLevel.fromScore(finalScore);

    audit.add(
      'Score finalized: $finalScore/100 (${finalRiskLevel.label}) [Peak: $peakCatScore, Mean: ${meanCatScore.toStringAsFixed(1)}].',
    );

    final findingContributions = deduplicated.map((f) {
      final calibrated = calibrateElementMetrics(
        category: f.category,
        nameOrType: f.name,
        rawSeverity: f.riskLevel.name,
        isDirect: f.isDirectExposure,
        confidence: f.confidence,
      );
      final reason = f.severityReason.isNotEmpty
          ? f.severityReason
          : calibrated.severityReason;

      return FindingRiskContribution(
        findingId: f.id,
        findingName: f.name,
        category: f.category,
        baseSensitivity: f.baseSensitivity,
        exploitability: f.exploitability,
        visibilityScore: f.visibilityScore,
        confidence: f.confidence,
        calculatedRiskContribution: f.calculatedRiskContribution,
        severityReason: reason,
      );
    }).toList();

    final String severityReason;
    if (finalScore == 0) {
      severityReason = 'Clean baseline: Zero sensitive privacy elements or operational markers detected.';
    } else if (hasCriticalCredential) {
      severityReason = 'CRITICAL EXPOSURE: High-value unmasked credentials or sensitive identity documents detected with immediate exploitability.';
    } else {
      severityReason =
          'Overall risk evaluated at $finalScore/100 (${finalRiskLevel.label}) driven by ${peakCategory.displayName} (peak domain score: $peakCatScore/100).';
    }

    return RiskScoreBreakdown(
      overallScore: finalScore,
      riskLevel: finalRiskLevel,
      categoryScores: categoryScores,
      peakCategory: peakCategory,
      peakCategoryScore: peakCatScore,
      meanCategoryScore: meanCatScore,
      synergyPenalty: synergyPenalty,
      rawFindingsCount: findings.length,
      deduplicatedFindingsCount: deduplicated.length,
      auditTrail: audit,
      findingContributions: findingContributions,
      severityReason: severityReason,
    );
  }

  /// Calibrates base sensitivity and exploitability based on element type and category.
  /// Enforces explainable, low risk (0-25) for ordinary biological faces and clean scenery,
  /// while guaranteeing high/critical impact for credential and identity documents.
  static CalibratedElementMetrics calibrateElementMetrics({
    required ExposureCategory category,
    required String nameOrType,
    required String rawSeverity,
    required bool isDirect,
    double confidence = 0.9,
  }) {
    final lower = nameOrType.trim().toLowerCase();
    final sev = rawSeverity.trim().toLowerCase();

    // 1. Critical Authentication, Shells & Plaintext Secrets (Guaranteed >= 90)
    if (lower.contains('api_key') ||
        lower.contains('apikey') ||
        lower.contains('api token') ||
        lower.contains('private key') ||
        lower.contains('private_key') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('access token') ||
        lower.contains('auth token') ||
        lower.contains('terminal') ||
        lower.contains('shell') ||
        lower.contains('bash') ||
        lower.contains('ssh') ||
        lower.contains('aws') ||
        lower.contains('sticky') ||
        (lower.contains('credential') &&
            !lower.contains('badge') &&
            !lower.contains('card') &&
            !lower.contains('pass')) ||
        lower.contains('passport') ||
        lower.contains('mrz') ||
        lower.contains('bank') ||
        lower.contains('routing') ||
        lower.contains('medical') ||
        lower.contains('prescription') ||
        lower.contains('health record') ||
        lower.contains('patient') ||
        lower.contains('pathology') ||
        sev == 'critical') {
      return const CalibratedElementMetrics(
        baseSensitivity: 100,
        exploitability: 1.0,
        visibilityScore: 1.0,
        severityReason:
            'Critical unmasked authentication secret or high-value document granting immediate exploitability.',
      );
    }

    // 2. Ordinary Biological Human Faces / Portraits (CALIBRATED LOW RISK <= 25)
    // Evaluated BEFORE general cards/ambient features so human faces receive calibrated low baseline.
    if (lower.contains('face') ||
        lower.contains('portrait') ||
        lower.contains('person') ||
        lower.contains('selfie') ||
        lower.contains('human face') ||
        lower.contains('facial') ||
        lower.contains('biometric')) {
      return const CalibratedElementMetrics(
        baseSensitivity: 15,
        exploitability: 0.20,
        visibilityScore: 0.80,
        severityReason:
            'Publicly observable biological feature in ordinary context with low intrinsic exploitability.',
      );
    }

    // 3. Explicit High Severity Findings (HIGH SEVERITY 51-75)
    if (sev == 'high') {
      return const CalibratedElementMetrics(
        baseSensitivity: 80,
        exploitability: 0.85,
        visibilityScore: 0.90,
        severityReason:
            'High-value organizational badge, vehicle plate, or domicile identifier exposing trackable personal markers.',
      );
    }

    // 3. Ambiguous numeric fragments, partial, occluded, or pixelated records (MODERATE SEVERITY 26-50)
    // Evaluated before general badge/plate checks so degraded/partial items are not scored as full exposures.
    if (lower.contains('ambiguous') ||
        lower.contains('fragment') ||
        lower.contains('partial') ||
        lower.contains('digit') ||
        lower.contains('pixelated') ||
        lower.contains('occluded') ||
        lower.contains('blurred') ||
        sev == 'moderate' ||
        sev == 'medium') {
      return const CalibratedElementMetrics(
        baseSensitivity: 50,
        exploitability: 0.70,
        visibilityScore: 0.85,
        severityReason:
            'Moderate sensitivity visual feature with contextual or secondary privacy impact.',
      );
    }

    // 4. Benign, prop, or low severity indicators (LOW SEVERITY 0-25)
    if (sev == 'low' ||
        lower.contains('movie prop') ||
        lower.contains('prop') ||
        lower.contains('theatrical') ||
        lower.contains('fictional') ||
        lower.contains('poster') ||
        lower.contains('landscape') ||
        lower.contains('scenery') ||
        lower.contains('clean')) {
      return const CalibratedElementMetrics(
        baseSensitivity: 15,
        exploitability: 0.25,
        visibilityScore: 0.75,
        severityReason:
            'Low sensitivity visual element with minimal operational risk.',
      );
    }

    // 5. High-Value Identity, Badges, Addresses, Contact, Plates, Tickets (HIGH SEVERITY 51-75)
    if (lower.contains('badge') ||
        lower.contains('student') ||
        lower.contains('employee') ||
        lower.contains('lanyard') ||
        lower.contains('card') ||
        lower.contains('address') ||
        lower.contains('house') ||
        lower.contains('street') ||
        lower.contains('placard') ||
        lower.contains('plate') ||
        lower.contains('license') ||
        lower.contains('vehicle') ||
        lower.contains('boarding') ||
        lower.contains('flight') ||
        lower.contains('pnr') ||
        lower.contains('transit') ||
        lower.contains('qr') ||
        lower.contains('barcode') ||
        lower.contains('phone') ||
        lower.contains('email') ||
        lower.contains('contact') ||
        lower.contains('gps') ||
        lower.contains('exif') ||
        sev == 'high') {
      return const CalibratedElementMetrics(
        baseSensitivity: 80,
        exploitability: 0.85,
        visibilityScore: 0.90,
        severityReason:
            'High-value organizational badge, vehicle plate, or domicile identifier exposing trackable personal markers.',
      );
    }

    // 6. Diffuse scenery, landscapes, benign displays (LOW SEVERITY 0-25)
    return const CalibratedElementMetrics(
      baseSensitivity: 15,
      exploitability: 0.25,
      visibilityScore: 0.75,
      severityReason:
          'Low sensitivity visual element with minimal operational risk.',
    );
  }

  /// Deduplicates findings based on spatial IoU overlap and semantic equivalence.
  ///
  /// Prevents double-penalties if multiple detectors (e.g. OCR and Gemini)
  /// identify the same element in the photograph.
  static List<DetectedElement> deduplicateFindings(
    List<DetectedElement> input, {
    List<String>? auditTrail,
  }) {
    if (input.length <= 1) return List.from(input);

    final result = <DetectedElement>[];
    final mergedIndices = <int>{};

    for (int i = 0; i < input.length; i++) {
      if (mergedIndices.contains(i)) continue;

      var current = input[i];

      for (int j = i + 1; j < input.length; j++) {
        if (mergedIndices.contains(j)) continue;

        final candidate = input[j];

        // Check if category matches
        if (current.category != candidate.category) continue;

        bool shouldMerge = false;

        // Condition A: Spatial IoU overlap >= 0.50
        if (current.boundingBox != null && candidate.boundingBox != null) {
          final iou = current.boundingBox!.intersectionOverUnion(
            candidate.boundingBox!,
          );
          if (iou >= iouDeduplicationThreshold) {
            shouldMerge = true;
            auditTrail?.add(
              'Spatial merge: "${current.name}" and "${candidate.name}" overlap with IoU ${iou.toStringAsFixed(2)}.',
            );
          }
        }

        // Condition B: Identical evidence text match
        if (!shouldMerge &&
            current.evidenceText != null &&
            candidate.evidenceText != null &&
            current.evidenceText!.trim().isNotEmpty &&
            current.evidenceText!.trim().toLowerCase() ==
                candidate.evidenceText!.trim().toLowerCase()) {
          shouldMerge = true;
          auditTrail?.add(
            'Textual merge: "${current.name}" and "${candidate.name}" share exact evidence "${current.evidenceText}".',
          );
        }

        // Perform merge by inheriting peak sensitivity, confidence, exploitability
        if (shouldMerge) {
          mergedIndices.add(j);
          final peakSensitivity = math.max(
            current.baseSensitivity,
            candidate.baseSensitivity,
          );
          final peakConfidence = math.max(
            current.confidence,
            candidate.confidence,
          );
          final peakExploitability = math.max(
            current.exploitability,
            candidate.exploitability,
          );
          final avgVisibility =
              (current.visibilityScore + candidate.visibilityScore) / 2.0;

          current = current.copyWith(
            baseSensitivity: peakSensitivity,
            confidence: peakConfidence,
            exploitability: peakExploitability,
            visibilityScore: avgVisibility,
            description: current.description.isNotEmpty
                ? current.description
                : candidate.description,
            opsecImpact: current.opsecImpact.isNotEmpty
                ? current.opsecImpact
                : candidate.opsecImpact,
          );
        }
      }

      result.add(current);
    }

    return result;
  }
}
