import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/risk_level.dart';
import '../scoring/deterministic_risk_engine.dart';

/// Raw observations output by a vision analysis provider before deterministic scoring.
class VisionAnalysisRawResult {
  final String sceneDescription;
  final List<DetectedElement> detectedElements;
  final Map<String, dynamic> rawModelMetadata;
  final bool isLiveAi;
  final int durationMs;
  final List<String> inferences;
  final List<String> analysisLimitations;
  final String model;
  final String provider;

  const VisionAnalysisRawResult({
    required this.sceneDescription,
    required this.detectedElements,
    this.rawModelMetadata = const {},
    required this.isLiveAi,
    required this.durationMs,
    this.inferences = const [],
    this.analysisLimitations = const [],
    this.model = 'mock-heuristic',
    this.provider = 'mock',
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

/// Unconfigured provider used when server has no GEMINI_API_KEY.
/// Rejects real image analysis explicitly instead of falling back to fake mock results.
class UnconfiguredVisionProvider implements IVisionAnalysisProvider {
  final String message;

  const UnconfiguredVisionProvider({
    this.message = 'GEMINI_API_KEY environment variable is not configured on the server. Real image analysis requires valid Google Gemini credentials.',
  });

  @override
  Future<VisionAnalysisRawResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? sensitivity,
    String? model,
  }) async {
    throw VisionProviderException(message, statusCode: 503);
  }
}

/// Live Google Gemini Vision provider utilizing multimodal prompt engineering.
///
/// Restricts Gemini to raw detection, localization, and description.
/// Numerical scoring authority is reserved for Zenith's DeterministicRiskEngine.
class GeminiVisionProvider implements IVisionAnalysisProvider {
  final String apiKey;
  final String model;
  final http.Client _httpClient;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiVisionProvider({
    required this.apiKey,
    this.model = 'gemini-3.5-flash-lite',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

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
        statusCode: 401,
      );
    }

    var currentModel = model ?? this.model;
    final base64Image = base64Encode(imageBytes);

    final prompt =
        '''
You are ZENITH Vision Inspection Engine, an adversarial OPSEC and visual privacy analyst.
Evaluate this photograph for privacy exposures, security risks, credentials, and trackable personal identifiers.

SENSITIVITY PROFILE: ${sensitivity ?? 'Balanced'}.

EVALUATE THESE CATEGORIES AND SEVERITIES CAREFULLY:
1. identity:
   - Faces, selfies, and individual portraits in public or ordinary settings are LOW severity.
   - Student IDs, University campus cards, and Employee/Corporate badges are HIGH severity.
   - Government passports, Driver licenses, and National identification cards are CRITICAL severity.
2. personal_information:
   - Direct personal phone numbers, private emails, and physical mailing addresses are HIGH severity.
   - Bank account statements, credit card numbers, and financial records are CRITICAL severity.
3. digital_security:
   - Ambient computer/tv screens or benign wallpaper displays without secrets are LOW severity.
   - Visible terminal shells, active code, or internal network topology are MODERATE severity.
   - Plaintext passwords, API keys, private tokens, and credentials are CRITICAL severity.
4. location_exposure:
   - Generic outdoor scenery, nature landscapes, and diffuse room interiors are LOW severity.
   - Residential house numbers, street plaques, and geolocatable domicile signs are HIGH severity.
5. other_exposures:
   - Vehicle registration plates, airline boarding passes (PNR codes/barcodes), and transit tickets are HIGH severity.

STRICT INSTRUCTIONS:
- Distinguish direct exposures (clearly visible data) from contextual inferences (deduced from clues).
- For evidence, provide factual observed visual details or legible text snippets without hallucination. Do not invent or guess unreadable text.
- If no privacy exposures are detected (e.g. an empty nature scene), return an empty "findings" list.
- DO NOT CALCULATE OR RETURN AN OVERALL RISK SCORE. Numerical scoring is computed independently by Zenith's deterministic risk engine.
- Return ONLY a valid JSON object matching the schema below. Never wrap the output in markdown code fences (```) or backticks. Never include conversational text.

JSON SCHEMA:
{
  "image_summary": "A concise factual description of what is visible in the photograph.",
  "findings": [
    {
      "category": "identity | personal_information | digital_security | location_exposure | other_exposures",
      "type": "Specific feature type (e.g. student_id, face, license_plate, api_token, home_address, monitor_screen)",
      "description": "Factual explanation of what was observed",
      "evidence": "Observed visual detail or legible text snippet without hallucination",
      "confidence": 0.95,
      "severity": "low | moderate | high | critical",
      "exposure_type": "direct | inference",
      "recommendation": "Actionable mitigation advice (e.g. blur face, redact barcode, crop document)",
      "bounding_box": { "left": 0.1, "top": 0.2, "width": 0.3, "height": 0.2 }
    }
  ],
  "inferences": [
    "Potential risk inferred from combination of visual clues (if any)"
  ],
  "analysis_limitations": [
    "Anything ambiguous, low-resolution, obscured, or unreadable (if any)"
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
      final endpoint = Uri.parse('$_baseUrl/$currentModel:generateContent');
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
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          break;
        } else if (response.statusCode == 429) {
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 1000 * attempts));
            continue;
          }
          throw const VisionProviderException(
            'Gemini API rate limit or quota exceeded (HTTP 429). Please retry shortly.',
            statusCode: 429,
            isRateLimit: true,
          );
        } else if (response.statusCode >= 500 && attempts < maxAttempts) {
          if (response.statusCode == 503 &&
              currentModel != 'gemini-3.5-flash-lite') {
            currentModel = 'gemini-3.5-flash-lite';
          }
          await Future.delayed(Duration(milliseconds: 1200 * attempts));
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

    // Robust JSON parsing: strip potential markdown code fences and isolate outermost JSON block
    var cleanedText = rawText
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final firstBrace = cleanedText.indexOf('{');
    final lastBrace = cleanedText.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);
    }

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      throw VisionProviderException(
        'Failed to parse Gemini structured JSON: $e',
      );
    }

    // Support both schema variations: "findings" or "detectedElements"
    final rawFindings =
        (parsed['findings'] as List? ??
        parsed['detectedElements'] as List? ??
        []);

    final detectedElements = <DetectedElement>[];
    for (int i = 0; i < rawFindings.length; i++) {
      final f = Map<String, dynamic>.from(rawFindings[i] as Map);
      final categoryStr = f['category'] as String? ?? 'identity';
      final category = ExposureCategory.fromString(categoryStr);

      final severityStr =
          (f['severity'] as String? ?? f['riskLevel'] as String? ?? 'moderate')
              .toLowerCase();
      final riskLevel = RiskLevel.fromString(severityStr);

      final exposureType =
          (f['exposure_type'] as String? ??
                  (f['isDirectExposure'] == false ? 'inference' : 'direct'))
              .toLowerCase();
      final isDirect = exposureType != 'inference';

      final confidence = ((f['confidence'] as num?)?.toDouble() ?? 0.85).clamp(
        0.0,
        1.0,
      );
      final type =
          f['type'] as String? ??
          f['informationType'] as String? ??
          f['name'] as String? ??
          'Sensitive Feature';
      final description = f['description'] as String? ?? '';
      final evidence = f['evidence'] as String? ?? f['evidenceText'] as String?;
      final recommendation =
          f['recommendation'] as String? ??
          f['actionableMitigation'] as String? ??
          '';

      final calibrated = DeterministicRiskEngine.calibrateElementMetrics(
        category: category,
        nameOrType: type,
        rawSeverity: severityStr,
        isDirect: isDirect,
        confidence: confidence,
      );

      BoundingBox? bbox;
      if (f['bounding_box'] != null && f['bounding_box'] is Map) {
        bbox = BoundingBox.fromJson(
          Map<String, dynamic>.from(f['bounding_box'] as Map),
        );
      } else if (f['boundingBox'] != null && f['boundingBox'] is Map) {
        bbox = BoundingBox.fromJson(
          Map<String, dynamic>.from(f['boundingBox'] as Map),
        );
      }

      detectedElements.add(
        DetectedElement(
          id: 'fnd_${DateTime.now().microsecondsSinceEpoch}_$i',
          name: type,
          category: category,
          riskLevel: riskLevel,
          confidence: confidence,
          description: description,
          opsecImpact: isDirect
              ? 'Direct exposure of $type poses immediate OPSEC and privacy disclosure risks.'
              : 'Secondary contextual indicator contributing to identity or location inference.',
          evidenceText: evidence,
          actionableMitigation: recommendation,
          isDirectExposure: isDirect,
          informationType: type,
          baseSensitivity: calibrated.baseSensitivity,
          exploitability: calibrated.exploitability,
          visibilityScore: calibrated.visibilityScore,
          severityReason: calibrated.severityReason,
          boundingBox: bbox,
        ),
      );
    }

    final imageSummary =
        parsed['image_summary'] as String? ??
        parsed['sceneDescription'] as String? ??
        (detectedElements.isEmpty
            ? 'No sensitive privacy risks detected in the image.'
            : 'Visual privacy analysis of photograph.');

    final inferences = (parsed['inferences'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    final limitations = (parsed['analysis_limitations'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    return VisionAnalysisRawResult(
      sceneDescription: imageSummary,
      detectedElements: detectedElements,
      rawModelMetadata: {
        'model': currentModel,
        'provider': 'gemini',
        'durationMs': stopwatch.elapsedMilliseconds,
      },
      isLiveAi: true,
      durationMs: stopwatch.elapsedMilliseconds,
      inferences: inferences,
      analysisLimitations: limitations,
      model: currentModel,
      provider: 'gemini',
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
      rawModelMetadata: {'provider': 'mock', 'model': 'mock-engine'},
      isLiveAi: false,
      durationMs: 50,
      model: 'mock-engine',
      provider: 'mock',
    );
  }
}
