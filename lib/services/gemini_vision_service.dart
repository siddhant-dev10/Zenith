import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/detected_element.dart';
import '../models/exposure_category.dart';
import '../models/inferred_insight.dart';
import '../models/privacy_audit_report.dart';
import '../models/recommendation.dart';
import '../models/risk_level.dart';

class GeminiVisionService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Performs live multimodal privacy & OPSEC analysis via Google Gemini API
  static Future<PrivacyAuditReport> analyzeImage({
    required Uint8List imageBytes,
    required String apiKey,
    String model = AppConstants.defaultGeminiModel,
    String? imagePath,
    String mimeType = 'image/jpeg',
    String sensitivity = AppConstants.sensitivityBalanced,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception(
        'Gemini API Key is missing. Please configure your API key in Settings.',
      );
    }

    final endpoint = Uri.parse('$_baseUrl/$model:generateContent?key=$cleanKey');
    final base64Image = base64Encode(imageBytes);

    final systemInstruction = '''
You are ZENITH, an elite AI-Powered Privacy and Operational Security (OPSEC) Risk Assessment System.
Your job is to analyze captured photos before they are posted online, identify every privacy and security risk, evaluate direct exposure, and infer what an adversary or OSINT investigator could deduce.

SENSITIVITY MODE: $sensitivity.

CATEGORIES TO EVALUATE:
1. Identity Exposure (Faces, Student IDs, Employee badges, Government IDs, Portraits)
2. Location Exposure (Street signs, House numbers, Landmarks, Recognizable buildings, GPS cues)
3. Digital Exposure (Laptop/monitor screens, Mobile phones, Open applications, Passwords/API keys, Terminal code)
4. Personal Information Exposure (Phone numbers, Email addresses, Barcodes, QR codes, Mail, Financial documents)
5. Transportation Exposure (Vehicle number plates, Parking permits, Travel tickets, Boarding passes)

SCORING RULES:
- 0-25: Low Risk (Clean/safe photo with negligible exposure)
- 26-50: Moderate Risk (Some identifiable details, caution needed)
- 51-75: High Risk (Significant PII, location tracing, or credential risks)
- 76-100: Critical Risk (Severe OPSEC breach: visible passwords/keys, unblurred IDs, boarding passes, exact home address)

BOUNDING BOXES:
For each detected sensitive element, provide normalized bounding box coordinates:
- "left": 0.0 to 1.0 (relative X start from left)
- "top": 0.0 to 1.0 (relative Y start from top)
- "width": 0.0 to 1.0 (relative width)
- "height": 0.0 to 1.0 (relative height)

INFERENCE ENGINE (Key Differentiator):
Do not only state what is visible. Deduce what an attacker can infer:
e.g., Visible Student ID -> Inferred: Institution, Student Status, Approximate Age, Degree Program.
e.g., Visible Building -> Inferred: City, Area, Workplace, Commute Pattern.

OUTPUT STRICTLY VALID JSON WITH NO BACKTICKS OR MARKDOWN FORMATTING:
{
  "overallScore": 74,
  "riskLevel": "high",
  "title": "High Risk Privacy & Location Exposure",
  "summary": "Concise 2-sentence executive summary of the exposure risks.",
  "categoryScores": {
    "identity": 80,
    "location": 65,
    "digital": 40,
    "personal_info": 90,
    "transportation": 20
  },
  "detectedElements": [
    {
      "name": "Element name",
      "category": "identity | location | digital | personal_info | transportation",
      "riskLevel": "low | moderate | high | critical",
      "confidence": 0.95,
      "description": "What was seen",
      "opsecImpact": "Why it is dangerous if shared online",
      "boundingBox": { "left": 0.1, "top": 0.2, "width": 0.4, "height": 0.3 }
    }
  ],
  "inferredInsights": [
    {
      "category": "identity | location | digital | personal_info | transportation",
      "directObservation": "What is directly visible",
      "inferredInsight": "What an attacker or stalker can deduce",
      "attackerThreatProfile": "How an adversary weaponizes this insight",
      "severity": "low | moderate | high | critical",
      "confidence": 0.92
    }
  ],
  "recommendations": [
    {
      "priority": "critical | high | moderate | low",
      "title": "Action title",
      "action": "Specific mitigation instructions",
      "type": "blur | crop | scrub_exif | do_not_share | rotate | general"
    }
  ]
}
''';

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": systemInstruction},
            {
              "inlineData": {
                "mimeType": mimeType,
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "temperature": 0.2,
      }
    };

    final stopwatch = Stopwatch()..start();
    final response = await http.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    stopwatch.stop();

    if (response.statusCode != 200) {
      final err = response.body;
      throw Exception('Gemini API Error (${response.statusCode}): $err');
    }

    final responseJson = jsonDecode(response.body);
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No analysis response generated by Gemini Vision.');
    }

    final contentParts = candidates[0]['content']?['parts'] as List?;
    if (contentParts == null || contentParts.isEmpty) {
      throw Exception('Empty content returned from Gemini.');
    }

    final rawText = contentParts[0]['text'] as String;
    // Clean potential markdown fencing if returned
    final cleanedText = rawText
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final Map<String, dynamic> parsed = jsonDecode(cleanedText);

    // Map categories
    final catScoresRaw = parsed['categoryScores'] as Map<String, dynamic>? ?? {};
    final categoryScores = <ExposureCategory, int>{};
    for (final cat in ExposureCategory.values) {
      categoryScores[cat] = (catScoresRaw[cat.id] as num?)?.toInt() ?? 0;
    }

    final score = (parsed['overallScore'] as num?)?.toInt() ?? 50;

    return PrivacyAuditReport(
      id: 'audit_live_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      imagePath: imagePath,
      imageBytes: imageBytes,
      overallScore: score,
      riskLevel: RiskLevel.fromScore(score),
      title: parsed['title'] as String? ?? 'Gemini Privacy Audit Assessment',
      summary: parsed['summary'] as String? ?? 'Analysis completed successfully.',
      categoryScores: categoryScores,
      detectedElements: (parsed['detectedElements'] as List? ?? [])
          .map((e) => DetectedElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      inferredInsights: (parsed['inferredInsights'] as List? ?? [])
          .map((e) => InferredInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (parsed['recommendations'] as List? ?? [])
          .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      isLiveAi: true,
      scanDurationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Verifies if an API key works by sending a ping to list models
  static Future<bool> testApiKey(String apiKey) async {
    try {
      final cleanKey = apiKey.trim();
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey',
      );
      final res = await http.get(uri);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
