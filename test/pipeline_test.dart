import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/core/privacy_engine/api/zenith_api_contract.dart';
import 'package:zenith/core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import 'package:zenith/core/privacy_engine/providers/vision_analysis_provider.dart';
import 'package:zenith/core/privacy_engine/validation/image_validator.dart';
import 'package:zenith/models/detected_element.dart';
import 'package:zenith/models/exposure_category.dart';
import 'package:zenith/models/risk_level.dart';

void main() {
  group('ZenithAnalysisPipeline End-to-End Tests', () {
    // Standard minimal valid PNG header for in-memory testing
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

    test(
      'Pipeline rejects invalid image bytes before calling vision provider',
      () async {
        final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        final mockProvider = MockVisionProvider();
        final pipeline = ZenithAnalysisPipeline(visionProvider: mockProvider);

        expect(
          () => pipeline.execute(imageBytes: invalidBytes),
          throwsA(isA<ImageValidationException>()),
        );
      },
    );

    test('Pipeline executes full cycle: validation -> vision -> inference -> scoring -> recommendations', () async {
      final customFindings = [
        const DetectedElement(
          id: 'test_badge',
          name: 'Institutional Student ID Badge',
          category: ExposureCategory.identity,
          riskLevel: RiskLevel.critical,
          confidence: 0.95,
          baseSensitivity: 80,
          exploitability: 0.85,
          visibilityScore: 0.95,
          description: 'University badge visible on chest',
          opsecImpact: 'Identifies active student affiliation',
        ),
      ];

      final mockProvider = MockVisionProvider(customFindings: customFindings);
      final pipeline = ZenithAnalysisPipeline(visionProvider: mockProvider);

      final report = await pipeline.execute(imageBytes: validPngBytes);

      expect(report.id.isNotEmpty, true);
      expect(report.overallScore > 0, true);
      expect(report.detectedElements.isNotEmpty, true);
      expect(report.recommendations.isNotEmpty, true);
      expect(
        report.categoryScores.containsKey(ExposureCategory.identity),
        true,
      );
    });

    test('Pipeline enters partial failure and enforces risk floor >= 50 when provider fails with allowDegradedFallback=true', () async {
      final failingProvider = _FailingVisionProvider(
        const VisionProviderException('Simulated upstream API timeout'),
      );
      final pipeline = ZenithAnalysisPipeline(visionProvider: failingProvider);

      final report = await pipeline.execute(
        imageBytes: validPngBytes,
        allowDegradedFallback: true,
      );

      expect(report.processingStatus, 'partial_failure');
      expect(report.processingErrors.isNotEmpty, true);
      expect(
        report.processingErrors.first,
        contains('Simulated upstream API timeout'),
      );
      expect(report.analysisLimitations.isNotEmpty, true);
      // Safety floor: failed detector must NEVER emit score < 50
      expect(report.overallScore >= 50, true);
      expect(report.riskLevel != RiskLevel.low, true);
    });

    test('Pipeline rethrows exception when provider fails with allowDegradedFallback=false', () async {
      final failingProvider = _FailingVisionProvider(
        const VisionProviderException('Simulated unhandled AI failure'),
      );
      final pipeline = ZenithAnalysisPipeline(visionProvider: failingProvider);

      expect(
        () => pipeline.execute(
          imageBytes: validPngBytes,
          allowDegradedFallback: false,
        ),
        throwsA(isA<VisionProviderException>()),
      );
    });
  });

  group('GeminiVisionProvider Malformed Response & Error Handling Tests', () {
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

    test('GeminiVisionProvider rejects empty API key', () async {
      final provider = GeminiVisionProvider(apiKey: '   ');
      expect(
        () =>
            provider.analyze(imageBytes: validPngBytes, mimeType: 'image/png'),
        throwsA(isA<VisionProviderException>()),
      );
    });

    test(
      'GeminiVisionProvider handles malformed JSON response from Gemini',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'THIS IS NOT VALID JSON AT ALL {[[['},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        });

        final provider = GeminiVisionProvider(
          apiKey: 'test-key',
          httpClient: mockClient,
        );

        expect(
          () => provider.analyze(
            imageBytes: validPngBytes,
            mimeType: 'image/png',
          ),
          throwsA(
            isA<VisionProviderException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse Gemini structured JSON'),
            ),
          ),
        );
      },
    );

    test('GeminiVisionProvider handles empty candidates list (safety filter block)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'candidates': []}), 200);
      });

      final provider = GeminiVisionProvider(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      expect(
        () =>
            provider.analyze(imageBytes: validPngBytes, mimeType: 'image/png'),
        throwsA(
          isA<VisionProviderException>().having(
            (e) => e.message,
            'message',
            contains('empty candidates list'),
          ),
        ),
      );
    });

    test(
      'GeminiVisionProvider handles upstream HTTP 500 error after retries',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final provider = GeminiVisionProvider(
          apiKey: 'test-key',
          httpClient: mockClient,
        );

        expect(
          () => provider.analyze(
            imageBytes: validPngBytes,
            mimeType: 'image/png',
          ),
          throwsA(
            isA<VisionProviderException>().having(
              (e) => e.statusCode,
              'statusCode',
              500,
            ),
          ),
        );
      },
    );
  });

  group('ZenithApiContract Client Adapter Tests', () {
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

    test(
      'ZenithLocalClient executes analysis request for external camera app',
      () async {
        final client = ZenithLocalClient();
        final request = AnalyzeImageRequest(
          imageBytes: validPngBytes,
          clientRequestId: 'req_camera_123',
          sensitivityProfile: 'balanced',
        );

        final response = await client.analyzeImage(request);

        expect(response.analysisId.isNotEmpty, true);
        expect(response.overallScore >= 0, true);
        expect(response.categoryScores.containsKey('identity'), true);
        expect(response.findings.isNotEmpty, true);
        expect(response.recommendations.isNotEmpty, true);

        // Verify JSON serialization format required by API specification
        final json = response.toJson();
        expect(json.containsKey('analysisId'), true);
        expect(json.containsKey('riskAssessment'), true);

        // Verify deserialization symmetry
        final reconstituted = AnalyzeImageResponse.fromJson(json);
        expect(reconstituted.analysisId, response.analysisId);
        expect(reconstituted.overallScore, response.overallScore);
        expect(reconstituted.severityLevel, response.severityLevel);
        expect(reconstituted.findings.length, response.findings.length);
      },
    );

    test('ZenithLocalClient handles rescan verification request and fromJson roundtrip', () async {
      final client = ZenithLocalClient();
      final rescanReq = RescanVerificationRequest(
        originalAnalysisId: 'aud_original_123',
        redactedImageBytes: validPngBytes,
      );

      final rescanRes = await client.verifyRescan(rescanReq);

      expect(rescanRes.rescanId.isNotEmpty, true);
      expect(rescanRes.originalAnalysisId, 'aud_original_123');
      expect(rescanRes.verificationStatus.isNotEmpty, true);

      final json = rescanRes.toJson();
      final reconstituted = RescanVerificationResponse.fromJson(json);
      expect(reconstituted.rescanId, rescanRes.rescanId);
      expect(reconstituted.originalScore, rescanRes.originalScore);
      expect(reconstituted.scoreDelta, rescanRes.scoreDelta);
      expect(reconstituted.verificationStatus, rescanRes.verificationStatus);
    });
  });

  group('Section 4 & 5 Gemini Vision Structured Schema and Independent Scoring Tests', () {
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

    test('GeminiVisionProvider parses full Section 4 schema (image_summary, findings, inferences, analysis_limitations)', () async {
      final mockPayload = {
        'image_summary':
            'An office desk with an employee badge and computer monitor.',
        'findings': [
          {
            'category': 'identity',
            'type': 'employee_badge',
            'description':
                'Corporate security badge with photo and name visible.',
            'evidence': 'Acme Corp - Jane Doe - Eng ID #8841',
            'confidence': 0.98,
            'severity': 'high',
            'exposure_type': 'direct',
            'recommendation':
                'Blur badge or remove photo and employee ID number.',
            'bounding_box': {
              'left': 0.15,
              'top': 0.45,
              'width': 0.2,
              'height': 0.25,
            },
          },
          {
            'category': 'digital_security',
            'type': 'terminal_token',
            'description':
                'Active bash shell showing AWS credentials environment export.',
            'evidence': 'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCY',
            'confidence': 0.99,
            'severity': 'critical',
            'exposure_type': 'direct',
            'recommendation':
                'Rotate AWS key immediately and blackout terminal window.',
            'bounding_box': {
              'left': 0.4,
              'top': 0.1,
              'width': 0.5,
              'height': 0.6,
            },
          },
        ],
        'inferences': [
          'Affiliation with Acme Corp combined with AWS key creates targeting vector for cloud compromise.',
        ],
        'analysis_limitations': [
          'Background whiteboard has partially illegible handwriting.',
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(mockPayload)},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = GeminiVisionProvider(
        apiKey: 'test-gemini-key',
        model: 'gemini-3.5-flash',
        httpClient: mockClient,
      );

      final result = await provider.analyze(
        imageBytes: validPngBytes,
        mimeType: 'image/png',
      );

      expect(
        result.sceneDescription,
        contains('office desk with an employee badge'),
      );
      expect(result.detectedElements.length, 2);
      expect(result.detectedElements[0].name, 'employee_badge');
      expect(result.detectedElements[0].category, ExposureCategory.identity);
      expect(result.detectedElements[0].riskLevel, RiskLevel.high);
      expect(result.detectedElements[0].evidenceText, contains('Jane Doe'));
      expect(result.detectedElements[1].name, 'terminal_token');
      expect(result.detectedElements[1].category, ExposureCategory.digital);
      expect(result.detectedElements[1].riskLevel, RiskLevel.critical);
      expect(result.inferences.length, 1);
      expect(result.analysisLimitations.length, 1);
      expect(result.provider, 'gemini');
      expect(result.model, 'gemini-3.5-flash');
    });

    test('Clean image with zero detected risks produces score 0 and LOW risk level', () async {
      final mockPayload = {
        'image_summary': 'A generic landscape view of trees and mountains.',
        'findings': [],
        'inferences': [],
        'analysis_limitations': [],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(mockPayload)},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = GeminiVisionProvider(
        apiKey: 'test-gemini-key',
        httpClient: mockClient,
      );
      final pipeline = ZenithAnalysisPipeline(visionProvider: provider);

      final report = await pipeline.execute(imageBytes: validPngBytes);

      expect(report.overallScore, 0);
      expect(report.riskLevel, RiskLevel.low);
      expect(report.detectedElements.isEmpty, true);
      expect(report.title, contains('Clean Baseline'));
    });

    test('Distinct images produce distinct scores and findings, resolving repeated 43/100', () async {
      // Image A: Casual family photo with faces (Moderate risk)
      final imageAPayload = {
        'image_summary': 'A family portrait in a park.',
        'findings': [
          {
            'category': 'identity',
            'type': 'family_faces',
            'description': 'Three recognizable faces.',
            'evidence': 'Unblurred biometric portraits.',
            'confidence': 0.85,
            'severity': 'moderate',
            'exposure_type': 'direct',
            'recommendation': 'Blur faces of minors before social posting.',
          },
        ],
        'inferences': [],
        'analysis_limitations': [],
      };

      // Image B: Severe financial and passport breach (Critical risk)
      final imageBPayload = {
        'image_summary':
            'Desk with international passport, credit card, and utility bill.',
        'findings': [
          {
            'category': 'identity',
            'type': 'international_passport',
            'description': 'Passport open to MRZ machine readable zone.',
            'evidence': 'P<USADOE<<JOHN<<<<<<<<<<<<<<<<<<',
            'confidence': 0.99,
            'severity': 'critical',
            'exposure_type': 'direct',
            'recommendation': 'Never photograph open travel passports.',
          },
          {
            'category': 'personal_information',
            'type': 'credit_card',
            'description': 'Visa payment card with full 16-digit PAN visible.',
            'evidence': '4111 2222 3333 4444',
            'confidence': 0.99,
            'severity': 'critical',
            'exposure_type': 'direct',
            'recommendation': 'Freeze card and request immediate reissue.',
          },
        ],
        'inferences': ['Full identity theft package exposed.'],
        'analysis_limitations': [],
      };

      final clientA = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(imageAPayload)},
                  ],
                },
              },
            ],
          }),
          200,
        ),
      );
      final clientB = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(imageBPayload)},
                  ],
                },
              },
            ],
          }),
          200,
        ),
      );

      final pipelineA = ZenithAnalysisPipeline(
        visionProvider: GeminiVisionProvider(
          apiKey: 'key',
          httpClient: clientA,
        ),
      );
      final pipelineB = ZenithAnalysisPipeline(
        visionProvider: GeminiVisionProvider(
          apiKey: 'key',
          httpClient: clientB,
        ),
      );

      final reportA = await pipelineA.execute(imageBytes: validPngBytes);
      final reportB = await pipelineB.execute(imageBytes: validPngBytes);

      // Verify that reports are image-specific and scores are not locked to 43!
      expect(reportA.overallScore, isNot(equals(reportB.overallScore)));
      expect(reportA.overallScore, isNot(equals(43)));
      expect(reportB.overallScore, greaterThan(75)); // Critical
      expect(reportB.riskLevel, RiskLevel.critical);
      expect(reportA.detectedElements.length, 1);
      expect(reportB.detectedElements.length, 2);
    });
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
