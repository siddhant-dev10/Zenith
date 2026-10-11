import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import '../core/privacy_engine/providers/vision_analysis_provider.dart';
import '../models/privacy_audit_report.dart';

/// Service adapter for live Gemini Vision analysis.
///
/// Delegates to [ZenithAnalysisPipeline] with [GeminiVisionProvider], ensuring
/// that Gemini observations are strictly normalized and scored by Zenith's
/// deterministic risk engine.
class GeminiVisionService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Performs live multimodal privacy analysis via Google Gemini API + Zenith Deterministic Engine.
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

    final provider = GeminiVisionProvider(apiKey: cleanKey);
    final pipeline = ZenithAnalysisPipeline(visionProvider: provider);

    return pipeline.execute(
      imageBytes: imageBytes,
      imagePath: imagePath,
      sensitivity: sensitivity,
      model: model,
    );
  }

  static Future<bool> testApiKey(String apiKey) async {
    try {
      final cleanKey = apiKey.trim();
      final uri = Uri.parse(_baseUrl);
      final res = await http
          .get(uri, headers: {'x-goog-api-key': cleanKey})
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
