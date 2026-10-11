import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/recommendation.dart';
import '../../../models/risk_level.dart';

/// Generates actionable, prioritized mitigation checklists linked to specific findings.
class RecommendationEngine {
  /// Generates mitigation recommendations from a collection of deduplicated findings.
  static List<Recommendation> generateRecommendations(
    List<DetectedElement> findings,
  ) {
    if (findings.isEmpty) {
      return [
        const Recommendation(
          id: 'rec_clean_baseline',
          priority: RiskLevel.low,
          title: 'Safe for Publication',
          action: 'No significant privacy or operational security leaks were detected in this image.',
          type: 'general',
          isCompleted: false,
          estimatedRiskReduction: 0,
          automatable: false,
        ),
      ];
    }

    final recommendations = <Recommendation>[];
    int counter = 1;

    // Sort findings by calculated risk contribution descending so most severe threats are mitigated first
    final sortedFindings = List<DetectedElement>.from(findings)
      ..sort(
        (a, b) => b.calculatedRiskContribution.compareTo(
          a.calculatedRiskContribution,
        ),
      );

    for (final f in sortedFindings) {
      final rec = _createRecommendationForFinding(f, 'rec_${counter++}');
      recommendations.add(rec);
    }

    // Add general EXIF stripping advice if location or device tags are possible
    final hasLocation = findings.any(
      (f) => f.category == ExposureCategory.location,
    );
    if (hasLocation) {
      recommendations.add(
        Recommendation(
          id: 'rec_exif_scrub_${DateTime.now().microsecondsSinceEpoch}',
          priority: RiskLevel.moderate,
          title: 'Scrub Image EXIF Metadata',
          action: 'Strip GPS coordinates, capture timestamp, and device serial numbers from the image file before publishing online.',
          type: 'scrub_exif',
          isCompleted: false,
          estimatedRiskReduction: 15,
          automatable: true,
        ),
      );
    }

    return recommendations;
  }

  static Recommendation _createRecommendationForFinding(
    DetectedElement f,
    String id,
  ) {
    final lowerName = f.name.toLowerCase();
    final lowerType = f.informationType.toLowerCase();

    // 1. Credentials & Passwords -> Solid Black Box (Never blur passwords - blur can be reversed via deconvolution)
    if (f.category == ExposureCategory.digital ||
        lowerName.contains('password') ||
        lowerName.contains('key') ||
        lowerName.contains('token') ||
        lowerType.contains('credential')) {
      return Recommendation(
        id: id,
        findingRef: f.id,
        priority: RiskLevel.critical,
        title: 'Apply Solid Censorship Bar over Credentials',
        action:
            'Overlay an opaque solid black box directly over "${f.name}". Do not use blur filters on text or secrets.',
        type: 'solid_censor',
        isCompleted: false,
        estimatedRiskReduction: (f.calculatedRiskContribution * 0.9).round(),
        automatable: true,
      );
    }

    // 2. Barcodes & QR codes -> Solid Censor
    if (lowerName.contains('barcode') ||
        lowerName.contains('qr') ||
        lowerName.contains('aztec') ||
        lowerType.contains('barcode')) {
      return Recommendation(
        id: id,
        findingRef: f.id,
        priority: RiskLevel.critical,
        title: 'Redact Machine-Readable Code',
        action: 'Black out the barcode or QR code completely. Barcodes contain unencrypted binary identity strings.',
        type: 'solid_censor',
        isCompleted: false,
        estimatedRiskReduction: (f.calculatedRiskContribution * 0.85).round(),
        automatable: true,
      );
    }

    // 3. Identification Cards & Badges -> Blur or Crop
    if (f.category == ExposureCategory.identity ||
        lowerName.contains('badge') ||
        lowerName.contains('id card')) {
      return Recommendation(
        id: id,
        findingRef: f.id,
        priority: f.riskLevel,
        title: 'Obscure Identity Document / Badge',
        action:
            'Apply a heavy Gaussian privacy blur or crop "${f.name}" to prevent institutional impersonation.',
        type: 'blur',
        isCompleted: false,
        estimatedRiskReduction: (f.calculatedRiskContribution * 0.80).round(),
        automatable: true,
      );
    }

    // 4. Vehicle Registration Plates -> Heavy Blur
    if (lowerName.contains('plate') || lowerType.contains('vehicle')) {
      return Recommendation(
        id: id,
        findingRef: f.id,
        priority: RiskLevel.high,
        title: 'Blur Vehicle License Plate',
        action: 'Apply a 25-pixel blur filter over license plate region before posting.',
        type: 'blur',
        isCompleted: false,
        estimatedRiskReduction: (f.calculatedRiskContribution * 0.75).round(),
        automatable: true,
      );
    }

    // 5. House number / Street sign -> Crop or Blur
    if (f.category == ExposureCategory.location) {
      return Recommendation(
        id: id,
        findingRef: f.id,
        priority: f.riskLevel,
        title: 'Conceal Residential Location Cue',
        action:
            'Crop the background or blur architectural markers and street placards for "${f.name}".',
        type: 'crop',
        isCompleted: false,
        estimatedRiskReduction: (f.calculatedRiskContribution * 0.70).round(),
        automatable: true,
      );
    }

    // Default Fallback
    return Recommendation(
      id: id,
      findingRef: f.id,
      priority: f.riskLevel,
      title: 'Remediate Sensitive Exposure',
      action: f.actionableMitigation.isNotEmpty
          ? f.actionableMitigation
          : 'Obscure or crop "${f.name}" to prevent unwanted disclosure.',
      type: 'blur',
      isCompleted: false,
      estimatedRiskReduction: (f.calculatedRiskContribution * 0.60).round(),
      automatable: true,
    );
  }
}
