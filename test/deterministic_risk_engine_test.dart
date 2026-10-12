import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/privacy_engine/scoring/deterministic_risk_engine.dart';
import 'package:zenith/models/detected_element.dart';
import 'package:zenith/models/exposure_category.dart';
import 'package:zenith/models/inferred_insight.dart';
import 'package:zenith/models/risk_level.dart';

void main() {
  group('DeterministicRiskEngine Core Formulation Tests', () {
    test('Zero findings produces exactly 0 overall score and Low Risk', () {
      final breakdown = DeterministicRiskEngine.calculateScore(findings: []);
      expect(breakdown.overallScore, 0);
      expect(breakdown.riskLevel, RiskLevel.low);
      expect(breakdown.peakCategoryScore, 0);
      expect(breakdown.meanCategoryScore, 0.0);
      expect(breakdown.synergyPenalty, 0.0);
      for (final cat in ExposureCategory.values) {
        expect(breakdown.categoryScores[cat], 0);
      }
    });

    test('Score is strictly bounded in [0, 100]', () {
      // Create massive number of high-risk findings to test upper bound
      final massiveFindings = List.generate(
        30,
        (i) => DetectedElement(
          id: 'crit_$i',
          name: 'Critical Exposure Item $i',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.critical,
          confidence: 0.99,
          baseSensitivity: 95,
          exploitability: 0.95,
          visibilityScore: 1.0,
          description: 'High risk element',
          opsecImpact: 'Severe threat',
        ),
      );

      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: massiveFindings,
      );

      expect(breakdown.overallScore <= 100, true);
      expect(breakdown.overallScore >= 0, true);
      expect(breakdown.categoryScores[ExposureCategory.digital]! <= 100, true);
    });

    test('Monotonicity holds: adding risks never reduces score', () {
      const finding1 = DetectedElement(
        id: 'f1',
        name: 'Municipal Street Sign',
        category: ExposureCategory.location,
        riskLevel: RiskLevel.moderate,
        confidence: 0.85,
        baseSensitivity: 45,
        exploitability: 0.6,
        visibilityScore: 0.8,
        description: 'Street sign',
        opsecImpact: 'Location cue',
      );

      const finding2 = DetectedElement(
        id: 'f2',
        name: 'House Number Placard',
        category: ExposureCategory.location,
        riskLevel: RiskLevel.high,
        confidence: 0.90,
        baseSensitivity: 70,
        exploitability: 0.8,
        visibilityScore: 0.9,
        description: 'House number',
        opsecImpact: 'Address cue',
      );

      final score1 = DeterministicRiskEngine.calculateScore(
        findings: [finding1],
      );
      final score2 = DeterministicRiskEngine.calculateScore(
        findings: [finding1, finding2],
      );

      expect(score2.overallScore >= score1.overallScore, true);
      expect(
        score2.categoryScores[ExposureCategory.location]! >=
            score1.categoryScores[ExposureCategory.location]!,
        true,
      );
    });

    test('Critical credential floor guarantees score >= 90', () {
      const awsKey = DetectedElement(
        id: 'aws_key',
        name: 'Plaintext AWS Secret Key',
        category: ExposureCategory.digital,
        riskLevel: RiskLevel.critical,
        confidence: 0.98,
        baseSensitivity: 100,
        exploitability: 1.0,
        visibilityScore: 0.95,
        evidenceText: 'AKIAIOSFODNN7EXAMPLE',
        description: 'AWS API root key',
        opsecImpact: 'Direct infrastructure compromise',
      );

      // Even if it is the ONLY finding and other 4 categories are zero
      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: [awsKey],
      );
      expect(breakdown.overallScore >= 90, true);
      expect(breakdown.riskLevel, RiskLevel.critical);
    });

    test('Spatial IoU deduplication merges overlapping detections and prevents double-penalties', () {
      // Two detectors identifying the same student ID badge in almost the same bounding box
      const detectorA = DetectedElement(
        id: 'ocr_badge',
        name: 'Student ID Card (OCR)',
        category: ExposureCategory.identity,
        riskLevel: RiskLevel.high,
        confidence: 0.95,
        baseSensitivity: 75,
        exploitability: 0.8,
        visibilityScore: 0.9,
        description: 'Student badge',
        opsecImpact: 'Identity exposure',
        boundingBox: BoundingBox(
          left: 0.10,
          top: 0.20,
          width: 0.40,
          height: 0.30,
        ),
      );

      const detectorB = DetectedElement(
        id: 'gemini_badge',
        name: 'University Student Badge (AI Vision)',
        category: ExposureCategory.identity,
        riskLevel: RiskLevel.high,
        confidence: 0.92,
        baseSensitivity: 80,
        exploitability: 0.85,
        visibilityScore: 0.95,
        description: 'University ID',
        opsecImpact: 'Student record access',
        boundingBox: BoundingBox(
          left: 0.11,
          top: 0.21,
          width: 0.39,
          height: 0.29,
        ),
      );

      // Raw list contains 2 overlapping detections
      final deduplicated = DeterministicRiskEngine.deduplicateFindings([
        detectorA,
        detectorB,
      ]);

      // Deduplication should merge them into 1
      expect(deduplicated.length, 1);
      final merged = deduplicated.first;
      // Inherits peak sensitivity and confidence
      expect(merged.baseSensitivity, 80);
      expect(merged.confidence, 0.95);
      expect(merged.exploitability, 0.85);

      // Score for deduplicated should match single consolidated assessment
      final scoreWithDuplicates = DeterministicRiskEngine.calculateScore(
        findings: [detectorA, detectorB],
      );
      final scoreSingle = DeterministicRiskEngine.calculateScore(
        findings: [merged],
      );

      expect(scoreWithDuplicates.overallScore, scoreSingle.overallScore);
    });

    test('Inference synergy penalty elevates compound risk posture', () {
      const badge = DetectedElement(
        id: 'badge',
        name: 'Campus Badge',
        category: ExposureCategory.identity,
        riskLevel: RiskLevel.high,
        confidence: 0.90,
        baseSensitivity: 70,
        exploitability: 0.8,
        visibilityScore: 0.9,
        description: 'Campus ID',
        opsecImpact: 'Affiliation',
      );

      const inference = InferredInsight(
        id: 'inf_1',
        category: ExposureCategory.identity,
        directObservation: 'Campus badge',
        inferredInsight: 'Class schedule and physical routine',
        attackerThreatProfile: 'Stalking vector',
        severity: RiskLevel.high,
        confidence: 0.90,
      );

      final scoreWithoutInference = DeterministicRiskEngine.calculateScore(
        findings: [badge],
        inferences: [],
      );

      final scoreWithInference = DeterministicRiskEngine.calculateScore(
        findings: [badge],
        inferences: [inference],
      );

      expect(
        scoreWithInference.overallScore > scoreWithoutInference.overallScore,
        true,
      );
      expect(scoreWithInference.synergyPenalty, 4.5); // 5.0 * 0.90
    });
  });

  group('Worked Scoring Examples Calibration Tests', () {
    test(
      'Worked Example 1: Ordinary Clean Photograph is Low Risk (Score <= 25)',
      () {
        const scenicFinding = DetectedElement(
          id: 'f1',
          name: 'Natural Mountain Landscape',
          category: ExposureCategory.location,
          riskLevel: RiskLevel.low,
          confidence: 0.99,
          baseSensitivity: 5,
          exploitability: 0.2,
          visibilityScore: 1.0,
          description: 'Scenic nature park',
          opsecImpact: 'Negligible threat',
        );

        final breakdown = DeterministicRiskEngine.calculateScore(
          findings: [scenicFinding],
        );

        expect(breakdown.overallScore <= 25, true);
        expect(breakdown.riskLevel, RiskLevel.low);
      },
    );

    test('Worked Example 2: Vehicle License Plate in Public is Moderate Risk (26 - 50)', () {
      const plateFinding = DetectedElement(
        id: 'f_plate',
        name: 'Vehicle License Plate',
        category: ExposureCategory.transportation,
        riskLevel: RiskLevel.moderate,
        confidence: 0.96,
        baseSensitivity: 70,
        exploitability: 0.8,
        visibilityScore: 0.9,
        evidenceText: 'CALIFORNIA 7XYZ123',
        description: 'Parked car registration plate',
        opsecImpact: 'Owner registration lookup vector',
      );

      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: [plateFinding],
      );

      expect(breakdown.overallScore >= 26, true);
      expect(breakdown.overallScore <= 50, true);
      expect(breakdown.riskLevel, RiskLevel.moderate);
      expect(
        breakdown.categoryScores[ExposureCategory.transportation]! >= 40,
        true,
      );
    });

    test('Worked Example 3: Student ID Card is Critical Risk (76 - 100)', () {
      final studentIdFindings = [
        const DetectedElement(
          id: 'stu_name',
          name: 'Full Legal Name',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.high,
          confidence: 0.98,
          baseSensitivity: 65,
          exploitability: 0.8,
          visibilityScore: 1.0,
          evidenceText: 'Alexander Morgan',
          description: 'Student name',
          opsecImpact: 'PII exposure',
        ),
        const DetectedElement(
          id: 'stu_id',
          name: 'Student ID Number',
          category: ExposureCategory.identity,
          riskLevel: RiskLevel.high,
          confidence: 0.96,
          baseSensitivity: 75,
          exploitability: 0.85,
          visibilityScore: 1.0,
          evidenceText: '9948201',
          description: 'University registration number',
          opsecImpact: 'Portal credential',
        ),
        const DetectedElement(
          id: 'stu_barcode',
          name: 'Institutional Barcode',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.critical,
          confidence: 0.99,
          baseSensitivity: 85,
          exploitability: 0.95,
          visibilityScore: 1.0,
          description: 'Scannable barcode',
          opsecImpact: 'Physical badge cloning',
        ),
      ];

      const studentInference = InferredInsight(
        id: 'inf_stu',
        category: ExposureCategory.identity,
        directObservation: 'Student card and name',
        inferredInsight: 'Pacific State University enrollment class of 2027',
        attackerThreatProfile: 'Campus spear-phishing',
        severity: RiskLevel.high,
        confidence: 0.95,
      );

      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: studentIdFindings,
        inferences: [studentInference],
      );

      expect(breakdown.overallScore >= 76, true);
      expect(breakdown.riskLevel, RiskLevel.critical);
    });

    test('Worked Example 4: Laptop Screen Credentials Leak is Critical Risk (>= 90)', () {
      final credentialsFindings = [
        const DetectedElement(
          id: 'aws_key',
          name: 'Cloud API Secret Key',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.critical,
          confidence: 0.98,
          baseSensitivity: 100,
          exploitability: 1.0,
          visibilityScore: 0.95,
          evidenceText: 'AKIAIOSFODNN7EXAMPLE',
          description: 'AWS access key',
          opsecImpact: 'Direct account takeover',
        ),
        const DetectedElement(
          id: 'db_uri',
          name: 'Database Connection URI',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.critical,
          confidence: 0.95,
          baseSensitivity: 95,
          exploitability: 0.95,
          visibilityScore: 0.90,
          evidenceText: 'postgres://admin:pass@db.prod.internal:5432/core',
          description: 'Database connection string',
          opsecImpact: 'Database extraction',
        ),
      ];

      final breakdown = DeterministicRiskEngine.calculateScore(
        findings: credentialsFindings,
      );

      expect(breakdown.overallScore >= 90, true);
      expect(breakdown.riskLevel, RiskLevel.critical);
      expect(breakdown.categoryScores[ExposureCategory.digital]! >= 95, true);
    });
  });
}
