import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import 'package:zenith/core/privacy_engine/providers/vision_analysis_provider.dart';
import 'package:zenith/core/privacy_engine/testing/test_case_repository.dart';
import 'package:zenith/core/privacy_engine/testing/test_evaluator.dart';

void main() {
  group('Zenith Evaluation Engine & Persistent Repository Tests', () {
    late Directory tempDir;
    late File testCasesFile;
    late File testRunsFile;
    late ZenithTestCaseRepository caseRepo;
    late ZenithTestRunRepository runRepo;
    late ZenithAnalysisPipeline pipeline;
    late ZenithTestEvaluator evaluator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zenith_eval_test_');
      testCasesFile = File('${tempDir.path}/test_cases.json');
      testRunsFile = File('${tempDir.path}/test_runs.json');

      caseRepo = ZenithTestCaseRepository(filePath: testCasesFile.path);
      runRepo = ZenithTestRunRepository(filePath: testRunsFile.path);

      // Seed standard 20 cases into temp file
      final seeder = ZenithTestCaseSeeder(caseRepo);
      await seeder.seedInitialCases();

      pipeline = ZenithAnalysisPipeline(visionProvider: MockVisionProvider());
      evaluator = ZenithTestEvaluator(
        pipeline: pipeline,
        testCaseRepo: caseRepo,
        testRunRepo: runRepo,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Seeder populates exactly 20 distinct threat classes', () async {
      final cases = await caseRepo.getAll();
      // ignore: avoid_print
      print('FOUND ${cases.length} CASES: ${cases.map((c) => c.id).toList()}');
      expect(cases.length, 20);

      final ids = cases.map((c) => c.id).toSet();
      expect(ids.length, 20);
      expect(ids.contains('TC-01-CLEAN'), isTrue);
      expect(ids.contains('TC-20-DEGRADED-DETECTOR'), isTrue);
    });

    test('Seeder is idempotent on subsequent executions', () async {
      final seeder = ZenithTestCaseSeeder(caseRepo);
      final added = await seeder.seedInitialCases();
      expect(added, 0);

      final cases = await caseRepo.getAll();
      expect(cases.length, 20);
    });

    test(
      'Fetch test case by ID retrieves expected record and annotations',
      () async {
        final tc01 = await caseRepo.getById('TC-01-CLEAN');
        expect(tc01, isNotNull);
        expect(tc01!.name, contains('Clean'));
        expect(tc01.category, 'clean_photographs');
        expect(tc01.expectedSeverity, 'low');
      },
    );

    test('Evaluator runs entire 20-category suite and computes precision, recall, F1', () async {
      final run = await evaluator.executeSuite();

      for (final r in run.results) {
        if (!r.passed) {
          // ignore: avoid_print
          print(
            'FAILED: ${r.testCaseId} (${r.testCaseName}): diffs=${r.differences}, score=${r.actualScore} (expected [${r.expectedMinScore}-${r.expectedMaxScore}]), sev=${r.actualSeverity} (expected ${r.expectedSeverity})',
          );
        }
      }

      expect(run.totalCases, 20);
      expect(run.passedCases, 20);
      expect(run.failedCases, 0);
      expect(run.passRate, 100.0);
      expect(run.precision, greaterThanOrEqualTo(0.95));
      expect(run.recall, greaterThanOrEqualTo(0.95));
      expect(run.f1Score, greaterThanOrEqualTo(0.95));
      expect(run.severityAccuracy, 100.0);
      expect(run.results.length, 20);

      // Verify persistence of run record
      final recent = await runRepo.getAllRuns();
      expect(recent.length, 1);
      expect(recent.first.runId, run.runId);
      expect(recent.first.passRate, 100.0);
    });
  });
}
