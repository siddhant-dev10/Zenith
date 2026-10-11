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
      expect(body['service'], 'zenith-privacy-intelligence-engine');
      expect(body['version'], '1.0.0');
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
  });
}
