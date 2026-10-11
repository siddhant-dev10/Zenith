import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/privacy_engine/testing/test_case_framework.dart';

void main() {
  group('Zenith Benchmark Test Suite (15 Standard Threat Classes)', () {
    test('Standard library contains all 15 required scenario classes', () {
      final cases = ZenithTestLibrary.getStandardTestCases();
      expect(cases.length, 15);

      final classes = cases.map((c) => c.scenarioClass).toSet();
      expect(classes.contains('Clean photographs'), true);
      expect(classes.contains('Student and employee IDs'), true);
      expect(classes.contains('Vehicle registration plates'), true);
      expect(classes.contains('Visible addresses'), true);
      expect(classes.contains('Sensitive computer screens'), true);
      expect(classes.contains('QR codes and barcodes'), true);
      expect(classes.contains('Financial documents'), true);
      expect(classes.contains('Travel documents'), true);
      expect(classes.contains('Exposed credentials'), true);
      expect(classes.contains('Metadata exposure'), true);
      expect(classes.contains('Multiple simultaneous risks'), true);
      expect(classes.contains('Blurred or obstructed information'), true);
      expect(classes.contains('Low-quality images'), true);
      expect(classes.contains('Ambiguous cases'), true);
      expect(classes.contains('False-positive scenarios'), true);
    });

    test('Automated benchmark runner executes all 15 scenarios with 100% pass rate', () async {
      final summary = await ZenithTestRunner.runBenchmarkSuite();

      // Print audit summary for test telemetry
      for (final res in summary.results) {
        if (!res.passed) {
          // ignore: avoid_print
          print('FAILED TEST: ${res.testCase.testId} - ${res.failureReason}');
        }
      }

      expect(summary.totalTests, 15);
      expect(summary.passedTests, 15);
      expect(summary.failedTests, 0);
      expect(summary.passRate, 100.0);
      expect(summary.meanAbsoluteScoreDelta <= 15.0, true);
    });
  });
}
