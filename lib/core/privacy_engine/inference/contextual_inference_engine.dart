import '../../../models/detected_element.dart';
import '../../../models/exposure_category.dart';
import '../../../models/inferred_insight.dart';
import '../../../models/risk_level.dart';

/// Analyzes correlations between detected elements to synthesize attacker-perspective inferences.
///
/// Operates defensively: models what an OSINT researcher or stalker could deduce
/// from multi-vector exposure without hallucinating or speculating.
class ContextualInferenceEngine {
  /// Analyzes a list of validated findings to produce structured inferences.
  static List<InferredInsight> synthesizeInferences(
    List<DetectedElement> findings,
  ) {
    if (findings.isEmpty) return [];

    final inferences = <InferredInsight>[];

    // Helper lookup
    Iterable<DetectedElement> findByType(String typeSnippet) => findings.where(
      (f) =>
          f.informationType.toLowerCase().contains(typeSnippet.toLowerCase()) ||
          f.name.toLowerCase().contains(typeSnippet.toLowerCase()),
    );

    // Rule 1: Student or Corporate ID + Location or Schedule (EXCLUDE ordinary faces)
    final idFindings = findings.where((f) {
      final lowerName = f.name.toLowerCase();
      final lowerType = f.informationType.toLowerCase();
      final isFace =
          lowerName.contains('face') ||
          lowerType.contains('face') ||
          lowerName.contains('portrait') ||
          lowerType.contains('portrait') ||
          lowerName.contains('person') ||
          lowerType.contains('person') ||
          lowerName.contains('selfie') ||
          lowerType.contains('selfie');
      if (isFace) return false;

      return lowerName.contains('badge') ||
          lowerType.contains('badge') ||
          lowerName.contains('student id') ||
          lowerType.contains('student_id') ||
          lowerName.contains('campus card') ||
          lowerType.contains('campus_card') ||
          lowerName.contains('employee') ||
          lowerType.contains('employee') ||
          lowerName.contains('lanyard') ||
          lowerType.contains('lanyard') ||
          lowerName.contains('id card') ||
          lowerType.contains('id_card');
    });
    final locationFindings = findings.where(
      (f) =>
          f.category == ExposureCategory.location ||
          f.category == ExposureCategory.personalInfo,
    );

    if (idFindings.isNotEmpty && locationFindings.isNotEmpty) {
      final primaryId = idFindings.first;
      final supportingIds = [
        primaryId.id,
        ...locationFindings.map((l) => l.id),
      ];

      inferences.add(
        InferredInsight(
          id: 'inf_institutional_${DateTime.now().microsecondsSinceEpoch}',
          category: ExposureCategory.identity,
          directObservation:
              'Visible credential badge (${primaryId.name}) paired with physical location indicators.',
          inferredInsight: 'Adversary can determine institutional affiliation, cohort schedule, and routine physical presence intervals.',
          attackerThreatProfile: 'Targeted spear-phishing utilizing institutional context, physical campus stalking, or pretexting for unauthorized building access.',
          severity: RiskLevel.high,
          confidence: 0.90,
          supportingEvidenceIds: supportingIds,
          epistemicLevel: EpistemicLevel.corroboratedDeduction,
          uncertaintyAssessment: 'High certainty of affiliation; physical schedule is deduced from standard institutional operating hours.',
        ),
      );
    }

    // Rule 2: Travel Ticket / Boarding Pass
    final travelFindings = findings.where(
      (f) =>
          f.category == ExposureCategory.transportation ||
          f.name.toLowerCase().contains('boarding pass') ||
          f.name.toLowerCase().contains('pnr') ||
          f.informationType.toLowerCase().contains('travel'),
    );

    if (travelFindings.isNotEmpty) {
      final primaryTravel = travelFindings.first;
      inferences.add(
        InferredInsight(
          id: 'inf_travel_${DateTime.now().microsecondsSinceEpoch}',
          category: ExposureCategory.transportation,
          directObservation:
              'Visible travel document or transit token (${primaryTravel.name}).',
          inferredInsight: 'Reveals active departure timeline, transit trajectory, and unoccupied domicile window.',
          attackerThreatProfile: 'Intruders exploit verified travel windows to execute physical burglary during known residential absence intervals.',
          severity: RiskLevel.critical,
          confidence: 0.94,
          supportingEvidenceIds: travelFindings.map((t) => t.id).toList(),
          epistemicLevel: EpistemicLevel.corroboratedDeduction,
          uncertaintyAssessment: 'Verified departure date and itinerary extracted from ticket confirmation or barcode structure.',
        ),
      );
    }

    // Rule 3: Digital Terminal / Cloud Credentials (EXCLUDE blank/benign screens)
    final digitalFindings = findings.where((f) {
      final lowerName = f.name.toLowerCase();
      final lowerType = f.informationType.toLowerCase();
      return lowerName.contains('key') ||
          lowerType.contains('key') ||
          lowerName.contains('credential') ||
          lowerType.contains('credential') ||
          lowerName.contains('token') ||
          lowerType.contains('token') ||
          lowerName.contains('password') ||
          lowerType.contains('password') ||
          lowerName.contains('secret') ||
          lowerType.contains('secret') ||
          lowerName.contains('terminal') ||
          lowerType.contains('terminal') ||
          (f.baseSensitivity >= 70 &&
              f.evidenceText != null &&
              f.evidenceText!.isNotEmpty);
    });

    if (digitalFindings.isNotEmpty) {
      final primaryDigital = digitalFindings.first;
      inferences.add(
        InferredInsight(
          id: 'inf_digital_${DateTime.now().microsecondsSinceEpoch}',
          category: ExposureCategory.digital,
          directObservation:
              'Visible developer workstation screen or plaintext credential token (${primaryDigital.name}).',
          inferredInsight: 'Exposes cloud infrastructure tenancy, internal network topography, and authentication tokens.',
          attackerThreatProfile: 'Automated credential scraping bots can immediately compromise IAM accounts, extract database snapshots, and pivot across internal networks.',
          severity: RiskLevel.critical,
          confidence: 0.96,
          supportingEvidenceIds: digitalFindings.map((d) => d.id).toList(),
          epistemicLevel: EpistemicLevel.corroboratedDeduction,
          uncertaintyAssessment: 'High certainty: token formatting or shell environment matches standard provider conventions.',
        ),
      );
    }

    // Rule 4: Street Placard + House Number (Residential Domicile Geolocation)
    final streetFindings = findByType('street');
    final houseFindings = findByType('house');
    if (streetFindings.isNotEmpty || houseFindings.isNotEmpty) {
      final supporting = [
        ...streetFindings.map((s) => s.id),
        ...houseFindings.map((h) => h.id),
      ];

      inferences.add(
        InferredInsight(
          id: 'inf_location_${DateTime.now().microsecondsSinceEpoch}',
          category: ExposureCategory.location,
          directObservation:
              'Visible street signage and architectural address placard.',
          inferredInsight: 'Pinpoints exact residential domicile coordinates and neighborhood transit vectors.',
          attackerThreatProfile: 'Doxxing of personal residence, physical swatting harassment, and in-person stalking.',
          severity: RiskLevel.high,
          confidence: 0.88,
          supportingEvidenceIds: supporting.isNotEmpty
              ? supporting
              : findings.map((f) => f.id).toList(),
          epistemicLevel: EpistemicLevel.contextualProbability,
          uncertaintyAssessment: 'Exact street intersection requires cross-referencing municipal parcel maps with building elevation.',
        ),
      );
    }

    // Rule 5: Vehicle Registration Plate Exposure
    final plateFindings = findByType('plate').toList();
    if (plateFindings.isNotEmpty) {
      final plate = plateFindings.first;
      inferences.add(
        InferredInsight(
          id: 'inf_transit_${DateTime.now().microsecondsSinceEpoch}',
          category: ExposureCategory.transportation,
          directObservation:
              'Visible vehicle registration plate (${plate.evidenceText ?? plate.name}).',
          inferredInsight: 'Vehicle identifier permits DMV owner record indexing, automated license plate reader (ALPR) tracking, and physical transit monitoring.',
          attackerThreatProfile: 'Correlating vehicle presence across public cameras to map daily commute patterns and parked vehicle vulnerability.',
          severity: RiskLevel.moderate,
          confidence: 0.92,
          supportingEvidenceIds: [plate.id],
          epistemicLevel: EpistemicLevel.corroboratedDeduction,
          uncertaintyAssessment: 'State/regional jurisdiction verified; registrant identity requires external DMV database authorization.',
        ),
      );
    }

    return inferences;
  }
}
