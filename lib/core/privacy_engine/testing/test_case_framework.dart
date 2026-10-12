import 'dart:typed_data';

import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/privacy_audit_report.dart';
import '../../../models/risk_level.dart';
import '../pipeline/zenith_analysis_pipeline.dart';
import '../providers/vision_analysis_provider.dart';

/// Structured specification of an automated evaluation test case.
class ZenithTestCase {
  final String testId;
  final String scenarioClass;
  final String title;
  final String description;
  final String? assetPath;
  final List<DetectedElement> fixtureFindings;
  final RiskLevel expectedSeverity;
  final int minExpectedScore;
  final int maxExpectedScore;
  final List<ExposureCategory> expectedCategories;
  final String acceptanceCriteria;

  const ZenithTestCase({
    required this.testId,
    required this.scenarioClass,
    required this.title,
    required this.description,
    this.assetPath,
    required this.fixtureFindings,
    required this.expectedSeverity,
    required this.minExpectedScore,
    required this.maxExpectedScore,
    required this.expectedCategories,
    required this.acceptanceCriteria,
  });
}

/// Result of running a single evaluation test case.
class TestCaseExecutionResult {
  final ZenithTestCase testCase;
  final PrivacyAuditReport report;
  final bool passed;
  final int scoreDelta; // Actual score - midpoint of expected range
  final String? failureReason;

  const TestCaseExecutionResult({
    required this.testCase,
    required this.report,
    required this.passed,
    required this.scoreDelta,
    this.failureReason,
  });
}

/// Comprehensive summary of an evaluation suite execution.
class BenchmarkEvaluationSummary {
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final double passRate;
  final double meanAbsoluteScoreDelta;
  final List<TestCaseExecutionResult> results;

  const BenchmarkEvaluationSummary({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.passRate,
    required this.meanAbsoluteScoreDelta,
    required this.results,
  });
}

/// Built-in library of 15 structured benchmark test cases covering the required threat scenarios.
class ZenithTestLibrary {
  static List<ZenithTestCase> getStandardTestCases() {
    return [
      // 1. Clean photographs
      const ZenithTestCase(
        testId: 'TC-01-CLEAN',
        scenarioClass: 'Clean photographs',
        title: 'Alpine Mountain Landscape',
        description: 'Nature scenery with zero human PII or credentials.',
        fixtureFindings: [],
        expectedSeverity: RiskLevel.low,
        minExpectedScore: 0,
        maxExpectedScore: 25,
        expectedCategories: [],
        acceptanceCriteria:
            'Score must remain <= 25 (Low Risk) with zero critical findings.',
      ),

      // 2. Student and employee IDs
      const ZenithTestCase(
        testId: 'TC-02-STUDENT-ID',
        scenarioClass: 'Student and employee IDs',
        title: 'Pacific State University Student ID',
        description:
            'University badge displaying legal name, ID number, and barcode.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc2_f1',
            name: 'Student ID Card',
            category: ExposureCategory.identity,
            riskLevel: RiskLevel.critical,
            confidence: 0.98,
            baseSensitivity: 85,
            exploitability: 0.9,
            visibilityScore: 1.0,
            description: 'Institutional identity card.',
            opsecImpact: 'Direct student identity exposure.',
          ),
          DetectedElement(
            id: 'tc2_f2',
            name: 'Printed Student Name',
            category: ExposureCategory.personalInfo,
            riskLevel: RiskLevel.high,
            confidence: 0.95,
            baseSensitivity: 70,
            exploitability: 0.85,
            visibilityScore: 0.95,
            evidenceText: 'Alexander Morgan',
            description: 'Full legal name.',
            opsecImpact: 'Identifiable student name.',
          ),
        ],
        expectedSeverity: RiskLevel.critical,
        minExpectedScore: 76,
        maxExpectedScore: 95,
        expectedCategories: [
          ExposureCategory.identity,
          ExposureCategory.personalInfo,
        ],
        acceptanceCriteria: 'Overall score must be >= 76 (Critical Risk).',
      ),

      // 3. Vehicle registration plates
      const ZenithTestCase(
        testId: 'TC-03-LICENSE-PLATE',
        scenarioClass: 'Vehicle registration plates',
        title: 'Parked Vehicle License Plate',
        description: 'Legible state license plate on public road.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc3_f1',
            name: 'Vehicle License Plate',
            category: ExposureCategory.transportation,
            riskLevel: RiskLevel.moderate,
            confidence: 0.95,
            baseSensitivity: 60,
            exploitability: 0.7,
            visibilityScore: 0.85,
            evidenceText: '7XYZ123',
            description: 'State license plate.',
            opsecImpact: 'Vehicle tracking vector.',
          ),
        ],
        expectedSeverity: RiskLevel.moderate,
        minExpectedScore: 26,
        maxExpectedScore: 50,
        expectedCategories: [ExposureCategory.transportation],
        acceptanceCriteria: 'Severity must register as Moderate Risk.',
      ),

      // 4. Visible addresses
      const ZenithTestCase(
        testId: 'TC-04-VISIBLE-ADDRESS',
        scenarioClass: 'Visible addresses',
        title: 'Residential House Number & Street Name',
        description: 'Suburban home with visible house number 742 and Evergreen Ter sign.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc4_f1',
            name: 'House Number Placard 742',
            category: ExposureCategory.location,
            riskLevel: RiskLevel.high,
            confidence: 0.92,
            baseSensitivity: 70,
            exploitability: 0.8,
            visibilityScore: 0.9,
            evidenceText: '742',
            description: 'Street address number.',
            opsecImpact: 'Domicile geolocation.',
          ),
          DetectedElement(
            id: 'tc4_f2',
            name: 'Municipal Street Sign',
            category: ExposureCategory.location,
            riskLevel: RiskLevel.moderate,
            confidence: 0.88,
            baseSensitivity: 55,
            exploitability: 0.7,
            visibilityScore: 0.85,
            evidenceText: 'Evergreen Ter',
            description: 'Street name sign.',
            opsecImpact: 'Street intersection doxxing.',
          ),
        ],
        expectedSeverity: RiskLevel.high,
        minExpectedScore: 51,
        maxExpectedScore: 78,
        expectedCategories: [ExposureCategory.location],
        acceptanceCriteria:
            'Location category score >= 60; Overall score >= 51 (High Risk).',
      ),

      // 5. Sensitive computer screens
      const ZenithTestCase(
        testId: 'TC-05-COMPUTER-SCREEN',
        scenarioClass: 'Sensitive computer screens',
        title: 'Developer Terminal with AWS Access Key',
        description:
            'Laptop monitor displaying terminal with plaintext AWS key.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc5_f1',
            name: 'AWS Access Key ID in Terminal',
            category: ExposureCategory.digital,
            riskLevel: RiskLevel.critical,
            confidence: 0.99,
            baseSensitivity: 100,
            exploitability: 1.0,
            visibilityScore: 0.95,
            evidenceText: 'AKIAIOSFODNN7EXAMPLE',
            description: 'Plaintext AWS root key.',
            opsecImpact: 'Cloud account takeover.',
          ),
        ],
        expectedSeverity: RiskLevel.critical,
        minExpectedScore: 90,
        maxExpectedScore: 100,
        expectedCategories: [ExposureCategory.digital],
        acceptanceCriteria:
            'Overall score must be >= 90 due to critical credential floor.',
      ),

      // 6. QR codes and barcodes
      const ZenithTestCase(
        testId: 'TC-06-BARCODES',
        scenarioClass: 'QR codes and barcodes',
        title: 'High-Density 2D Aztec Boarding Pass Barcode',
        description: 'Printed barcode containing passenger PNR and itinerary.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc6_f1',
            name: 'Aztec Travel Barcode',
            category: ExposureCategory.personalInfo,
            riskLevel: RiskLevel.critical,
            confidence: 0.98,
            baseSensitivity: 90,
            exploitability: 0.95,
            visibilityScore: 1.0,
            evidenceText:
                'M1MORGAN/ALEXANDER EK9P2X1 SFO JFK UA 0123 285Y012A0001',
            description: 'IATA BCBP barcode string.',
            opsecImpact: 'Full unencrypted itinerary data.',
          ),
        ],
        expectedSeverity: RiskLevel.critical,
        minExpectedScore: 76,
        maxExpectedScore: 95,
        expectedCategories: [ExposureCategory.personalInfo],
        acceptanceCriteria: 'Barcode must trigger Critical severity and solid censor mitigation.',
      ),

      // 7. Financial documents
      const ZenithTestCase(
        testId: 'TC-07-FINANCIAL-DOCS',
        scenarioClass: 'Financial documents',
        title: 'Credit Card Primary Account Number',
        description:
            'Payment card with embossed 16-digit card number and expiry.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc7_f1',
            name: 'Payment Card Number (PAN)',
            category: ExposureCategory.personalInfo,
            riskLevel: RiskLevel.critical,
            confidence: 0.99,
            baseSensitivity: 98,
            exploitability: 0.98,
            visibilityScore: 0.95,
            evidenceText: '4111 2222 3333 4444',
            description: 'Unmasked Visa payment card number.',
            opsecImpact: 'Fraudulent financial card charges.',
          ),
        ],
        expectedSeverity: RiskLevel.critical,
        minExpectedScore: 90,
        maxExpectedScore: 100,
        expectedCategories: [ExposureCategory.personalInfo],
        acceptanceCriteria: 'Score >= 90; immediate DO NOT SHARE mitigation.',
      ),

      // 8. Travel documents
      const ZenithTestCase(
        testId: 'TC-08-TRAVEL-DOCS',
        scenarioClass: 'Travel documents',
        title: 'Airline Boarding Pass PNR & Route',
        description:
            'Passenger ticket displaying PNR K9P2X1 and departure flight date.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc8_f1',
            name: 'Booking Confirmation Code (PNR)',
            category: ExposureCategory.transportation,
            riskLevel: RiskLevel.critical,
            confidence: 0.96,
            baseSensitivity: 88,
            exploitability: 0.9,
            visibilityScore: 0.95,
            evidenceText: 'K9P2X1',
            description: 'Airline reservation locator.',
            opsecImpact: 'Flight cancellation and itinerary hijack.',
          ),
        ],
        expectedSeverity: RiskLevel.critical,
        minExpectedScore: 76,
        maxExpectedScore: 95,
        expectedCategories: [ExposureCategory.transportation],
        acceptanceCriteria: 'Deduces absence and flight hijacking vector.',
      ),

      // 9. Exposed credentials
      const ZenithTestCase(
        testId: 'TC-09-EXPOSED-CREDENTIALS',
        scenarioClass: 'Exposed credentials',
        title: 'Sticky Note with Wi-Fi Password & Alarm Code',
        description: 'Desk monitor bezel with handwritten network credentials.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc9_f1',
            name: 'Wi-Fi Password & Security PIN',
            category: ExposureCategory.digital,
            riskLevel: RiskLevel.critical,
            confidence: 0.98,
            baseSensitivity: 98,
            exploitability: 0.98,
            visibilityScore: 1.0,
            evidenceText: 'Pass: CorpSecret2026! PIN: 4891',
            description: 'Handwritten credentials.',
            opsecImpact:
                'Local Wi-Fi network and physical security compromise.',
          ),
        ],
        expectedSeverity: RiskLevel.critical,
        minExpectedScore: 85,
        maxExpectedScore: 100,
        expectedCategories: [ExposureCategory.digital],
        acceptanceCriteria: 'Generates solid censor recommendation.',
      ),

      // 10. Metadata exposure
      const ZenithTestCase(
        testId: 'TC-10-METADATA-EXPOSURE',
        scenarioClass: 'Metadata exposure',
        title: 'Photo with High-Precision GPS EXIF Tags',
        description:
            'Ordinary room photo containing lat/long coordinates in headers.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc10_f1',
            name: 'Embedded EXIF GPS Coordinates',
            category: ExposureCategory.location,
            riskLevel: RiskLevel.high,
            confidence: 1.0,
            baseSensitivity: 70,
            exploitability: 0.9,
            visibilityScore: 1.0,
            evidenceText: '37.7749° N, 122.4194° W',
            description: 'Precise hardware GPS tag.',
            opsecImpact: 'Physical location tracking down to 3 meters.',
          ),
        ],
        expectedSeverity: RiskLevel.high,
        minExpectedScore: 51,
        maxExpectedScore: 75,
        expectedCategories: [ExposureCategory.location],
        acceptanceCriteria: 'Triggers EXIF scrub recommendation.',
      ),

      // 11. Multiple simultaneous risks
      const ZenithTestCase(
        testId: 'TC-11-COMPOUND-RISKS',
        scenarioClass: 'Multiple simultaneous risks',
        title: 'Multi-Vector Compound Exposure',
        description:
            'Student badge + campus street sign + timetable calendar on phone.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc11_f1',
            name: 'Student ID Badge',
            category: ExposureCategory.identity,
            riskLevel: RiskLevel.high,
            confidence: 0.94,
            baseSensitivity: 75,
            exploitability: 0.8,
            visibilityScore: 0.9,
            description: 'University badge.',
            opsecImpact: 'Institutional affiliation.',
          ),
          DetectedElement(
            id: 'tc11_f2',
            name: 'Campus Street Sign',
            category: ExposureCategory.location,
            riskLevel: RiskLevel.moderate,
            confidence: 0.90,
            baseSensitivity: 50,
            exploitability: 0.7,
            visibilityScore: 0.8,
            description: 'Campus road sign.',
            opsecImpact: 'Location context.',
          ),
          DetectedElement(
            id: 'tc11_f3',
            name: 'Phone Timetable Screen',
            category: ExposureCategory.digital,
            riskLevel: RiskLevel.moderate,
            confidence: 0.85,
            baseSensitivity: 45,
            exploitability: 0.6,
            visibilityScore: 0.75,
            description: 'Daily schedule visible.',
            opsecImpact: 'Routine pattern deduction.',
          ),
        ],
        expectedSeverity: RiskLevel.high,
        minExpectedScore: 55,
        maxExpectedScore: 85,
        expectedCategories: [
          ExposureCategory.identity,
          ExposureCategory.location,
          ExposureCategory.digital,
        ],
        acceptanceCriteria:
            'Compound synergy penalty elevates overall risk score.',
      ),

      // 12. Blurred or obstructed information
      const ZenithTestCase(
        testId: 'TC-12-BLURRED-INFO',
        scenarioClass: 'Blurred or obstructed information',
        title: 'Heavily Defocused Employee Badge',
        description:
            'Badge outline visible but text completely illegible due to bokeh.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc12_f1',
            name: 'Defocused Badge Silhouette',
            category: ExposureCategory.identity,
            riskLevel: RiskLevel.low,
            confidence: 0.60,
            baseSensitivity: 40,
            exploitability: 0.3,
            visibilityScore: 0.2, // Low visibility damping
            description: 'Out of focus badge outline.',
            opsecImpact: 'Unclear badge text.',
          ),
        ],
        expectedSeverity: RiskLevel.low,
        minExpectedScore: 0,
        maxExpectedScore: 25,
        expectedCategories: [ExposureCategory.identity],
        acceptanceCriteria:
            'Low visibility score damps risk below Moderate threshold.',
      ),

      // 13. Low-quality images
      const ZenithTestCase(
        testId: 'TC-13-LOW-QUALITY',
        scenarioClass: 'Low-quality images',
        title: 'Low Resolution CCTV Monitor Snapshot',
        description: 'Pixelated screen showing faint terminal prompt.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc13_f1',
            name: 'Pixelated Monitor Silhouette',
            category: ExposureCategory.digital,
            riskLevel: RiskLevel.low,
            confidence: 0.65,
            baseSensitivity: 35,
            exploitability: 0.4,
            visibilityScore: 0.3,
            description: 'Heavy compression noise.',
            opsecImpact: 'Low exploitability due to illegibility.',
          ),
        ],
        expectedSeverity: RiskLevel.low,
        minExpectedScore: 0,
        maxExpectedScore: 25,
        expectedCategories: [ExposureCategory.digital],
        acceptanceCriteria: 'Score does not exceed 25 points.',
      ),

      // 14. Ambiguous cases
      const ZenithTestCase(
        testId: 'TC-14-AMBIGUOUS',
        scenarioClass: 'Ambiguous cases',
        title: 'Plain Solid Color Lanyard without Card',
        description: 'Blue fabric lanyard with no attached card or text.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc14_f1',
            name: 'Plain Fabric Neck Lanyard',
            category: ExposureCategory.identity,
            riskLevel: RiskLevel.low,
            confidence: 0.70,
            baseSensitivity: 20,
            exploitability: 0.2,
            visibilityScore: 0.7,
            description: 'No badge attached.',
            opsecImpact: 'Ambiguous accessory.',
          ),
        ],
        expectedSeverity: RiskLevel.low,
        minExpectedScore: 0,
        maxExpectedScore: 20,
        expectedCategories: [ExposureCategory.identity],
        acceptanceCriteria:
            'Must not trigger false positive credential breach.',
      ),

      // 15. False-positive scenarios
      const ZenithTestCase(
        testId: 'TC-15-FALSE-POSITIVE',
        scenarioClass: 'False-positive scenarios',
        title: 'Barcode Graphic on Grocery Cereal Box',
        description: 'Commercial retail UPC barcode on grocery food packaging.',
        fixtureFindings: [
          DetectedElement(
            id: 'tc15_f1',
            name: 'Retail Food UPC Barcode',
            category: ExposureCategory.personalInfo,
            riskLevel: RiskLevel.low,
            confidence: 0.95,
            baseSensitivity: 10, // Retail product, not personal
            exploitability: 0.2,
            visibilityScore: 0.9,
            evidenceText: '012345678905',
            description: 'Public commercial consumer goods barcode.',
            opsecImpact: 'Zero personal data contained.',
          ),
        ],
        expectedSeverity: RiskLevel.low,
        minExpectedScore: 0,
        maxExpectedScore: 20,
        expectedCategories: [ExposureCategory.personalInfo],
        acceptanceCriteria:
            'Public retail barcode does not trigger privacy warning.',
      ),
    ];
  }
}

/// Evaluation runner that executes test cases through Zenith's deterministic engine.
class ZenithTestRunner {
  /// Executes a single test case against the deterministic pipeline.
  static Future<TestCaseExecutionResult> runTestCase(
    ZenithTestCase testCase,
    ZenithAnalysisPipeline pipeline,
  ) async {
    // Generate simulated image bytes (valid minimal PNG header)
    final dummyPngBytes = _createDummyPng();

    final report = await pipeline.execute(
      imageBytes: dummyPngBytes,
      sampleAsset: testCase.assetPath,
    );

    // Evaluate assertions
    final score = report.overallScore;
    final expectedMidpoint =
        (testCase.minExpectedScore + testCase.maxExpectedScore) / 2.0;
    final scoreDelta = (score - expectedMidpoint).round();

    bool passed = true;
    String? failureReason;

    // Check 1: Score range
    if (score < testCase.minExpectedScore ||
        score > testCase.maxExpectedScore) {
      passed = false;
      failureReason =
          'Score $score out of expected range [${testCase.minExpectedScore}, ${testCase.maxExpectedScore}].';
    }

    // Check 2: Expected severity
    if (passed && report.riskLevel != testCase.expectedSeverity) {
      passed = false;
      failureReason =
          'Severity ${report.riskLevel.label} did not match expected ${testCase.expectedSeverity.label}.';
    }

    return TestCaseExecutionResult(
      testCase: testCase,
      report: report,
      passed: passed,
      scoreDelta: scoreDelta,
      failureReason: failureReason,
    );
  }

  /// Runs all standard test cases and compiles a benchmark summary.
  static Future<BenchmarkEvaluationSummary> runBenchmarkSuite() async {
    final testCases = ZenithTestLibrary.getStandardTestCases();
    final results = <TestCaseExecutionResult>[];
    int totalDelta = 0;

    for (final tc in testCases) {
      // Use MockVisionProvider pre-loaded with the test case's fixture findings
      final mockProvider = MockVisionProvider(
        customFindings: tc.fixtureFindings,
        customSceneDescription: tc.description,
      );
      final pipeline = ZenithAnalysisPipeline(visionProvider: mockProvider);

      final res = await runTestCase(tc, pipeline);
      results.add(res);
      totalDelta += res.scoreDelta.abs();
    }

    final passedCount = results.where((r) => r.passed).length;
    final failedCount = results.length - passedCount;
    final passRate = (passedCount / results.length) * 100.0;
    final meanDelta = totalDelta / results.length;

    return BenchmarkEvaluationSummary(
      totalTests: results.length,
      passedTests: passedCount,
      failedTests: failedCount,
      passRate: passRate,
      meanAbsoluteScoreDelta: meanDelta,
      results: results,
    );
  }

  /// Creates a minimal 67-byte valid PNG header for in-memory pipeline tests.
  static Uint8List _createDummyPng() {
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52, // IHDR chunk length & type
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4, // 8-bit depth, color type, CRC
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, // Deflate stream
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
      0x42, 0x60, 0x82,
    ]);
  }
}
