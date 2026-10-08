import 'dart:typed_data';
import '../models/detected_element.dart';
import '../models/exposure_category.dart';
import '../models/inferred_insight.dart';
import '../models/privacy_audit_report.dart';
import '../models/recommendation.dart';
import '../models/risk_level.dart';
import 'sample_data_service.dart';

class MockAnalysisService {
  /// Analyzes an image using Zenith's onboard heuristic privacy risk engine
  static Future<PrivacyAuditReport> analyzeImage({
    Uint8List? imageBytes,
    String? imagePath,
    String? sampleAsset,
  }) async {
    // Simulate real neural network scanning latency
    await Future.delayed(const Duration(milliseconds: 1400));

    // Check if it's one of the known sample assets
    if (sampleAsset != null) {
      final sample = SampleDataService.getScenarios().firstWhere(
        (s) => s.assetPath == sampleAsset,
        orElse: () => SampleDataService.getScenarios().first,
      );
      return sample.report.copyWith(
        id: 'audit_mock_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        imageBytes: imageBytes,
        imagePath: imagePath,
        sampleAsset: sampleAsset,
        isLiveAi: false,
      );
    }

    // Heuristic generator for any camera photo or gallery upload
    return _generateHeuristicReport(
      imageBytes: imageBytes,
      imagePath: imagePath,
    );
  }

  static PrivacyAuditReport _generateHeuristicReport({
    Uint8List? imageBytes,
    String? imagePath,
  }) {
    final now = DateTime.now();
    // Default balanced simulation for arbitrary user photos
    const overallScore = 64;
    final riskLevel = RiskLevel.fromScore(overallScore);

    return PrivacyAuditReport(
      id: 'audit_heuristic_${now.millisecondsSinceEpoch}',
      timestamp: now,
      imageBytes: imageBytes,
      imagePath: imagePath,
      overallScore: overallScore,
      riskLevel: riskLevel,
      title: 'High Risk Visual Exposure Detected',
      summary:
          'Automated computer vision scan detected prominent facial features, background architectural structures, and digital device silhouettes presenting elevated privacy exposure.',
      categoryScores: {
        ExposureCategory.identity: 70,
        ExposureCategory.location: 55,
        ExposureCategory.digital: 45,
        ExposureCategory.personalInfo: 30,
        ExposureCategory.transportation: 15,
      },
      detectedElements: [
        DetectedElement(
          id: 'elem_gen_1',
          name: 'Primary Human Face / Biometric Silhouette',
          category: ExposureCategory.identity,
          riskLevel: RiskLevel.high,
          confidence: 0.94,
          description:
              'Biometric facial markers detected with high clarity in center-frame.',
          opsecImpact:
              'Can be mapped to facial recognition indexing engines and social media scrapers.',
          boundingBox: const BoundingBox(
            left: 0.32,
            top: 0.18,
            width: 0.36,
            height: 0.40,
          ),
        ),
        DetectedElement(
          id: 'elem_gen_2',
          name: 'Background Architectural & Window View',
          category: ExposureCategory.location,
          riskLevel: RiskLevel.moderate,
          confidence: 0.88,
          description:
              'Window reflections and exterior building lines visible in upper quadrant.',
          opsecImpact:
              'Can be cross-referenced via sun angle analysis and street panorama databases to determine floor level and neighborhood.',
          boundingBox: const BoundingBox(
            left: 0.65,
            top: 0.08,
            width: 0.30,
            height: 0.35,
          ),
        ),
        DetectedElement(
          id: 'elem_gen_3',
          name: 'Digital Device / Screen Glare',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.moderate,
          confidence: 0.82,
          description:
              'Screen illumination or hardware silhouette detected in peripheral bounds.',
          opsecImpact:
              'Potential reflection of open browser windows, active apps, or notification banners.',
          boundingBox: const BoundingBox(
            left: 0.08,
            top: 0.58,
            width: 0.32,
            height: 0.32,
          ),
        ),
      ],
      inferredInsights: [
        InferredInsight(
          id: 'inf_gen_1',
          category: ExposureCategory.location,
          directObservation: 'Exterior daylight illumination & architectural lines',
          inferredInsight:
              'User is currently located in an urban residential or commercial workspace during daytime.',
          attackerThreatProfile:
              'Helps adversaries establish current time-zone, working schedule, and geographic perimeter.',
          severity: RiskLevel.moderate,
          confidence: 0.85,
        ),
        InferredInsight(
          id: 'inf_gen_2',
          category: ExposureCategory.identity,
          directObservation: 'Clear facial portrait',
          inferredInsight:
              'Direct triangulation with public LinkedIn, Twitter/X, or GitHub avatars.',
          attackerThreatProfile:
              'Attacker can correlate online pseudonyms with real-world legal identity.',
          severity: RiskLevel.high,
          confidence: 0.92,
        ),
      ],
      recommendations: [
        Recommendation(
          id: 'rec_gen_1',
          priority: RiskLevel.high,
          title: 'Crop or Soften Peripheral Background',
          action:
              'Consider cropping background windows and desk perimeters to eliminate geo-location cues.',
          type: 'crop',
        ),
        Recommendation(
          id: 'rec_gen_2',
          priority: RiskLevel.moderate,
          title: 'Strip EXIF Metadata Headers',
          action:
              'Before uploading, ensure your phone does not attach camera serial number and GPS coordinates.',
          type: 'scrub_exif',
        ),
        Recommendation(
          id: 'rec_gen_3',
          priority: RiskLevel.moderate,
          title: 'Check Screen Reflections',
          action:
              'Ensure glasses lenses or dark tables do not mirror confidential passwords or messages.',
          type: 'blur',
        ),
      ],
      exifMetadata: {
        'CameraModel': 'High-Definition Sensor',
        'ISO': '100',
        'FocalLength': '26mm eq.',
        'DateTime': now.toIso8601String(),
        'GPSTagged': false,
      },
      isLiveAi: false,
      scanDurationMs: 1350,
    );
  }
}
