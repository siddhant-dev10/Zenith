import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../models/privacy_audit_report.dart';
import '../../network/api_config.dart';
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
  final String? model;
  final String? provider;
  final String? imageSummary;
  final String severityReason;
  final List<Map<String, dynamic>> findingContributions;

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
    this.model,
    this.provider,
    this.imageSummary,
    this.severityReason = '',
    this.findingContributions = const [],
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
      model: report.model,
      provider: report.provider,
      imageSummary: report.imageSummary ?? report.summary,
      severityReason: report.severityReason.isNotEmpty
          ? report.severityReason
          : report.summary,
      findingContributions: report.detectedElements
          .map(
            (e) => {
              'findingId': e.id,
              'findingName': e.name,
              'category': e.category.id,
              'baseSensitivity': e.baseSensitivity,
              'exploitability': e.exploitability,
              'visibilityScore': e.visibilityScore,
              'confidence': e.confidence,
              'calculatedRiskContribution': e.calculatedRiskContribution,
              'severityReason': e.severityReason,
            },
          )
          .toList(),
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
      model: json['model'] as String?,
      provider: json['provider'] as String?,
      imageSummary:
          json['imageSummary'] as String? ??
          (riskAssessment['executiveSummary'] as String?),
      severityReason:
          json['severityReason'] as String? ??
          (riskAssessment['severityReason'] as String? ?? ''),
      findingContributions:
          (json['findingContributions'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
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
    'model': model,
    'provider': provider,
    'imageSummary': imageSummary,
    'severityReason': severityReason,
    'riskAssessment': {
      'overallScore': overallScore,
      'severityLevel': severityLevel,
      'headline': headline,
      'executiveSummary': executiveSummary,
      'categoryScores': categoryScores,
      'severityReason': severityReason,
    },
    'findingsCount': findings.length,
    'findings': findings,
    'findingContributions': findingContributions,
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
  Future<Map<String, dynamic>> checkHealth();

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

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {
      'status': 'healthy',
      'service': 'zenith-privacy-intelligence-engine',
      'version': '1.0.0',
      'geminiConfigured':
          _pipeline.visionProvider is! UnconfiguredVisionProvider,
      'provider': _pipeline.visionProvider is GeminiVisionProvider
          ? 'gemini'
          : 'mock',
      'timestamp': DateTime.now().toIso8601String(),
    };
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

  Uri _endpoint(String path) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw Exception(
        'Live analysis is not configured for this website. The site owner must set the production API URL and redeploy.',
      );
    }
    final uri = Uri.tryParse('$normalized$path');
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw Exception('The configured Zenith API URL is invalid.');
    }
    final isProductionWeb =
        (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') &&
        const bool.fromEnvironment('dart.vm.product');
    if (isProductionWeb && uri.scheme != 'https') {
      throw Exception('The production Zenith API must use HTTPS.');
    }
    if (isProductionWeb &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '::1')) {
      throw Exception(
        'This website is configured to use localhost, which points to your device. The site owner must configure and deploy a public HTTPS API URL.',
      );
    }
    return uri;
  }

  Future<http.Response> _send(Future<http.Response> request) =>
      request.timeout(const Duration(seconds: 60));

  String _apiError(http.Response response, String feature) {
    String? title;
    String? detail;
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map) {
        title = payload['title']?.toString();
        detail = payload['detail']?.toString();
      }
    } catch (_) {}
    final message = switch (response.statusCode) {
      400 || 415 || 422 => detail ?? title ?? 'The image could not be validated. Choose a supported image and try again.',
      401 || 503 => detail != null && detail.isNotEmpty
          ? '$detail (contact the site owner)'
          : 'Live image analysis is not configured on the server. Please contact the site owner.',
      429 => 'The analysis service is busy or its quota is exhausted. Please wait and retry.',
      >= 500 =>
        detail ?? title ?? 'The analysis service encountered an error (${response.statusCode}). Please retry shortly.',
      _ => detail ?? title ?? 'The server rejected the $feature request.',
    };
    return 'Zenith $feature unavailable (${response.statusCode}): $message';
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
    String feature, {
    String requiredIdField = 'analysisId',
    bool requiresRiskAssessment = true,
  }) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded[requiredIdField] is! String ||
          (decoded[requiredIdField] as String).isEmpty ||
          (requiresRiskAssessment && decoded['riskAssessment'] is! Map)) {
        throw const FormatException('Required response fields are missing.');
      }
      return decoded;
    } catch (_) {
      throw Exception(
        'Zenith $feature unavailable: the server returned an invalid response. Please retry or contact the site owner.',
      );
    }
  }

  @override
  Future<AnalyzeImageResponse> analyzeImage(AnalyzeImageRequest request) async {
    final uri = _endpoint('/v1/analyze');
    final payload = {
      'image': base64Encode(request.imageBytes),
      'clientRequestId': request.clientRequestId,
      'sensitivityProfile': request.sensitivityProfile,
      'clientVersion': request.clientVersion,
    };

    try {
      final response = await _send(
        _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeResponse(response, 'analysis');
        return AnalyzeImageResponse.fromJson(data);
      } else {
        throw Exception(_apiError(response, 'analysis'));
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('Zenith analysis unavailable')) {
        rethrow;
      }
      if (e is TimeoutException) {
        throw Exception(
          'The analysis service timed out. Check your connection and retry.',
        );
      }
      throw Exception(ApiConfig.diagnoseConnectionError(e, uri.toString()));
    }
  }

  @override
  Future<RescanVerificationResponse> verifyRescan(
    RescanVerificationRequest request,
  ) async {
    final uri = _endpoint('/v1/rescan');
    final payload = {
      'originalAnalysisId': request.originalAnalysisId,
      'redactedImage': base64Encode(request.redactedImageBytes),
    };

    try {
      final response = await _send(
        _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeResponse(
          response,
          'rescan',
          requiredIdField: 'rescanId',
          requiresRiskAssessment: false,
        );
        return RescanVerificationResponse.fromJson(data);
      } else {
        throw Exception(_apiError(response, 'rescan'));
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('Zenith rescan unavailable')) {
        rethrow;
      }
      if (e is TimeoutException) {
        throw Exception(
          'The rescan service timed out. Check your connection and retry.',
        );
      }
      throw Exception(ApiConfig.diagnoseConnectionError(e, uri.toString()));
    }
  }

  @override
  Future<List<ZenithTestCaseRecord>> getTestCases() async {
    final uri = _endpoint('/api/v1/test-cases');
    final response = await _send(_client.get(uri));
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
    final uri = _endpoint('/api/v1/test-cases/${Uri.encodeComponent(id)}');
    final response = await _send(_client.get(uri));
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
    final uri = _endpoint('/api/v1/test-runs');
    final payload = caseIds != null ? {'caseIds': caseIds} : {};
    final response = await _send(
      _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
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
    final uri = _endpoint('/api/v1/test-runs');
    final response = await _send(_client.get(uri));
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
    final uri = _endpoint('/api/v1/test-runs/${Uri.encodeComponent(runId)}');
    final response = await _send(_client.get(uri));
    if (response.statusCode == 200) {
      return ZenithTestRunRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to load test run $runId: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    final uri = _endpoint('/health');
    try {
      final response = await _send(_client.get(uri));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
      throw Exception(
        'Server health check returned HTTP ${response.statusCode}',
      );
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('Live analysis is not configured')) {
        rethrow;
      }
      throw Exception(ApiConfig.diagnoseConnectionError(e, uri.toString()));
    }
  }
}
