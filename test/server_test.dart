import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zenith/core/privacy_engine/api/zenith_api_contract.dart';
import 'package:zenith/core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import 'package:zenith/core/privacy_engine/providers/vision_analysis_provider.dart';

import '../bin/zenith_server.dart';

void main() {
  group('Zenith HTTP Server & Remote API Integration Tests', () {
    late HttpServer server;
    late String baseUrl;
    late ZenithHttpClient apiClient;

    // Standard valid 1x1 PNG bytes
    final validPngBytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);

    setUp(() async {
      final pipeline = ZenithAnalysisPipeline(
        visionProvider: MockVisionProvider(),
      );
      server = await startZenithServer(
        port: 0, // Ephemeral port
        pipeline: pipeline,
        address: InternetAddress.loopbackIPv4,
      );
      baseUrl = 'http://127.0.0.1:${server.port}';
      apiClient = ZenithHttpClient(baseUrl: baseUrl);
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('GET /health returns 200 OK and healthy status', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers['content-type'], contains('application/json'));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['status'], 'healthy');
      expect(body['serverStatus'], 'healthy');
      expect(body['analysisReady'], true);
      expect(body['providerConfigured'], true);
      expect(body['service'], 'zenith-privacy-intelligence-engine');
      expect(body['version'], '1.0.0');
    });

    test(
      'GET /ready reports provider readiness independently of liveness',
      () async {
        final response = await http.get(Uri.parse('$baseUrl/ready'));
        expect(response.statusCode, HttpStatus.ok);

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['status'], 'ready');
        expect(body['ready'], true);
        expect(body['providerConfigured'], true);
      },
    );

    test('ZenithHttpClient.checkHealth succeeds against live server', () async {
      final health = await apiClient.checkHealth();
      expect(health['status'], 'healthy');
      expect(health['service'], 'zenith-privacy-intelligence-engine');
      expect(health['version'], '1.0.0');
    });

    test('OPTIONS preflight allows the GitHub Pages origin', () async {
      final request = http.Request('OPTIONS', Uri.parse('$baseUrl/v1/analyze'))
        ..headers['Origin'] = 'https://siddhant-dev10.github.io';
      final corsResponse = await request.send().then(http.Response.fromStream);
      expect(corsResponse.statusCode, HttpStatus.noContent);
      expect(
        corsResponse.headers['access-control-allow-origin'],
        'https://siddhant-dev10.github.io',
      );
    });

    test('OPTIONS preflight rejects an unconfigured browser origin', () async {
      final request = http.Request('OPTIONS', Uri.parse('$baseUrl/v1/analyze'))
        ..headers['Origin'] = 'https://untrusted.example';
      final response = await request.send().then(http.Response.fromStream);
      expect(response.statusCode, HttpStatus.forbidden);
      expect(response.headers['access-control-allow-origin'], isNull);
    });

    test(
      'POST /v1/analyze processes valid image and returns complete contract',
      () async {
        final requestBody = {
          'image': base64Encode(validPngBytes),
          'clientRequestId': 'req_camera_unit_test',
          'sensitivityProfile': 'balanced',
          'clientVersion': '1.0.0',
        };

        final response = await http.post(
          Uri.parse('$baseUrl/v1/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        expect(response.statusCode, HttpStatus.ok);
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        expect(json['analysisId'], isNotEmpty);
        expect(json.containsKey('riskAssessment'), true);

        final riskAssessment = json['riskAssessment'] as Map<String, dynamic>;
        expect(riskAssessment['overallScore'], inInclusiveRange(0, 100));
        expect(riskAssessment['severityLevel'], isNotEmpty);
        expect(json['findingsCount'], greaterThan(0));
        expect(json['findings'], isNotEmpty);
        expect(json['recommendations'], isNotEmpty);
      },
    );

    test(
      'POST /v1/analyze rejects malformed JSON with 400 Problem Details',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/v1/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: '{not valid json',
        );

        expect(response.statusCode, HttpStatus.badRequest);
        expect(response.headers['content-type'], contains('problem+json'));

        final problem = jsonDecode(response.body) as Map<String, dynamic>;
        expect(problem['type'], contains('malformed-json'));
        expect(problem['title'], contains('Malformed JSON'));
      },
    );

    test(
      'POST /v1/analyze rejects missing image field with 400 Problem Details',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/v1/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'sensitivityProfile': 'balanced'}),
        );

        expect(response.statusCode, HttpStatus.badRequest);
        final problem = jsonDecode(response.body) as Map<String, dynamic>;
        expect(problem['type'], contains('missing-image'));
      },
    );

    test(
      'POST /v1/analyze rejects invalid base64 with 400 Problem Details',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/v1/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image': 'not_base_64_&&&!!!'}),
        );

        expect(response.statusCode, HttpStatus.badRequest);
        final problem = jsonDecode(response.body) as Map<String, dynamic>;
        expect(problem['type'], contains('invalid-base64'));
      },
    );

    test('POST /v1/analyze rejects corrupted image payload with 422 Unprocessable Entity', () async {
      final corruptBytes = Uint8List.fromList([0x00, 0x11, 0x22, 0x33]);
      final response = await http.post(
        Uri.parse('$baseUrl/v1/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Encode(corruptBytes)}),
      );

      expect(response.statusCode, HttpStatus.unprocessableEntity);
      final problem = jsonDecode(response.body) as Map<String, dynamic>;
      expect(problem['type'], contains('validation-failed'));
    });

    test('OPTIONS preflight includes Access-Control-Max-Age and Accept headers', () async {
      final request = http.Request('OPTIONS', Uri.parse('$baseUrl/v1/analyze'))
        ..headers['Origin'] = 'https://siddhant-dev10.github.io';
      final corsResponse = await request.send().then(http.Response.fromStream);
      expect(corsResponse.statusCode, HttpStatus.noContent);
      expect(corsResponse.headers['access-control-max-age'], '86400');
      expect(corsResponse.headers['access-control-allow-headers'], contains('Accept'));
    });

    test(
      'POST /v1/rescan verifies sanitized photograph risk reduction',
      () async {
        final rescanPayload = {
          'originalAnalysisId': 'orig_sample_123',
          'redactedImage': base64Encode(validPngBytes),
        };

        final response = await http.post(
          Uri.parse('$baseUrl/v1/rescan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(rescanPayload),
        );

        expect(response.statusCode, HttpStatus.ok);
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        expect(json['originalAnalysisId'], 'orig_sample_123');
        expect(json['verificationStatus'], isNotEmpty);
        expect(json.containsKey('scoreDelta'), true);
      },
    );

    test('Unknown routes return 404 Problem Details', () async {
      final response = await http.get(Uri.parse('$baseUrl/v1/nonexistent'));
      expect(response.statusCode, HttpStatus.notFound);
      final problem = jsonDecode(response.body) as Map<String, dynamic>;
      expect(problem['type'], contains('not-found'));
    });

    test(
      'ZenithHttpClient executes analyzeImage and verifyRescan over live HTTP',
      () async {
        final req = AnalyzeImageRequest(
          imageBytes: validPngBytes,
          clientRequestId: 'http_client_req_01',
        );

        final analysis = await apiClient.analyzeImage(req);
        expect(analysis.analysisId, isNotEmpty);
        expect(analysis.overallScore, inInclusiveRange(0, 100));

        final rescanReq = RescanVerificationRequest(
          originalAnalysisId: analysis.analysisId,
          redactedImageBytes: validPngBytes,
        );
        final rescanRes = await apiClient.verifyRescan(rescanReq);
        expect(rescanRes.originalAnalysisId, analysis.analysisId);
        expect(rescanRes.verificationStatus, isNotEmpty);
      },
    );

    test('Real disk image asset (sample_student_id.png) can be submitted and produces structured privacy report', () async {
      final sampleFile = File('assets/samples/sample_student_id.png');
      expect(
        sampleFile.existsSync(),
        true,
        reason: 'Real sample asset must exist on disk',
      );
      final realImageBytes = await sampleFile.readAsBytes();
      expect(realImageBytes.length, greaterThan(1000));

      final req = AnalyzeImageRequest(
        imageBytes: realImageBytes,
        clientRequestId: 'req_real_asset_student_id',
        sensitivityProfile: 'high',
      );

      final response = await apiClient.analyzeImage(req);

      expect(response.analysisId, isNotEmpty);
      expect(response.overallScore, inInclusiveRange(0, 100));
      expect(response.severityLevel, isNotEmpty);
      expect(response.categoryScores, isNotEmpty);
      expect(response.findings, isNotEmpty);
      expect(response.recommendations, isNotEmpty);
      expect(
        response.processingStatus,
        anyOf(equals('completed'), equals('partial_failure')),
      );

      // The server intentionally does not retain analysis records.
      final getAnalysisRes = await http.get(
        Uri.parse('$baseUrl/api/v1/analyses/${response.analysisId}'),
      );
      expect(getAnalysisRes.statusCode, HttpStatus.notFound);
    });

    test('GET /api/v1/test-cases returns all 20 seeded threat benchmark test cases', () async {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/test-cases'));
      expect(res.statusCode, HttpStatus.ok);
      final list = jsonDecode(res.body) as List;
      expect(list.length, greaterThanOrEqualTo(20));

      final ids = list.map((e) => (e as Map)['id']).toSet();
      expect(ids.contains('TC-01-CLEAN'), true);
      expect(ids.contains('TC-03-STUDENT-ID'), true);
      expect(ids.contains('TC-10-TERMINAL-SCREEN'), true);
      expect(ids.contains('TC-20-DEGRADED-DETECTOR'), true);
    });

    test(
      'GET /api/v1/test-cases/:id returns specific test case details',
      () async {
        final res = await http.get(
          Uri.parse('$baseUrl/api/v1/test-cases/TC-03-STUDENT-ID'),
        );
        expect(res.statusCode, HttpStatus.ok);
        final tc = jsonDecode(res.body) as Map<String, dynamic>;
        expect(tc['id'], 'TC-03-STUDENT-ID');
        expect(tc['category'], 'student_ids');
        expect(tc['expectedSeverity'], 'high');
        expect(tc['minExpectedScore'], 51);
      },
    );

    test('POST /api/v1/test-runs executes suite, computes evaluation metrics and persists run', () async {
      // Execute a targeted test run with clean landscape, student ID, and terminal screen
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/test-runs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'caseIds': [
            'TC-01-CLEAN',
            'TC-03-STUDENT-ID',
            'TC-10-TERMINAL-SCREEN',
          ],
        }),
      );

      expect(res.statusCode, HttpStatus.ok);
      final run = jsonDecode(res.body) as Map<String, dynamic>;
      expect(run['runId'], isNotEmpty);
      expect(run['totalCases'], 3);
      expect(run['passedCases'], 3);
      expect(run['passRate'], 100.0);
      expect(run['precision'], greaterThan(0.0));
      expect(run['recall'], greaterThan(0.0));
      expect(run['f1Score'], greaterThan(0.0));
      expect(run['severityAccuracy'], 100.0);
      expect((run['results'] as List).length, 3);

      // Verify GET /api/v1/test-runs lists this run
      final listRes = await http.get(Uri.parse('$baseUrl/api/v1/test-runs'));
      expect(listRes.statusCode, HttpStatus.ok);
      final allRuns = jsonDecode(listRes.body) as List;
      expect(allRuns.any((r) => (r as Map)['runId'] == run['runId']), true);
    });

    test('GET /v1/audits is disabled to prevent cross-user exposure', () async {
      final auditsRes = await http.get(Uri.parse('$baseUrl/v1/audits'));
      expect(auditsRes.statusCode, HttpStatus.forbidden);
      expect(jsonDecode(auditsRes.body)['title'], 'Audit History Unavailable');
    });

    test('Server with UnconfiguredVisionProvider returns HTTP 503 missing-credentials instead of mock 43', () async {
      final unconfiguredPipeline = ZenithAnalysisPipeline(
        visionProvider: const UnconfiguredVisionProvider(),
      );
      final unconfiguredServer = await startZenithServer(
        port: 0,
        pipeline: unconfiguredPipeline,
        address: InternetAddress.loopbackIPv4,
      );

      try {
        final readiness = await http.get(
          Uri.parse('http://127.0.0.1:${unconfiguredServer.port}/ready'),
        );
        expect(readiness.statusCode, HttpStatus.serviceUnavailable);
        final readinessBody =
            jsonDecode(readiness.body) as Map<String, dynamic>;
        expect(readinessBody['status'], 'not_ready');
        expect(readinessBody['ready'], false);
        expect(readinessBody['providerConfigured'], false);

        final health = await http.get(
          Uri.parse('http://127.0.0.1:${unconfiguredServer.port}/health'),
        );
        expect(health.statusCode, HttpStatus.ok);
        final healthBody = jsonDecode(health.body) as Map<String, dynamic>;
        expect(healthBody['status'], 'degraded');
        expect(healthBody['serverStatus'], 'healthy');
        expect(healthBody['analysisReady'], false);

        final res = await http.post(
          Uri.parse('http://127.0.0.1:${unconfiguredServer.port}/v1/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image': base64Encode(validPngBytes),
            'sensitivityProfile': 'balanced',
          }),
        );

        expect(res.statusCode, HttpStatus.serviceUnavailable);
        final problem = jsonDecode(res.body) as Map<String, dynamic>;
        expect(
          problem['type'],
          'https://zenith.privacy/errors/missing-credentials',
        );
        expect(problem['title'], 'Gemini Credentials Required');
        expect(
          problem['detail'],
          contains('configure GEMINI_API_KEY on the backend'),
        );
      } finally {
        await unconfiguredServer.close(force: true);
      }
    });

    test(
      'upstream Gemini HTTP 503 is not mislabeled as missing credentials',
      () async {
        final upstreamFailureServer = await startZenithServer(
          port: 0,
          pipeline: ZenithAnalysisPipeline(
            visionProvider: _FailingVisionProvider(
              const VisionProviderException(
                'upstream unavailable',
                statusCode: HttpStatus.serviceUnavailable,
              ),
            ),
          ),
          address: InternetAddress.loopbackIPv4,
        );

        try {
          final res = await http.post(
            Uri.parse(
              'http://127.0.0.1:${upstreamFailureServer.port}/v1/analyze',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image': base64Encode(validPngBytes),
              'sensitivityProfile': 'balanced',
            }),
          );

          expect(res.statusCode, HttpStatus.badGateway);
          final problem = jsonDecode(res.body) as Map<String, dynamic>;
          expect(
            problem['type'],
            'https://zenith.privacy/errors/vision-provider-failed',
          );
          expect(problem['title'], 'Vision Provider Failed');
          expect(problem['detail'], isNot(contains('GEMINI_API_KEY')));
        } finally {
          await upstreamFailureServer.close(force: true);
        }
      },
    );
  });
}

class _FailingVisionProvider implements IVisionAnalysisProvider {
  final Exception failure;

  _FailingVisionProvider(this.failure);

  @override
  Future<VisionAnalysisRawResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? sensitivity,
    String? model,
  }) async {
    throw failure;
  }
}
