import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../models/privacy_audit_report.dart';
import '../pipeline/zenith_analysis_pipeline.dart';
import '../providers/vision_analysis_provider.dart';
import '../testing/test_case_models.dart';
import '../testing/test_case_repository.dart';
import '../testing/test_evaluator.dart';

/// Request DTO submitted by the external Camera Application to Zenith.
class AnalyzeImageRequest {
  final Uint8List imageBytes;
  final String? clientRequestId;
  final String
  sensitivityProfile; // 'conservative', 'balanced', 'maximum_opsec'
  final String clientVersion;

  const AnalyzeImageRequest({
    required this.imageBytes,
    this.clientRequestId,
    this.sensitivityProfile = 'balanced',
    this.clientVersion = '1.0.0',
  });
}

/// Structured response DTO returned to the external Camera Application.
class AnalyzeImageResponse {
  final String analysisId;
  final DateTime timestamp;
  final int processingDurationMs;
  final String engineVersion;
  final bool degradedAnalysis;
  final int overallScore;
  final String severityLevel;
  final String headline;
  final String executiveSummary;
  final Map<String, int> categoryScores;
  final List<Map<String, dynamic>> findings;
  final List<Map<String, dynamic>> inferences;
  final List<Map<String, dynamic>> recommendations;
  final String processingStatus;
  final List<String> analysisLimitations;
  final List<String> processingErrors;

  const AnalyzeImageResponse({
    required this.analysisId,
    required this.timestamp,
    required this.processingDurationMs,
    required this.engineVersion,
    required this.degradedAnalysis,
    required this.overallScore,
    required this.severityLevel,
    required this.headline,
    required this.executiveSummary,
    required this.categoryScores,
    required this.findings,
    required this.inferences,
    required this.recommendations,
    this.processingStatus = 'completed',
    this.analysisLimitations = const [],
    this.processingErrors = const [],
  });

  factory AnalyzeImageResponse.fromReport(PrivacyAuditReport report) {
    return AnalyzeImageResponse(
      analysisId: report.id,
      timestamp: report.timestamp,
      processingDurationMs: report.scanDurationMs,
      engineVersion: 'zenith-core-1.0.0',
      degradedAnalysis:
          !report.isLiveAi || report.processingStatus != 'completed',
      overallScore: report.overallScore,
      severityLevel: report.riskLevel.label.toUpperCase(),
      headline: report.title,
      executiveSummary: report.summary,
      categoryScores: report.categoryScores.map((k, v) => MapEntry(k.id, v)),
      findings: report.detectedElements.map((e) => e.toJson()).toList(),
      inferences: report.inferredInsights.map((i) => i.toJson()).toList(),
      recommendations: report.recommendations.map((r) => r.toJson()).toList(),
      processingStatus: report.processingStatus,
      analysisLimitations: report.analysisLimitations,
      processingErrors: report.processingErrors,
    );
  }

  factory AnalyzeImageResponse.fromJson(Map<String, dynamic> json) {
    final riskAssessment =
        json['riskAssessment'] as Map<String, dynamic>? ?? {};
    final catScoresRaw =
        riskAssessment['categoryScores'] as Map<String, dynamic>? ?? {};
    final categoryScores = catScoresRaw.map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );

    return AnalyzeImageResponse(
      analysisId: json['analysisId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      processingDurationMs:
          (json['processingDurationMs'] as num?)?.toInt() ?? 0,
      engineVersion: json['engineVersion'] as String? ?? 'zenith-core-1.0.0',
      degradedAnalysis: json['degradedAnalysis'] as bool? ?? false,
      overallScore: (riskAssessment['overallScore'] as num?)?.toInt() ?? 0,
      severityLevel: riskAssessment['severityLevel'] as String? ?? 'LOW',
      headline: riskAssessment['headline'] as String? ?? '',
      executiveSummary: riskAssessment['executiveSummary'] as String? ?? '',
      categoryScores: categoryScores,
      findings: (json['findings'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      inferences: (json['inferredInsights'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      processingStatus: json['processingStatus'] as String? ?? 'completed',
      analysisLimitations: (json['analysisLimitations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      processingErrors: (json['processingErrors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'analysisId': analysisId,
    'timestamp': timestamp.toIso8601String(),
    'processingDurationMs': processingDurationMs,
    'engineVersion': engineVersion,
    'degradedAnalysis': degradedAnalysis,
    'processingStatus': processingStatus,
    'analysisLimitations': analysisLimitations,
    'processingErrors': processingErrors,
    'riskAssessment': {
      'overallScore': overallScore,
      'severityLevel': severityLevel,
      'headline': headline,
      'executiveSummary': executiveSummary,
      'categoryScores': categoryScores,
    },
    'findingsCount': findings.length,
    'findings': findings,
    'inferredInsights': inferences,
    'recommendations': recommendations,
  };
}

/// Request DTO for rescan verification of a redacted image.
class RescanVerificationRequest {
  final String originalAnalysisId;
  final Uint8List redactedImageBytes;

  const RescanVerificationRequest({
    required this.originalAnalysisId,
    required this.redactedImageBytes,
  });
}

/// Response DTO detailing the residual risk after mitigation.
class RescanVerificationResponse {
  final String rescanId;
  final String originalAnalysisId;
  final int originalScore;
  final int newScore;
  final int
  scoreDelta; // newScore - originalScore (negative indicates risk reduction)
  final String previousSeverity;
  final String newSeverity;
  final String
  verificationStatus; // 'MITIGATION_VERIFIED' or 'RESIDUAL_RISK_DETECTED'
  final int residualFindingsCount;
  final String message;

  const RescanVerificationResponse({
    required this.rescanId,
    required this.originalAnalysisId,
    required this.originalScore,
    required this.newScore,
    required this.scoreDelta,
    required this.previousSeverity,
    required this.newSeverity,
    required this.verificationStatus,
    required this.residualFindingsCount,
    required this.message,
  });

  factory RescanVerificationResponse.fromJson(Map<String, dynamic> json) {
    return RescanVerificationResponse(
      rescanId: json['rescanId'] as String? ?? '',
      originalAnalysisId: json['originalAnalysisId'] as String? ?? '',
      originalScore: (json['originalScore'] as num?)?.toInt() ?? 0,
      newScore: (json['newScore'] as num?)?.toInt() ?? 0,
      scoreDelta: (json['scoreDelta'] as num?)?.toInt() ?? 0,
      previousSeverity: json['previousSeverity'] as String? ?? 'CRITICAL',
      newSeverity: json['newSeverity'] as String? ?? 'LOW',
      verificationStatus:
          json['verificationStatus'] as String? ?? 'MITIGATION_VERIFIED',
      residualFindingsCount:
          (json['residualFindingsCount'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'rescanId': rescanId,
    'originalAnalysisId': originalAnalysisId,
    'originalScore': originalScore,
    'newScore': newScore,
    'scoreDelta': scoreDelta,
    'previousSeverity': previousSeverity,
    'newSeverity': newSeverity,
    'verificationStatus': verificationStatus,
    'residualFindingsCount': residualFindingsCount,
    'message': message,
  };
}

/// Standardized RFC 7807 problem details error response.
class ApiProblemDetails {
  final String type;
  final String title;
  final int status;
  final String detail;
  final String instance;
  final String requestId;

  const ApiProblemDetails({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    required this.instance,
    required this.requestId,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'status': status,
    'detail': detail,
    'instance': instance,
    'requestId': requestId,
  };

  @override
  String toString() => jsonEncode(toJson());
}

/// Contract interface that any Zenith client adapter implements.
///
/// Team Member 1's Camera App consumes this interface.
abstract class IZenithClient {
  Future<AnalyzeImageResponse> analyzeImage(AnalyzeImageRequest request);
  Future<RescanVerificationResponse> verifyRescan(
    RescanVerificationRequest request,
  );

  // Test-case library & evaluation framework endpoints
  Future<List<ZenithTestCaseRecord>> getTestCases();
  Future<ZenithTestCaseRecord?> getTestCase(String id);
  Future<ZenithTestRunRecord> executeTestRun({List<String>? caseIds});
  Future<List<ZenithTestRunRecord>> getTestRuns();
  Future<ZenithTestRunRecord?> getTestRun(String runId);
}

/// Local implementation of the Zenith API client, allowing the camera app
/// to run in-process or mock mode without requiring a remote HTTP server.
class ZenithLocalClient implements IZenithClient {
  final ZenithAnalysisPipeline _pipeline;
  final ZenithTestCaseRepository _testCaseRepo;
  final ZenithTestRunRepository _testRunRepo;

  ZenithLocalClient({
    ZenithAnalysisPipeline? pipeline,
    ZenithTestCaseRepository? testCaseRepo,
    ZenithTestRunRepository? testRunRepo,
  }) : _pipeline =
           pipeline ??
           ZenithAnalysisPipeline(visionProvider: MockVisionProvider()),
       _testCaseRepo = testCaseRepo ?? ZenithTestCaseRepository(),
       _testRunRepo = testRunRepo ?? ZenithTestRunRepository();

  @override
  Future<AnalyzeImageResponse> analyzeImage(AnalyzeImageRequest request) async {
    final report = await _pipeline.execute(
      imageBytes: request.imageBytes,
      sensitivity: request.sensitivityProfile,
    );
    return AnalyzeImageResponse.fromReport(report);
  }

  @override
  Future<RescanVerificationResponse> verifyRescan(
    RescanVerificationRequest request,
  ) async {
    final report = await _pipeline.execute(
      imageBytes: request.redactedImageBytes,
    );

    const assumedOriginalScore = 78;
    final delta = report.overallScore - assumedOriginalScore;
    final isVerified = report.overallScore <= 25;

    return RescanVerificationResponse(
      rescanId: 'res_${DateTime.now().microsecondsSinceEpoch}',
      originalAnalysisId: request.originalAnalysisId,
      originalScore: assumedOriginalScore,
      newScore: report.overallScore,
      scoreDelta: delta,
      previousSeverity: 'CRITICAL',
      newSeverity: report.riskLevel.label.toUpperCase(),
      verificationStatus: isVerified
          ? 'MITIGATION_VERIFIED'
          : 'RESIDUAL_RISK_DETECTED',
      residualFindingsCount: report.detectedElements.length,
      message: isVerified
          ? 'All critical privacy exposures successfully redacted. Safe for publication.'
          : 'Residual exposure detected. Consider additional blurring.',
    );
  }

  @override
  Future<List<ZenithTestCaseRecord>> getTestCases() async {
    return _testCaseRepo.getAll();
  }

  @override
  Future<ZenithTestCaseRecord?> getTestCase(String id) async {
    return _testCaseRepo.getById(id);
  }

  @override
  Future<ZenithTestRunRecord> executeTestRun({List<String>? caseIds}) async {
    final evaluator = ZenithTestEvaluator(
      testCaseRepo: _testCaseRepo,
      testRunRepo: _testRunRepo,
      pipeline: _pipeline,
    );
    return evaluator.executeSuite(selectedCaseIds: caseIds);
  }

  @override
  Future<List<ZenithTestRunRecord>> getTestRuns() async {
    return _testRunRepo.getAllRuns();
  }

  @override
  Future<ZenithTestRunRecord?> getTestRun(String runId) async {
    return _testRunRepo.getRunById(runId);
  }
}

/// Remote HTTP implementation of the Zenith API client, allowing external
/// applications (e.g. Team Member 1's Camera App) to communicate with Zenith
/// over REST.
class ZenithHttpClient implements IZenithClient {
  final String baseUrl;
  final http.Client _client;

  ZenithHttpClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<AnalyzeImageResponse> analyzeImage(AnalyzeImageRequest request) async {
    final uri = Uri.parse('$baseUrl/v1/analyze');
    final payload = {
      'image': base64Encode(request.imageBytes),
      'clientRequestId': request.clientRequestId,
      'sensitivityProfile': request.sensitivityProfile,
      'clientVersion': request.clientVersion,
    };

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyzeImageResponse.fromJson(data);
    } else {
      throw Exception(
        'Zenith API Error (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<RescanVerificationResponse> verifyRescan(
    RescanVerificationRequest request,
  ) async {
    final uri = Uri.parse('$baseUrl/v1/rescan');
    final payload = {
      'originalAnalysisId': request.originalAnalysisId,
      'redactedImage': base64Encode(request.redactedImageBytes),
    };

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RescanVerificationResponse.fromJson(data);
    } else {
      throw Exception(
        'Zenith Rescan API Error (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<List<ZenithTestCaseRecord>> getTestCases() async {
    final uri = Uri.parse('$baseUrl/api/v1/test-cases');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map(
            (e) => ZenithTestCaseRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    throw Exception('Failed to load test cases: ${response.statusCode}');
  }

  @override
  Future<ZenithTestCaseRecord?> getTestCase(String id) async {
    final uri = Uri.parse('$baseUrl/api/v1/test-cases/$id');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return ZenithTestCaseRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to load test case $id: ${response.statusCode}');
  }

  @override
  Future<ZenithTestRunRecord> executeTestRun({List<String>? caseIds}) async {
    final uri = Uri.parse('$baseUrl/api/v1/test-runs');
    final payload = caseIds != null ? {'caseIds': caseIds} : {};
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ZenithTestRunRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to execute test run: ${response.statusCode}');
  }

  @override
  Future<List<ZenithTestRunRecord>> getTestRuns() async {
    final uri = Uri.parse('$baseUrl/api/v1/test-runs');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map(
            (e) => ZenithTestRunRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    throw Exception('Failed to load test runs: ${response.statusCode}');
  }

  @override
  Future<ZenithTestRunRecord?> getTestRun(String runId) async {
    final uri = Uri.parse('$baseUrl/api/v1/test-runs/$runId');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return ZenithTestRunRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to load test run $runId: ${response.statusCode}');
  }
}
