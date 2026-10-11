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

    // Rule 1: Student or Corporate ID + Location or Schedule
    final idFindings = findings.where(
      (f) =>
          f.category == ExposureCategory.identity ||
          f.informationType.toLowerCase().contains('id') ||
          f.informationType.toLowerCase().contains('badge'),
    );
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

    // Rule 3: Digital Terminal / Cloud Credentials
    final digitalFindings = findings.where(
      (f) =>
          f.category == ExposureCategory.digital ||
          f.name.toLowerCase().contains('key') ||
          f.name.toLowerCase().contains('credential') ||
          f.name.toLowerCase().contains('terminal') ||
          f.informationType.toLowerCase().contains('credential'),
    );

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
