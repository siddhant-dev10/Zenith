/// Represents a persistent test case specification in the Zenith backend library.
class ZenithTestCaseRecord {
  final String id;
  final String name;
  final String description;
  final String category;
  final String inputFixtureReference;
  final List<ExpectedDetection> expectedDetections;
  final String expectedSeverity; // 'low', 'moderate', 'high', 'critical'
  final int minExpectedScore;
  final int maxExpectedScore;
  final List<String> expectedRecommendations;
  final List<GroundTruthAnnotation> groundTruthAnnotations;
  final String evaluationCriteria;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isEnabled;

  const ZenithTestCaseRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.inputFixtureReference,
    required this.expectedDetections,
    required this.expectedSeverity,
    required this.minExpectedScore,
    required this.maxExpectedScore,
    required this.expectedRecommendations,
    required this.groundTruthAnnotations,
    required this.evaluationCriteria,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'inputFixtureReference': inputFixtureReference,
    'expectedDetections': expectedDetections.map((e) => e.toJson()).toList(),
    'expectedSeverity': expectedSeverity,
    'minExpectedScore': minExpectedScore,
    'maxExpectedScore': maxExpectedScore,
    'expectedRecommendations': expectedRecommendations,
    'groundTruthAnnotations': groundTruthAnnotations
        .map((e) => e.toJson())
        .toList(),
    'evaluationCriteria': evaluationCriteria,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
    'isEnabled': isEnabled,
  };

  factory ZenithTestCaseRecord.fromJson(Map<String, dynamic> json) {
    return ZenithTestCaseRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      inputFixtureReference: json['inputFixtureReference'] as String,
      expectedDetections: (json['expectedDetections'] as List? ?? [])
          .map(
            (e) =>
                ExpectedDetection.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      expectedSeverity: json['expectedSeverity'] as String? ?? 'low',
      minExpectedScore: (json['minExpectedScore'] as num?)?.toInt() ?? 0,
      maxExpectedScore: (json['maxExpectedScore'] as num?)?.toInt() ?? 100,
      expectedRecommendations: (json['expectedRecommendations'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      groundTruthAnnotations: (json['groundTruthAnnotations'] as List? ?? [])
          .map(
            (e) => GroundTruthAnnotation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      evaluationCriteria:
          json['evaluationCriteria'] as String? ?? 'severity_match',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  ZenithTestCaseRecord copyWith({
    String? name,
    String? description,
    String? category,
    String? inputFixtureReference,
    List<ExpectedDetection>? expectedDetections,
    String? expectedSeverity,
    int? minExpectedScore,
    int? maxExpectedScore,
    List<String>? expectedRecommendations,
    List<GroundTruthAnnotation>? groundTruthAnnotations,
    String? evaluationCriteria,
    DateTime? updatedAt,
    int? version,
    bool? isEnabled,
  }) {
    return ZenithTestCaseRecord(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      inputFixtureReference:
          inputFixtureReference ?? this.inputFixtureReference,
      expectedDetections: expectedDetections ?? this.expectedDetections,
      expectedSeverity: expectedSeverity ?? this.expectedSeverity,
      minExpectedScore: minExpectedScore ?? this.minExpectedScore,
      maxExpectedScore: maxExpectedScore ?? this.maxExpectedScore,
      expectedRecommendations:
          expectedRecommendations ?? this.expectedRecommendations,
      groundTruthAnnotations:
          groundTruthAnnotations ?? this.groundTruthAnnotations,
      evaluationCriteria: evaluationCriteria ?? this.evaluationCriteria,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      version: version ?? this.version,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Expected detection assertion in a test case.
class ExpectedDetection {
  final String category;
  final String type;
  final double minConfidence;
  final bool isDirectExposure;

  const ExpectedDetection({
    required this.category,
    required this.type,
    this.minConfidence = 0.5,
    this.isDirectExposure = true,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'type': type,
    'minConfidence': minConfidence,
    'isDirectExposure': isDirectExposure,
  };

  factory ExpectedDetection.fromJson(Map<String, dynamic> json) {
    return ExpectedDetection(
      category: json['category'] as String,
      type: json['type'] as String,
      minConfidence: (json['minConfidence'] as num?)?.toDouble() ?? 0.5,
      isDirectExposure: json['isDirectExposure'] as bool? ?? true,
    );
  }
}

/// Ground-truth annotation with spatial coordinates.
class GroundTruthAnnotation {
  final String label;
  final String category;
  final List<double>? boundingBox; // [ymin, xmin, ymax, xmax] in 0..1
  final String? sensitiveText;

  const GroundTruthAnnotation({
    required this.label,
    required this.category,
    this.boundingBox,
    this.sensitiveText,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'category': category,
    'boundingBox': boundingBox,
    'sensitiveText': sensitiveText,
  };

  factory GroundTruthAnnotation.fromJson(Map<String, dynamic> json) {
    return GroundTruthAnnotation(
      label: json['label'] as String,
      category: json['category'] as String,
      boundingBox: (json['boundingBox'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      sensitiveText: json['sensitiveText'] as String?,
    );
  }
}

/// Execution result for an individual test case within a test run.
class TestCaseRunResultRecord {
  final String testCaseId;
  final String testCaseName;
  final String category;
  final bool passed;
  final String expectedSeverity;
  final String actualSeverity;
  final int expectedMinScore;
  final int expectedMaxScore;
  final int actualScore;
  final int scoreDelta;
  final int expectedDetectionsCount;
  final int actualDetectionsCount;
  final List<String> differences;
  final int durationMs;
  final String? error;
  final bool inconclusive;
  final double mae;

  const TestCaseRunResultRecord({
    required this.testCaseId,
    required this.testCaseName,
    required this.category,
    required this.passed,
    required this.expectedSeverity,
    required this.actualSeverity,
    required this.expectedMinScore,
    required this.expectedMaxScore,
    required this.actualScore,
    required this.scoreDelta,
    required this.expectedDetectionsCount,
    required this.actualDetectionsCount,
    required this.differences,
    required this.durationMs,
    this.error,
    this.inconclusive = false,
    this.mae = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'testCaseId': testCaseId,
    'testCaseName': testCaseName,
    'category': category,
    'passed': passed,
    'expectedSeverity': expectedSeverity,
    'actualSeverity': actualSeverity,
    'expectedMinScore': expectedMinScore,
    'expectedMaxScore': expectedMaxScore,
    'actualScore': actualScore,
    'scoreDelta': scoreDelta,
    'expectedDetectionsCount': expectedDetectionsCount,
    'actualDetectionsCount': actualDetectionsCount,
    'differences': differences,
    'durationMs': durationMs,
    'error': error,
    'inconclusive': inconclusive,
    'mae': mae,
  };

  factory TestCaseRunResultRecord.fromJson(Map<String, dynamic> json) {
    return TestCaseRunResultRecord(
      testCaseId: json['testCaseId'] as String,
      testCaseName: json['testCaseName'] as String,
      category: json['category'] as String,
      passed: json['passed'] as bool,
      expectedSeverity: json['expectedSeverity'] as String,
      actualSeverity: json['actualSeverity'] as String,
      expectedMinScore: (json['expectedMinScore'] as num).toInt(),
      expectedMaxScore: (json['expectedMaxScore'] as num).toInt(),
      actualScore: (json['actualScore'] as num).toInt(),
      scoreDelta: (json['scoreDelta'] as num).toInt(),
      expectedDetectionsCount: (json['expectedDetectionsCount'] as num).toInt(),
      actualDetectionsCount: (json['actualDetectionsCount'] as num).toInt(),
      differences: (json['differences'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      durationMs: (json['durationMs'] as num).toInt(),
      error: json['error'] as String?,
      inconclusive: json['inconclusive'] as bool? ?? false,
      mae: (json['mae'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Comprehensive summary of a persistent test run execution.
class ZenithTestRunRecord {
  final String runId;
  final DateTime timestamp;
  final int totalCases;
  final int passedCases;
  final int failedCases;
  final double passRate;
  final double precision;
  final double recall;
  final double f1Score;
  final double fpr;
  final double fnr;
  final double categoryAccuracy;
  final double maeScoreError;
  final double severityAccuracy;
  final int meanDurationMs;
  final String modelIdentifier;
  final List<TestCaseRunResultRecord> results;

  const ZenithTestRunRecord({
    required this.runId,
    required this.timestamp,
    required this.totalCases,
    required this.passedCases,
    required this.failedCases,
    required this.passRate,
    required this.precision,
    required this.recall,
    required this.f1Score,
    this.fpr = 0.0,
    this.fnr = 0.0,
    this.categoryAccuracy = 100.0,
    this.maeScoreError = 0.0,
    required this.severityAccuracy,
    required this.meanDurationMs,
    required this.modelIdentifier,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
    'runId': runId,
    'timestamp': timestamp.toIso8601String(),
    'totalCases': totalCases,
    'passedCases': passedCases,
    'failedCases': failedCases,
    'passRate': passRate,
    'precision': precision,
    'recall': recall,
    'f1Score': f1Score,
    'fpr': fpr,
    'fnr': fnr,
    'categoryAccuracy': categoryAccuracy,
    'maeScoreError': maeScoreError,
    'severityAccuracy': severityAccuracy,
    'meanDurationMs': meanDurationMs,
    'modelIdentifier': modelIdentifier,
    'results': results.map((r) => r.toJson()).toList(),
  };

  factory ZenithTestRunRecord.fromJson(Map<String, dynamic> json) {
    return ZenithTestRunRecord(
      runId: json['runId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      totalCases: (json['totalCases'] as num).toInt(),
      passedCases: (json['passedCases'] as num).toInt(),
      failedCases: (json['failedCases'] as num).toInt(),
      passRate: (json['passRate'] as num).toDouble(),
      precision: (json['precision'] as num).toDouble(),
      recall: (json['recall'] as num).toDouble(),
      f1Score: (json['f1Score'] as num).toDouble(),
      fpr: (json['fpr'] as num?)?.toDouble() ?? 0.0,
      fnr: (json['fnr'] as num?)?.toDouble() ?? 0.0,
      categoryAccuracy: (json['categoryAccuracy'] as num?)?.toDouble() ?? 100.0,
      maeScoreError: (json['maeScoreError'] as num?)?.toDouble() ?? 0.0,
      severityAccuracy: (json['severityAccuracy'] as num).toDouble(),
      meanDurationMs: (json['meanDurationMs'] as num).toInt(),
      modelIdentifier: json['modelIdentifier'] as String? ?? 'unknown',
      results: (json['results'] as List? ?? [])
          .map(
            (r) => TestCaseRunResultRecord.fromJson(
              Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList(),
    );
  }
}
