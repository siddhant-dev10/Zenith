import 'dart:typed_data';

import '../../../models/privacy_audit_report.dart';
import '../../../models/risk_level.dart';
import '../inference/contextual_inference_engine.dart';
import '../providers/vision_analysis_provider.dart';
import '../recommendations/recommendation_engine.dart';
import '../scoring/deterministic_risk_engine.dart';
import '../validation/image_validator.dart';

/// Master orchestration pipeline executing Zenith's privacy intelligence analysis.
///
/// Ensures deterministic execution:
/// 1. Ingestion Validation
/// 2. Vision Provider Execution
/// 3. Normalization & Deduplication
/// 4. Contextual Threat Deduction
/// 5. Deterministic Risk Calculus
/// 6. Actionable Recommendation Generation
/// 7. Structured Audit Report Packaging
class ZenithAnalysisPipeline {
  final IVisionAnalysisProvider visionProvider;

  ZenithAnalysisPipeline({required this.visionProvider});

  /// Analyzes an image byte payload and produces a structured PrivacyAuditReport.
  Future<PrivacyAuditReport> execute({
    required Uint8List imageBytes,
    String? imagePath,
    String? sampleAsset,
    String sensitivity = 'Balanced',
    String? model,
    bool allowDegradedFallback = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final limitations = <String>[];
    final processingErrors = <String>[];
    String processingStatus = 'completed';

    // Stage 1: Validation
    final validation = ImageValidator.validate(imageBytes);
    if (!validation.isValid) {
      throw ImageValidationException(
        validation.errorMessage ?? 'Image validation failed',
        format: validation.format,
      );
    }

    if (validation.metadata['hasExif'] == false) {
      limitations.add(
        'Image file header contains no EXIF tags (possible stripped upload).',
      );
    }

    // Stage 2: Vision Analysis
    VisionAnalysisRawResult rawVisionResult;
    try {
      rawVisionResult = await visionProvider.analyze(
        imageBytes: imageBytes,
        mimeType: validation.mimeType,
        sensitivity: sensitivity,
        model: model,
      );
    } catch (e) {
      if (!allowDegradedFallback) {
        rethrow;
      }
      processingStatus = 'partial_failure';
      processingErrors.add('Vision analysis detector failure: $e');
      limitations.add(
        'Primary vision detector failed; conservative degraded posture active.',
      );
      rawVisionResult = const VisionAnalysisRawResult(
        sceneDescription:
            'Vision detector failed to execute. Degraded analysis.',
        detectedElements: [],
        isLiveAi: false,
        durationMs: 0,
      );
    }

    // Stage 3: Normalization and Deduplication
    final deduplicatedFindings = DeterministicRiskEngine.deduplicateFindings(
      rawVisionResult.detectedElements,
    );

    // Stage 4: Contextual Threat Deductions
    final inferences = ContextualInferenceEngine.synthesizeInferences(
      deduplicatedFindings,
    );

    // Stage 5: Deterministic Mathematical Risk Scoring
    final scoreBreakdown = DeterministicRiskEngine.calculateScore(
      findings: deduplicatedFindings,
      inferences: inferences,
    );

    // Stage 6: Actionable Recommendations
    final recommendations = RecommendationEngine.generateRecommendations(
      deduplicatedFindings,
    );

    stopwatch.stop();

    // Stage 7: Assemble Structured PrivacyAuditReport
    int finalScore = scoreBreakdown.overallScore;
    RiskLevel finalRiskLevel = scoreBreakdown.riskLevel;
    String reportTitle;
    String summary;

    if (processingStatus == 'partial_failure') {
      // Critical Safeguard: Never emit a LOW RISK report when critical analysis has failed.
      if (finalScore < 50) {
        finalScore = 50;
        finalRiskLevel = RiskLevel.moderate;
      }
      reportTitle = 'Partial Privacy Analysis (Detector Warning)';
      summary =
          'CRITICAL WARNING: Vision detectors failed (${processingErrors.first}). '
          'Zenith cannot confirm this asset is safe. Manual review is required before publishing.';
    } else if (deduplicatedFindings.isEmpty) {
      reportTitle = 'Clean Baseline - Minimal Privacy Risk';
      summary = 'No sensitive visual markers or operational security risks were detected in the analyzed payload.';
    } else {
      reportTitle =
          '${scoreBreakdown.riskLevel.label} Privacy & Security Exposure';
      summary =
          'Automated privacy audit identified ${deduplicatedFindings.length} sensitive element(s) with highest vulnerability in ${scoreBreakdown.peakCategory.displayName}.';
    }

    return PrivacyAuditReport(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      imagePath: imagePath,
      imageBytes: imageBytes,
      sampleAsset: sampleAsset,
      overallScore: finalScore,
      riskLevel: finalRiskLevel,
      title: reportTitle,
      summary: summary,
      categoryScores: scoreBreakdown.categoryScores,
      detectedElements: deduplicatedFindings,
      inferredInsights: inferences,
      recommendations: recommendations,
      exifMetadata: validation.metadata,
      isLiveAi: rawVisionResult.isLiveAi,
      scanDurationMs: stopwatch.elapsedMilliseconds,
      processingStatus: processingStatus,
      analysisLimitations: limitations,
      processingErrors: processingErrors,
    );
  }
}
