import 'dart:math' as math;

import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/inferred_insight.dart';
import '../../../models/risk_level.dart';

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
    // Gamma(I) = min(15, SUM(5.0 * confidence_j))
    double rawSynergy = 0.0;
    for (final inf in inferences) {
      rawSynergy += 5.0 * inf.confidence.clamp(0.0, 1.0);
    }
    final synergyPenalty = math.min(15.0, rawSynergy);
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
