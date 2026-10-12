import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/privacy_engine/inference/contextual_inference_engine.dart';
import 'package:zenith/core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import 'package:zenith/core/privacy_engine/providers/vision_analysis_provider.dart';
import 'package:zenith/core/privacy_engine/scoring/deterministic_risk_engine.dart';
import 'package:zenith/core/privacy_engine/testing/test_case_models.dart';
import 'package:zenith/core/privacy_engine/testing/test_case_repository.dart';
import 'package:zenith/core/privacy_engine/testing/test_evaluator.dart';
import 'package:zenith/models/detected_element.dart';
import 'package:zenith/models/exposure_category.dart';
import 'package:zenith/models/inferred_insight.dart';
import 'package:zenith/models/risk_level.dart';

void main() {
  group('Calibrated Privacy Risk Scoring & Evaluation Tests', () {
    test('Ordinary face photograph scores <= 15 (LOW risk)', () {
      final faceElement = DetectedElement(
        id: 'fnd_face_1',
        name: 'Human Face',
        category: ExposureCategory.identity,
        riskLevel: RiskLevel.low,
        confidence: 0.95,
        description: 'Adult facial features visible in portrait shot.',
        opsecImpact: 'Public facial biometrics.',
        baseSensitivity: 15,
        exploitability: 0.20,
        visibilityScore: 0.80,
        severityReason: 'Publicly observable biological feature in ordinary context with low intrinsic exploitability.',
      );

      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: [faceElement],
      );

      expect(breakdown.overallScore, lessThanOrEqualTo(15));
      expect(breakdown.overallScore, greaterThan(0));
      expect(breakdown.riskLevel, RiskLevel.low);
      expect(breakdown.peakCategoryScore, lessThanOrEqualTo(15));
      expect(breakdown.findingContributions.length, 1);
      expect(
        breakdown.findingContributions.first.severityReason,
        contains('biological feature'),
      );
      expect(breakdown.severityReason, contains('Low Risk'));
    });

    test('Multiple faces in photo remain firmly within LOW risk (< 25)', () {
      final faces = List.generate(
        4,
        (i) => DetectedElement(
          id: 'fnd_face_$i',
          name: 'Person Face $i',
          category: ExposureCategory.identity,
          riskLevel: RiskLevel.low,
          confidence: 0.90,
          description: 'Facial biometrics of person $i',
          opsecImpact: 'Public facial features',
          baseSensitivity: 15,
          exploitability: 0.20,
          visibilityScore: 0.80,
        ),
      );

      final breakdown = DeterministicRiskEngine.calculateScore(findings: faces);
      expect(breakdown.overallScore, lessThanOrEqualTo(25));
      expect(breakdown.riskLevel, RiskLevel.low);
    });

    test('Ordinary face outdoors does NOT trigger institutional schedule inference', () {
      final face = DetectedElement(
        id: 'fnd_face',
        name: 'Portrait Face',
        category: ExposureCategory.identity,
        riskLevel: RiskLevel.low,
        confidence: 0.95,
        description: 'Portrait shot of person',
        opsecImpact: 'Facial biometrics',
        baseSensitivity: 15,
        exploitability: 0.20,
      );

      final ambientLocation = DetectedElement(
        id: 'fnd_bg',
        name: 'Park Scenery',
        category: ExposureCategory.location,
        riskLevel: RiskLevel.low,
        confidence: 0.85,
        description: 'Public park greenery',
        opsecImpact: 'Ambient backdrop',
        baseSensitivity: 15,
        exploitability: 0.25,
      );

      final inferences = ContextualInferenceEngine.synthesizeInferences([
        face,
        ambientLocation,
      ]);
      expect(
        inferences.any((inf) => inf.id.contains('institutional')),
        isFalse,
      );
    });

    test(
      'Exposed cloud API key guarantees overall score >= 90 (CRITICAL risk)',
      () {
        final apiKey = DetectedElement(
          id: 'fnd_key',
          name: 'AWS API Key',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.critical,
          confidence: 0.99,
          description: 'Plaintext IAM access key AKIA...',
          opsecImpact: 'Immediate infrastructure compromise',
          baseSensitivity: 100,
          exploitability: 1.0,
          visibilityScore: 1.0,
          evidenceText: 'AKIAIOSFODNN7EXAMPLE',
        );

        final breakdown = DeterministicRiskEngine.calculateScore(
          findings: [apiKey],
        );

        expect(breakdown.overallScore, greaterThanOrEqualTo(90));
        expect(breakdown.riskLevel, RiskLevel.critical);
        expect(breakdown.severityReason, contains('CRITICAL EXPOSURE'));
      },
    );

    test('Clean image produces zero score and clean baseline explanation', () {
      final breakdown = DeterministicRiskEngine.calculateScore(findings: []);
      expect(breakdown.overallScore, 0);
      expect(breakdown.riskLevel, RiskLevel.low);
      expect(breakdown.severityReason, contains('Zero findings'));
    });

    test('Inference synergy cannot inflate low-risk image beyond 35% of peak score', () {
      final face = DetectedElement(
        id: 'fnd_face',
        name: 'Face',
        category: ExposureCategory.identity,
        riskLevel: RiskLevel.low,
        confidence: 0.95,
        description: 'Face',
        opsecImpact: 'Face',
        baseSensitivity: 15,
        exploitability: 0.20,
        visibilityScore: 0.80,
      );

      final inferences = [
        InferredInsight(
          id: 'inf_test_1',
          category: ExposureCategory.identity,
          directObservation: 'Obs 1',
          inferredInsight: 'Insight 1',
          attackerThreatProfile: 'Threat 1',
          severity: RiskLevel.high,
          confidence: 0.99,
          supportingEvidenceIds: ['fnd_face'],
        ),
        InferredInsight(
          id: 'inf_test_2',
          category: ExposureCategory.location,
          directObservation: 'Obs 2',
          inferredInsight: 'Insight 2',
          attackerThreatProfile: 'Threat 2',
          severity: RiskLevel.high,
          confidence: 0.99,
          supportingEvidenceIds: ['fnd_face'],
        ),
      ];

      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: [face],
        inferences: inferences,
      );

      // Face standalone score is ~2. Synergy penalty must be capped at 2 * 0.35 = 0.7
      expect(
        breakdown.synergyPenalty,
        lessThanOrEqualTo(breakdown.peakCategoryScore * 0.35 + 0.1),
      );
      expect(breakdown.overallScore, lessThanOrEqualTo(10));
      expect(breakdown.riskLevel, RiskLevel.low);
    });

    test('Evaluator computes extended Section 5 metrics: FPR, FNR, Category Accuracy, MAE', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'eval_metrics_test_',
      );
      final casesFile = File('${tempDir.path}/cases.json');
      final runsFile = File('${tempDir.path}/runs.json');

      final caseRepo = ZenithTestCaseRepository(filePath: casesFile.path);
      final runRepo = ZenithTestRunRepository(filePath: runsFile.path);
      final seeder = ZenithTestCaseSeeder(caseRepo);
      await seeder.seedInitialCases();

      final evaluator = ZenithTestEvaluator(
        pipeline: ZenithAnalysisPipeline(visionProvider: MockVisionProvider()),
        testCaseRepo: caseRepo,
        testRunRepo: runRepo,
      );

      final run = await evaluator.executeSuite();
      expect(run.totalCases, 20);
      expect(run.passedCases, 20);
      expect(run.fpr, 0.0);
      expect(run.fnr, 0.0);
      expect(run.categoryAccuracy, 100.0);
      expect(run.maeScoreError, lessThanOrEqualTo(15.0));
      expect(run.precision, greaterThanOrEqualTo(0.95));
      expect(run.recall, greaterThanOrEqualTo(0.95));
      expect(run.f1Score, greaterThanOrEqualTo(0.95));

      await tempDir.delete(recursive: true);
    });

    test(
      'Missing fixture file triggers inconclusive flag without fake passing',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'inconclusive_test_',
        );
        final casesFile = File('${tempDir.path}/cases.json');
        final runsFile = File('${tempDir.path}/runs.json');

        final caseRepo = ZenithTestCaseRepository(filePath: casesFile.path);
        final runRepo = ZenithTestRunRepository(filePath: runsFile.path);

        final missingCase = ZenithTestCaseRecord(
          id: 'TC-99-MISSING',
          name: 'Case with Missing Fixture',
          description: 'Fixture is absent from storage',
          category: 'test',
          inputFixtureReference: 'non_existent_path_dir/file.png',
          expectedDetections: [],
          expectedSeverity: 'low',
          minExpectedScore: 0,
          maxExpectedScore: 25,
          expectedRecommendations: [],
          groundTruthAnnotations: [],
          evaluationCriteria: 'score_within_range',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await caseRepo.save(missingCase);

        final evaluator = ZenithTestEvaluator(
          pipeline: ZenithAnalysisPipeline(
            visionProvider: MockVisionProvider(),
          ),
          testCaseRepo: caseRepo,
          testRunRepo: runRepo,
        );

        final run = await evaluator.executeSuite(
          selectedCaseIds: ['TC-99-MISSING'],
        );
        expect(run.results.first.inconclusive, isTrue);
        expect(run.results.first.passed, isFalse);
        expect(
          run.results.first.differences.first,
          contains('missing from disk'),
        );

        await tempDir.delete(recursive: true);
      },
    );
  });
}
