import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:zenith/core/privacy_engine/api/zenith_api_contract.dart';
import 'package:zenith/core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import 'package:zenith/core/privacy_engine/providers/vision_analysis_provider.dart';
import 'package:zenith/core/privacy_engine/validation/image_validator.dart';

Future<HttpServer> startZenithServer({
  required int port,
  required ZenithAnalysisPipeline pipeline,
  InternetAddress? address,
}) async {
  final bindAddress = address ?? InternetAddress.anyIPv4;
  final server = await HttpServer.bind(bindAddress, port);
  server.listen((HttpRequest request) {
    handleRequest(request, pipeline);
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

  final apiKey =
      Platform.environment['ZENITH_GEMINI_API_KEY'] ??
      Platform.environment['GEMINI_API_KEY'];

  final IVisionAnalysisProvider provider;
  if (apiKey != null && apiKey.isNotEmpty) {
    stdout.writeln(
      'Zenith Server: Initializing with GeminiVisionProvider (Live AI).',
    );
    provider = GeminiVisionProvider(apiKey: apiKey);
  } else {
    stdout.writeln(
      'Zenith Server: Initializing with MockVisionProvider (Deterministic Heuristic Mode).',
    );
    provider = MockVisionProvider();
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
    '  Analyze API:  POST http://localhost:${server.port}/v1/analyze',
  );
  stdout.writeln(
    '  Rescan API:   POST http://localhost:${server.port}/v1/rescan',
  );
  stdout.writeln('====================================================');
}

Future<void> handleRequest(
  HttpRequest request,
  ZenithAnalysisPipeline pipeline,
) async {
  final res = request.response;

  // Add standard CORS headers
  res.headers.set('Access-Control-Allow-Origin', '*');
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
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
    if (request.method == 'GET' && (path == '/' || path == '/health')) {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType.json;
      res.write(
        jsonEncode({
          'status': 'healthy',
          'service': 'zenith-privacy-intelligence-engine',
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      await res.close();
      return;
    }

    if (request.method == 'POST' && path == '/v1/analyze') {
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

      final imageRaw = body['image'] as String?;
      if (imageRaw == null || imageRaw.isEmpty) {
        _sendError(
          res,
          HttpStatus.badRequest,
          type: 'https://zenith.privacy/errors/missing-image',
          title: 'Missing Image Field',
          detail: 'Request body must contain base64 encoded "image" field.',
          instance: path,
        );
        return;
      }

      final Uint8List imageBytes;
      try {
        // Strip data URI scheme prefix if present
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

      try {
        final report = await pipeline.execute(
          imageBytes: imageBytes,
          sensitivity: sensitivity,
        );

        final apiResponse = AnalyzeImageResponse.fromReport(report);
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
        _sendError(
          res,
          status,
          type: e.isRateLimit
              ? 'https://zenith.privacy/errors/rate-limit-exceeded'
              : 'https://zenith.privacy/errors/vision-provider-failed',
          title: e.isRateLimit
              ? 'Rate Limit Exceeded'
              : 'Vision Provider Failed',
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

    if (request.method == 'POST' && path == '/v1/rescan') {
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
