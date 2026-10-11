import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/risk_level.dart';

/// Raw observations output by a vision analysis provider before deterministic scoring.
class VisionAnalysisRawResult {
  final String sceneDescription;
  final List<DetectedElement> detectedElements;
  final Map<String, dynamic> rawModelMetadata;
  final bool isLiveAi;
  final int durationMs;

  const VisionAnalysisRawResult({
    required this.sceneDescription,
    required this.detectedElements,
    this.rawModelMetadata = const {},
    required this.isLiveAi,
    required this.durationMs,
  });
}

/// Abstract interface for vision analysis providers.
///
/// Enables seamless substitution between live Gemini Vision, local ML models,
/// and deterministic mock providers for testing.
abstract class IVisionAnalysisProvider {
  Future<VisionAnalysisRawResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? sensitivity,
    String? model,
  });
}

/// Thrown when vision provider encounters an unrecoverable API or network error.
class VisionProviderException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRateLimit;

  const VisionProviderException(
    this.message, {
    this.statusCode,
    this.isRateLimit = false,
  });

  @override
  String toString() => 'VisionProviderException: $message';
}

/// Live Google Gemini Vision provider utilizing multimodal prompt engineering.
///
/// Restricts Gemini to raw detection, localization, and description.
/// Numerical scoring authority is reserved for Zenith's DeterministicRiskEngine.
class GeminiVisionProvider implements IVisionAnalysisProvider {
  final String apiKey;
  final http.Client _httpClient;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiVisionProvider({required this.apiKey, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<VisionAnalysisRawResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? sensitivity,
    String? model,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw const VisionProviderException(
        'Gemini API key is required but was empty.',
      );
    }

    final targetModel = model ?? 'gemini-2.5-flash';
    final endpoint = Uri.parse('$_baseUrl/$targetModel:generateContent');
    final base64Image = base64Encode(imageBytes);

    final prompt =
        '''
You are ZENITH Vision Inspection Engine, an adversarial OPSEC and visual privacy analyst.
Examine this image for sensitive information, privacy risks, credentials, and trackable personal identifiers.

SENSITIVITY MODE: ${sensitivity ?? 'Balanced'}.

EVALUATE THESE CATEGORIES:
1. identity: Faces, Student IDs, Employee badges, Passports, Driver licenses, Portrait photos.
2. location: House numbers, Street signs, Distinct landmarks, Architectural views, Window reflections.
3. digital: Laptop/monitor screens, Mobile displays, Plaintext passwords, API keys, Tokens, Terminal code.
4. personal_info: Phone numbers, Email addresses, Credit/Debit cards, Mail envelopes, Barcodes, QR codes.
5. transportation: Vehicle license plates, Airline boarding passes, Transit tickets, Parking decals.

RULES:
- Provide exact normalized bounding boxes (0.0 to 1.0) when an element has a distinct visual footprint.
- Extract any readable text snippet into "evidenceText".
- Estimate baseSensitivity (1 to 100), exploitability (0.2 to 1.0), and visibilityScore (0.1 to 1.0).
- DO NOT GENERATE AN OVERALL SCORE. Numerical risk scoring is calculated deterministically by Zenith Core.

RESPOND STRICTLY WITH VALID JSON (No markdown code blocks or backticks):
{
  "sceneDescription": "Brief summary of image scene",
  "detectedElements": [
    {
      "name": "Specific feature name",
      "category": "identity | location | digital | personal_info | transportation",
      "riskLevel": "low | moderate | high | critical",
      "confidence": 0.95,
      "baseSensitivity": 85,
      "exploitability": 0.9,
      "visibilityScore": 0.95,
      "evidenceText": "Readable text or token if legible, otherwise null",
      "description": "Factual description of what was seen",
      "opsecImpact": "Why it is dangerous if shared online",
      "actionableMitigation": "Specific step to obscure or remove it",
      "boundingBox": { "left": 0.1, "top": 0.2, "width": 0.3, "height": 0.2 }
    }
  ]
}
''';

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
            {
              "inlineData": {"mimeType": mimeType, "data": base64Image},
            },
          ],
        },
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "temperature": 0.1,
      },
    };

    http.Response? response;
    int attempts = 0;
    const maxAttempts = 3;
    final stopwatch = Stopwatch()..start();

    while (attempts < maxAttempts) {
      attempts++;
      try {
        response = await _httpClient
            .post(
              endpoint,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': cleanKey,
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          break;
        } else if (response.statusCode == 429) {
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 500 * attempts));
            continue;
          }
          throw const VisionProviderException(
            'Gemini API rate limit exceeded (HTTP 429). Please retry shortly.',
            statusCode: 429,
            isRateLimit: true,
          );
        } else if (response.statusCode >= 500 && attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 400 * attempts));
          continue;
        } else {
          final errorBody = response.body.replaceAll(
            cleanKey,
            '[REDACTED_KEY]',
          );
          throw VisionProviderException(
            'Gemini API returned error ${response.statusCode}: $errorBody',
            statusCode: response.statusCode,
          );
        }
      } on VisionProviderException {
        rethrow;
      } catch (e) {
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 400 * attempts));
          continue;
        }
        throw VisionProviderException(
          'Gemini connection failed after $maxAttempts attempts: $e',
        );
      }
    }
    stopwatch.stop();

    if (response == null || response.statusCode != 200) {
      throw const VisionProviderException(
        'Failed to obtain a valid response from Gemini Vision API.',
      );
    }

    final dynamic decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } catch (e) {
      throw VisionProviderException(
        'Invalid JSON payload returned from Gemini endpoint: $e',
      );
    }

    final responseJson = decodedBody as Map<String, dynamic>;
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const VisionProviderException(
        'Gemini returned an empty candidates list (possibly blocked by safety filters).',
      );
    }

    final contentParts = candidates[0]['content']?['parts'] as List?;
    if (contentParts == null || contentParts.isEmpty) {
      throw const VisionProviderException(
        'Empty content returned from Gemini.',
      );
    }

    final rawText = contentParts[0]['text'] as String?;
    if (rawText == null || rawText.trim().isEmpty) {
      throw const VisionProviderException(
        'Gemini returned empty text response.',
      );
    }

    final cleanedText = rawText
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      throw VisionProviderException(
        'Failed to parse Gemini structured JSON: $e',
      );
    }

    final rawElements = (parsed['detectedElements'] as List? ?? []).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return DetectedElement.fromJson(map);
    }).toList();

    return VisionAnalysisRawResult(
      sceneDescription:
          parsed['sceneDescription'] as String? ?? 'Visual privacy analysis',
      detectedElements: rawElements,
      rawModelMetadata: {
        'model': targetModel,
        'durationMs': stopwatch.elapsedMilliseconds,
      },
      isLiveAi: true,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Offline mock vision provider for predictable unit testing and offline development.
class MockVisionProvider implements IVisionAnalysisProvider {
  final List<DetectedElement>? customFindings;
  final String customSceneDescription;

  MockVisionProvider({
    this.customFindings,
    this.customSceneDescription = 'Simulated visual inspection scene',
  });

  @override
  Future<VisionAnalysisRawResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? sensitivity,
    String? model,
  }) async {
    // Return pre-configured findings or default balanced scenario
    final findings =
        customFindings ??
        [
          const DetectedElement(
            id: 'mock_fnd_01',
            name: 'Primary Human Face',
            category: ExposureCategory.identity,
            riskLevel: RiskLevel.high,
            confidence: 0.94,
            baseSensitivity: 60,
            exploitability: 0.7,
            visibilityScore: 0.9,
            description: 'Facial biometric markers in focus.',
            opsecImpact:
                'Biometric face matchable against public social media indexes.',
            boundingBox: BoundingBox(
              left: 0.3,
              top: 0.2,
              width: 0.4,
              height: 0.4,
            ),
          ),
          const DetectedElement(
            id: 'mock_fnd_02',
            name: 'Background Residential Window',
            category: ExposureCategory.location,
            riskLevel: RiskLevel.moderate,
            confidence: 0.88,
            baseSensitivity: 40,
            exploitability: 0.6,
            visibilityScore: 0.8,
            description: 'Exterior skyline view through window.',
            opsecImpact:
                'Enables architectural triangulation to estimate neighborhood.',
            boundingBox: BoundingBox(
              left: 0.7,
              top: 0.1,
              width: 0.25,
              height: 0.3,
            ),
          ),
        ];

    return VisionAnalysisRawResult(
      sceneDescription: customSceneDescription,
      detectedElements: findings,
      rawModelMetadata: {'provider': 'mock'},
      isLiveAi: false,
      durationMs: 50,
    );
  }
}
