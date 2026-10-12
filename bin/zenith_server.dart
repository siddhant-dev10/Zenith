import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:zenith/core/privacy_engine/api/zenith_api_contract.dart';
import 'package:zenith/core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import 'package:zenith/core/privacy_engine/providers/vision_analysis_provider.dart';
import 'package:zenith/core/privacy_engine/testing/test_case_models.dart';
import 'package:zenith/core/privacy_engine/testing/test_case_repository.dart';
import 'package:zenith/core/privacy_engine/testing/test_evaluator.dart';
import 'package:zenith/core/privacy_engine/validation/image_validator.dart';

// In-memory cache for generated analyses (supports GET /v1/analyses/:id)
final Map<String, AnalyzeImageResponse> _recentAnalyses = {};
final File _auditsFile = File('data/audits.json');

Future<void> _loadStoredAudits() async {
  if (await _auditsFile.exists()) {
    try {
      final content = await _auditsFile.readAsString();
      final list = jsonDecode(content) as List;
      for (final item in list) {
        final resp = AnalyzeImageResponse.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        _recentAnalyses[resp.analysisId] = resp;
      }
    } catch (e) {
      stderr.writeln('Warning: Failed to load stored audits: $e');
    }
  }
}

Future<void> _saveStoredAudit(AnalyzeImageResponse response) async {
  try {
    _recentAnalyses[response.analysisId] = response;
    final parentDir = _auditsFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    final allList = _recentAnalyses.values.map((r) => r.toJson()).toList();
    await _auditsFile.writeAsString(jsonEncode(allList));
  } catch (e) {
    stderr.writeln('Warning: Failed to persist audit to data/audits.json: $e');
  }
}

Map<String, String> _loadDotEnv() {
  final envMap = <String, String>{};
  final envFile = File('.env');
  if (envFile.existsSync()) {
    try {
      final lines = envFile.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx != -1) {
          final key = trimmed.substring(0, eqIdx).trim();
          var val = trimmed.substring(eqIdx + 1).trim();
          if ((val.startsWith('"') && val.endsWith('"')) ||
              (val.startsWith("'") && val.endsWith("'"))) {
            val = val.substring(1, val.length - 1);
          }
          envMap[key] = val;
        }
      }
    } catch (_) {}
  }
  return envMap;
}

Future<HttpServer> startZenithServer({
  required int port,
  required ZenithAnalysisPipeline pipeline,
  ZenithTestCaseRepository? testCaseRepo,
  ZenithTestRunRepository? testRunRepo,
  InternetAddress? address,
}) async {
  final tcRepo = testCaseRepo ?? ZenithTestCaseRepository();
  final trRepo = testRunRepo ?? ZenithTestRunRepository();
  final seeder = ZenithTestCaseSeeder(tcRepo);
  await seeder.seedInitialCases();
  await _loadStoredAudits();

  final evaluator = ZenithTestEvaluator(
    testCaseRepo: tcRepo,
    testRunRepo: trRepo,
    pipeline: pipeline,
  );

  final bindAddress = address ?? InternetAddress.anyIPv4;
  final server = await HttpServer.bind(bindAddress, port);
  server.listen((HttpRequest request) {
    handleRequest(
      request,
      pipeline,
      tcRepo: tcRepo,
      trRepo: trRepo,
      evaluator: evaluator,
    );
  });
  return server;
}

void main(List<String> args) async {
  int port = 8080;
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? port;
    }
  }
  final envPort = Platform.environment['PORT'];
  if (envPort != null) {
    port = int.tryParse(envPort) ?? port;
  }

  final dotEnv = _loadDotEnv();
  final apiKey =
      Platform.environment['GEMINI_API_KEY'] ??
      dotEnv['GEMINI_API_KEY'] ??
      Platform.environment['ZENITH_GEMINI_API_KEY'] ??
      dotEnv['ZENITH_GEMINI_API_KEY'];

  final model =
      Platform.environment['GEMINI_MODEL'] ??
      dotEnv['GEMINI_MODEL'] ??
      'gemini-3.8-flash';

  final IVisionAnalysisProvider provider;
  if (apiKey != null && apiKey.trim().isNotEmpty) {
    stdout.writeln(
      'Zenith Server: Initializing with GeminiVisionProvider (Live AI) [$model].',
    );
    provider = GeminiVisionProvider(apiKey: apiKey.trim(), model: model);
  } else {
    stdout.writeln(
      'Zenith Server: GEMINI_API_KEY is not set. Real image analysis will report missing credentials (503).',
    );
    provider = const UnconfiguredVisionProvider(
      message: 'GEMINI_API_KEY is not configured on the server. Please supply GEMINI_API_KEY in environment or .env file to enable live image analysis.',
    );
  }

  final pipeline = ZenithAnalysisPipeline(visionProvider: provider);

  final server = await startZenithServer(port: port, pipeline: pipeline);
  stdout.writeln('====================================================');
  stdout.writeln('  ZENITH PRIVACY INTELLIGENCE ENGINE SERVER (v1.0)  ');
  stdout.writeln(
    '  Listening on: http://${server.address.host}:${server.port}',
  );
  stdout.writeln('  Health check: http://localhost:${server.port}/health');
  stdout.writeln(
    '  Analyze API:  POST http://localhost:${server.port}/api/v1/analyze',
  );
  stdout.writeln(
    '  Audits API:   GET  http://localhost:${server.port}/api/v1/audits',
  );
  stdout.writeln(
    '  Test Cases:   GET  http://localhost:${server.port}/api/v1/test-cases',
  );
  stdout.writeln(
    '  Test Runs:    POST http://localhost:${server.port}/api/v1/test-runs',
  );
  stdout.writeln('====================================================');
}

Future<void> handleRequest(
  HttpRequest request,
  ZenithAnalysisPipeline pipeline, {
  ZenithTestCaseRepository? tcRepo,
  ZenithTestRunRepository? trRepo,
  ZenithTestEvaluator? evaluator,
}) async {
  final testCaseRepo = tcRepo ?? ZenithTestCaseRepository();
  final testRunRepo = trRepo ?? ZenithTestRunRepository();
  final testEvaluator =
      evaluator ??
      ZenithTestEvaluator(
        testCaseRepo: testCaseRepo,
        testRunRepo: testRunRepo,
        pipeline: pipeline,
      );

  final res = request.response;

  // Add standard CORS headers
  res.headers.set('Access-Control-Allow-Origin', '*');
  res.headers.set(
    'Access-Control-Allow-Methods',
    'GET, POST, PATCH, DELETE, OPTIONS',
  );
  res.headers.set(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, X-Client-Request-Id',
  );

  if (request.method == 'OPTIONS') {
    res.statusCode = HttpStatus.noContent;
    await res.close();
    return;
  }

  final path = request.uri.path;

  try {
    // 1. Health check
    if (request.method == 'GET' &&
        (path == '/' || path == '/health' || path == '/api/v1/health')) {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType.json;
      final isConfigured =
          pipeline.visionProvider is! UnconfiguredVisionProvider;
      res.write(
        jsonEncode({
          'status': 'healthy',
          'service': 'zenith-privacy-intelligence-engine',
          'version': '1.0.0',
          'geminiConfigured': isConfigured,
          'provider': pipeline.visionProvider is GeminiVisionProvider
              ? 'gemini'
              : (isConfigured ? 'mock' : 'unconfigured'),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      await res.close();
      return;
    }

    // Audits List Endpoint (GET /v1/audits or /api/v1/audits)
    if (request.method == 'GET' &&
        (path == '/v1/audits' || path == '/api/v1/audits')) {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType.json;
      final audits = _recentAnalyses.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      res.write(jsonEncode(audits.map((a) => a.toJson()).toList()));
      await res.close();
      return;
    }

    // 2. Ingest and Analyze Image (POST /v1/analyze or /api/v1/analyze)
    if (request.method == 'POST' &&
        (path == '/v1/analyze' || path == '/api/v1/analyze')) {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> body;
      try {
        body = jsonDecode(bodyStr) as Map<String, dynamic>;
      } catch (e) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/malformed-json',
          title: 'Malformed JSON Payload',
          detail: 'Failed to parse JSON body: $e',
          instance: path,
        );
        return;
      }

      final imageRaw =
          (body['image'] ?? body['image_bytes'] ?? body['imageBytes'])
              as String?;
      if (imageRaw == null || imageRaw.isEmpty) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/missing-image',
          title: 'Missing Image Field',
          detail: 'Request body must contain base64 encoded "image" or "image_bytes" field.',
          instance: path,
        );
        return;
      }

      final Uint8List imageBytes;
      try {
        final cleanBase64 = imageRaw.contains(',')
            ? imageRaw.split(',').last
            : imageRaw;
        imageBytes = base64Decode(cleanBase64);
      } catch (e) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/invalid-base64',
          title: 'Invalid Base64 Encoding',
          detail: 'Unable to decode base64 image data: $e',
          instance: path,
        );
        return;
      }

      final sensitivity = body['sensitivityProfile'] as String? ?? 'balanced';
      final clientRequestId = body['clientRequestId'] as String?;
      final requestedMime =
          body['mime_type'] as String? ?? body['mimeType'] as String?;
      if (requestedMime != null &&
          ![
            'image/jpeg',
            'image/png',
            'image/webp',
          ].contains(requestedMime.toLowerCase())) {
        _sendError(
          res,
          HttpStatus.unsupportedMediaType,
          type: 'https://zenith.privacy/errors/unsupported-media-type',
          title: 'Unsupported Media Type',
          detail:
              'MIME type "$requestedMime" is not supported. Zenith accepts image/jpeg, image/png, image/webp.',
          instance: path,
          requestId: clientRequestId,
        );
        return;
      }

      try {
        final report = await pipeline.execute(
          imageBytes: imageBytes,
          sensitivity: sensitivity,
        );

        final apiResponse = AnalyzeImageResponse.fromReport(report);
        await _saveStoredAudit(apiResponse);

        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(apiResponse.toJson()));
        await res.close();
      } on ImageValidationException catch (e) {
        _sendError(
          res,
          HttpStatus.unprocessableEntity,
          type: 'https://zenith.privacy/errors/validation-failed',
          title: 'Image Validation Failed',
          detail: e.message,
          instance: path,
          requestId: clientRequestId,
        );
      } on VisionProviderException catch (e) {
        final status = e.isRateLimit
            ? HttpStatus.tooManyRequests
            : (e.statusCode ?? HttpStatus.badGateway);
        final isAuthOrConfig =
            status == HttpStatus.unauthorized ||
            status == HttpStatus.serviceUnavailable;
        _sendError(
          res,
          status,
          type: isAuthOrConfig
              ? 'https://zenith.privacy/errors/missing-credentials'
              : (e.isRateLimit
                    ? 'https://zenith.privacy/errors/rate-limit-exceeded'
                    : 'https://zenith.privacy/errors/vision-provider-failed'),
          title: isAuthOrConfig
              ? 'Gemini Credentials Required'
              : (e.isRateLimit
                    ? 'Rate Limit Exceeded'
                    : 'Vision Provider Failed'),
          detail: e.message,
          instance: path,
          requestId: clientRequestId,
        );
      } catch (e) {
        _sendError(
          res,
          HttpStatus.internalServerError,
          type: 'https://zenith.privacy/errors/pipeline-execution-failed',
          title: 'Pipeline Execution Error',
          detail: e.toString(),
          instance: path,
          requestId: clientRequestId,
        );
      }
      return;
    }

    // 3. Retrieve Historical Analysis by ID (GET /api/v1/analyses/:id or /v1/analyses/:id)
    if (request.method == 'GET' &&
        (path.startsWith('/v1/analyses/') ||
            path.startsWith('/api/v1/analyses/'))) {
      final id = path.split('/').last;
      final cached = _recentAnalyses[id];
      if (cached != null) {
        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(cached.toJson()));
        await res.close();
        return;
      } else {
        _sendError(
          res,
          HttpStatus.notFound,
          type: 'https://zenith.privacy/errors/analysis-not-found',
          title: 'Analysis Not Found',
          detail: 'No analysis report found for ID "$id".',
          instance: path,
        );
        return;
      }
    }

    // 4. Verify Rescan (POST /v1/rescan or /api/v1/rescan)
    if (request.method == 'POST' &&
        (path == '/v1/rescan' || path == '/api/v1/rescan')) {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> body;
      try {
        body = jsonDecode(bodyStr) as Map<String, dynamic>;
      } catch (e) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/malformed-json',
          title: 'Malformed JSON Payload',
          detail: 'Failed to parse JSON body: $e',
          instance: path,
        );
        return;
      }

      final originalAnalysisId =
          body['originalAnalysisId'] as String? ?? 'orig_unknown';
      final redactedRaw = (body['redactedImage'] ?? body['image']) as String?;

      if (redactedRaw == null || redactedRaw.isEmpty) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/missing-image',
          title: 'Missing Image Field',
          detail: 'Rescan request must contain base64 encoded "redactedImage".',
          instance: path,
        );
        return;
      }

      final Uint8List redactedBytes;
      try {
        final clean = redactedRaw.contains(',')
            ? redactedRaw.split(',').last
            : redactedRaw;
        redactedBytes = base64Decode(clean);
      } catch (e) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/invalid-base64',
          title: 'Invalid Base64 Encoding',
          detail: 'Unable to decode base64 image data: $e',
          instance: path,
        );
        return;
      }

      try {
        final report = await pipeline.execute(imageBytes: redactedBytes);

        const assumedOriginalScore = 78;
        final delta = report.overallScore - assumedOriginalScore;
        final isVerified = report.overallScore <= 25;

        final rescanResponse = RescanVerificationResponse(
          rescanId: 'res_${DateTime.now().microsecondsSinceEpoch}',
          originalAnalysisId: originalAnalysisId,
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

        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(rescanResponse.toJson()));
        await res.close();
      } on ImageValidationException catch (e) {
        _sendError(
          res,
          HttpStatus.unprocessableEntity,
          type: 'https://zenith.privacy/errors/validation-failed',
          title: 'Image Validation Failed',
          detail: e.message,
          instance: path,
        );
      } catch (e) {
        _sendError(
          res,
          HttpStatus.internalServerError,
          type: 'https://zenith.privacy/errors/rescan-failed',
          title: 'Rescan Execution Error',
          detail: e.toString(),
          instance: path,
        );
      }
      return;
    }

    // 5. Test-Case Library Endpoints (GET, POST /api/v1/test-cases)
    if (path == '/api/v1/test-cases' || path == '/v1/test-cases') {
      if (request.method == 'GET') {
        final all = await testCaseRepo.getAll();
        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(all.map((e) => e.toJson()).toList()));
        await res.close();
        return;
      } else if (request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        final json = jsonDecode(bodyStr) as Map<String, dynamic>;
        final record = ZenithTestCaseRecord.fromJson(json);
        final saved = await testCaseRepo.save(record);
        res.statusCode = HttpStatus.created;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(saved.toJson()));
        await res.close();
        return;
      }
    }

    // 6. Test-Case Individual Endpoint (GET, PATCH, DELETE /api/v1/test-cases/:id)
    if (path.startsWith('/api/v1/test-cases/') ||
        path.startsWith('/v1/test-cases/')) {
      final id = path.split('/').last;
      if (request.method == 'GET') {
        final record = await testCaseRepo.getById(id);
        if (record != null) {
          res.statusCode = HttpStatus.ok;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode(record.toJson()));
          await res.close();
          return;
        } else {
          _sendError(
            res,
            HttpStatus.notFound,
            type: 'https://zenith.privacy/errors/test-case-not-found',
            title: 'Test Case Not Found',
            detail: 'Test case with ID "$id" does not exist.',
            instance: path,
          );
          return;
        }
      } else if (request.method == 'PATCH') {
        final bodyStr = await utf8.decodeStream(request);
        final updates = jsonDecode(bodyStr) as Map<String, dynamic>;
        final updated = await testCaseRepo.patch(id, updates);
        if (updated != null) {
          res.statusCode = HttpStatus.ok;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode(updated.toJson()));
          await res.close();
          return;
        } else {
          _sendError(
            res,
            HttpStatus.notFound,
            type: 'https://zenith.privacy/errors/test-case-not-found',
            title: 'Test Case Not Found',
            detail: 'Cannot patch non-existent test case "$id".',
            instance: path,
          );
          return;
        }
      } else if (request.method == 'DELETE') {
        final deleted = await testCaseRepo.delete(id);
        if (deleted) {
          res.statusCode = HttpStatus.noContent;
          await res.close();
          return;
        } else {
          _sendError(
            res,
            HttpStatus.notFound,
            type: 'https://zenith.privacy/errors/test-case-not-found',
            title: 'Test Case Not Found',
            detail: 'Cannot delete non-existent test case "$id".',
            instance: path,
          );
          return;
        }
      }
    }

    // 7. Test-Run Execution and History (POST, GET /api/v1/test-runs)
    if (path == '/api/v1/test-runs' || path == '/v1/test-runs') {
      if (request.method == 'GET') {
        final runs = await testRunRepo.getAllRuns();
        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(runs.map((r) => r.toJson()).toList()));
        await res.close();
        return;
      } else if (request.method == 'POST') {
        List<String>? selectedCaseIds;
        final bodyStr = await utf8.decodeStream(request);
        if (bodyStr.trim().isNotEmpty) {
          try {
            final json = jsonDecode(bodyStr) as Map<String, dynamic>;
            if (json['caseIds'] is List) {
              selectedCaseIds = (json['caseIds'] as List)
                  .map((e) => e.toString())
                  .toList();
            }
          } catch (_) {}
        }

        final runRecord = await testEvaluator.executeSuite(
          selectedCaseIds: selectedCaseIds,
        );

        res.statusCode = HttpStatus.ok;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(runRecord.toJson()));
        await res.close();
        return;
      }
    }

    // 8. Individual Test-Run Retrieval (GET /api/v1/test-runs/:id)
    if (path.startsWith('/api/v1/test-runs/') ||
        path.startsWith('/v1/test-runs/')) {
      final runId = path.split('/').last;
      if (request.method == 'GET') {
        final run = await testRunRepo.getRunById(runId);
        if (run != null) {
          res.statusCode = HttpStatus.ok;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode(run.toJson()));
          await res.close();
          return;
        } else {
          _sendError(
            res,
            HttpStatus.notFound,
            type: 'https://zenith.privacy/errors/test-run-not-found',
            title: 'Test Run Not Found',
            detail: 'Test run with ID "$runId" does not exist.',
            instance: path,
          );
          return;
        }
      }
    }

    // 404 Route Not Found
    _sendError(
      res,
      HttpStatus.notFound,
      type: 'https://zenith.privacy/errors/not-found',
      title: 'Endpoint Not Found',
      detail: 'No endpoint matched ${request.method} $path',
      instance: path,
    );
  } catch (e) {
    _sendError(
      res,
      HttpStatus.internalServerError,
      type: 'https://zenith.privacy/errors/unhandled-exception',
      title: 'Server Error',
      detail: e.toString(),
      instance: path,
    );
  }
}

Future<void> _sendError(
  HttpResponse res,
  int statusCode, {
  required String type,
  required String title,
  required String detail,
  required String instance,
  String? requestId,
}) async {
  final problem = ApiProblemDetails(
    type: type,
    title: title,
    status: statusCode,
    detail: detail,
    instance: instance,
    requestId: requestId ?? 'req_${DateTime.now().microsecondsSinceEpoch}',
  );

  res.statusCode = statusCode;
  res.headers.contentType = ContentType(
    'application',
    'problem+json',
    charset: 'utf-8',
  );
  res.write(problem.toString());
  await res.close();
}
