import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/models/detected_element.dart';
import 'package:zenith/models/exposure_category.dart';
import 'package:zenith/models/privacy_audit_report.dart';
import 'package:zenith/models/recommendation.dart';
import 'package:zenith/models/risk_level.dart';
import 'package:zenith/services/mock_analysis_service.dart';
import 'package:zenith/services/sample_data_service.dart';

void main() {
  group('Zenith Risk Scoring & Model Tests', () {
    test('RiskLevel classification matches PRD criteria', () {
      expect(RiskLevel.fromScore(0), RiskLevel.low);
      expect(RiskLevel.fromScore(25), RiskLevel.low);
      expect(RiskLevel.fromScore(26), RiskLevel.moderate);
      expect(RiskLevel.fromScore(50), RiskLevel.moderate);
      expect(RiskLevel.fromScore(51), RiskLevel.high);
      expect(RiskLevel.fromScore(75), RiskLevel.high);
      expect(RiskLevel.fromScore(76), RiskLevel.critical);
      expect(RiskLevel.fromScore(100), RiskLevel.critical);
    });

    test('RiskLevel labels and descriptions are correctly populated', () {
      expect(RiskLevel.low.label, 'Low Risk');
      expect(RiskLevel.moderate.label, 'Moderate Risk');
      expect(RiskLevel.high.label, 'High Risk');
      expect(RiskLevel.critical.label, 'Critical Risk');
    });

    test('ExposureCategory mappings are complete across all 5 domains', () {
      expect(ExposureCategory.values.length, 5);
      expect(ExposureCategory.fromString('identity'), ExposureCategory.identity);
      expect(ExposureCategory.fromString('location'), ExposureCategory.location);
      expect(ExposureCategory.fromString('digital'), ExposureCategory.digital);
      expect(ExposureCategory.fromString('personal_info'), ExposureCategory.personalInfo);
      expect(ExposureCategory.fromString('transportation'), ExposureCategory.transportation);
    });

    test('SampleDataService returns all 5 realistic scenarios with OPSEC metrics', () {
      final scenarios = SampleDataService.getScenarios();
      expect(scenarios.length, 5);

      // 1. Student ID
      final studentId = scenarios.firstWhere((s) => s.id == 'sample_student_id');
      expect(studentId.expectedRiskScore, 88);
      expect(studentId.riskLevel, RiskLevel.critical);
      expect(studentId.report.detectedElements.length, 5);

      // 2. Boarding Pass
      final boardingPass = scenarios.firstWhere((s) => s.id == 'sample_boarding_pass');
      expect(boardingPass.expectedRiskScore, 92);
      expect(boardingPass.riskLevel, RiskLevel.critical);
      expect(boardingPass.report.categoryScores[ExposureCategory.transportation], 98);

      // 3. Workstation Credentials Leak
      final workstation = scenarios.firstWhere((s) => s.id == 'sample_workstation_screen');
      expect(workstation.expectedRiskScore, 96);
      expect(workstation.riskLevel, RiskLevel.critical);
      expect(workstation.report.categoryScores[ExposureCategory.digital], 99);

      // 4. Suburban House
      final streetHouse = scenarios.firstWhere((s) => s.id == 'sample_street_house');
      expect(streetHouse.expectedRiskScore, 72);
      expect(streetHouse.riskLevel, RiskLevel.high);
      expect(streetHouse.report.categoryScores[ExposureCategory.location], 92);

      // 5. Clean Landscape (Safe baseline)
      final clean = scenarios.firstWhere((s) => s.id == 'sample_clean_landscape');
      expect(clean.expectedRiskScore, 8);
      expect(clean.riskLevel, RiskLevel.low);
    });

    test('BoundingBox geometry conversions are accurate', () {
      const box = BoundingBox(left: 0.1, top: 0.2, width: 0.5, height: 0.4);
      final json = box.toJson();
      final decoded = BoundingBox.fromJson(json);

      expect(decoded.left, 0.1);
      expect(decoded.top, 0.2);
      expect(decoded.width, 0.5);
      expect(decoded.height, 0.4);
    });

    test('Recommendation model supports completed toggle', () {
      const rec = Recommendation(
        id: 'rec_1',
        priority: RiskLevel.high,
        title: 'Blur license plate',
        action: 'Apply blur filter',
        type: 'blur',
        isCompleted: false,
      );

      final completed = rec.copyWith(isCompleted: true);
      expect(completed.isCompleted, true);
      expect(completed.title, rec.title);
    });

    test('MockAnalysisService generates valid heuristic report for custom uploads', () async {
      final report = await MockAnalysisService.analyzeImage();
      expect(report.overallScore > 0, true);
      expect(report.detectedElements.isNotEmpty, true);
      expect(report.inferredInsights.isNotEmpty, true);
      expect(report.recommendations.isNotEmpty, true);
      expect(report.categoryScores.containsKey(ExposureCategory.identity), true);
    });
  });
}
