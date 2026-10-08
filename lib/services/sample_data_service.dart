import '../models/detected_element.dart';
import '../models/exposure_category.dart';
import '../models/inferred_insight.dart';
import '../models/privacy_audit_report.dart';
import '../models/recommendation.dart';
import '../models/risk_level.dart';

class SampleScenario {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final int expectedRiskScore;
  final RiskLevel riskLevel;
  final String tag;
  final PrivacyAuditReport report;

  const SampleScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.expectedRiskScore,
    required this.riskLevel,
    required this.tag,
    required this.report,
  });
}

class SampleDataService {
  static List<SampleScenario> getScenarios() {
    return [
      _studentIdScenario,
      _boardingPassScenario,
      _workstationScenario,
      _streetHouseScenario,
      _cleanLandscapeScenario,
    ];
  }

  static SampleScenario? getById(String id) {
    try {
      return getScenarios().firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static final SampleScenario _studentIdScenario = SampleScenario(
    id: 'sample_student_id',
    title: 'Student ID Card & Campus Badge',
    subtitle: 'High-risk institutional credential with barcode & photo',
    assetPath: 'assets/samples/sample_student_id.png',
    expectedRiskScore: 88,
    riskLevel: RiskLevel.critical,
    tag: 'Identity Leak',
    report: PrivacyAuditReport(
      id: 'audit_sample_student_id',
      timestamp: DateTime.now(),
      sampleAsset: 'assets/samples/sample_student_id.png',
      overallScore: 88,
      riskLevel: RiskLevel.critical,
      title: 'Critical Identity & Student PII Breach',
      summary:
          'Image displays an unredacted institutional student ID containing full legal name, student registration number, department, graduation year, student portrait, and high-density 1D barcode.',
      categoryScores: {
        ExposureCategory.identity: 95,
        ExposureCategory.location: 65,
        ExposureCategory.digital: 15,
        ExposureCategory.personalInfo: 90,
        ExposureCategory.transportation: 10,
      },
      detectedElements: [
        DetectedElement(
          id: 'elem_stu_1',
          name: 'Student Identification Card',
          category: ExposureCategory.identity,
          riskLevel: RiskLevel.critical,
          confidence: 0.98,
          description:
              'Official card from "Pacific State University" with active validity period.',
          opsecImpact:
              'Verifies student status and institutional affiliation for bad actors.',
          boundingBox: BoundingBox(left: 0.04, top: 0.06, width: 0.92, height: 0.88),
        ),
        DetectedElement(
          id: 'elem_stu_2',
          name: 'Personal Portrait & Biometric Face',
          category: ExposureCategory.identity,
          riskLevel: RiskLevel.high,
          confidence: 0.96,
          description:
              'Frontal portrait photo suitable for automated reverse-image searches.',
          opsecImpact:
              'Facial recognition matchable across LinkedIn, Instagram, and social graphs.',
          boundingBox: BoundingBox(left: 0.08, top: 0.27, width: 0.23, height: 0.44),
        ),
        DetectedElement(
          id: 'elem_stu_3',
          name: 'Full Legal Name ("Alexander Morgan")',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.high,
          confidence: 0.99,
          description: 'Explicit student name printed clearly in capital letters.',
          opsecImpact:
              'Enables targeted spear phishing, doxxing, and social engineering.',
          boundingBox: BoundingBox(left: 0.33, top: 0.31, width: 0.45, height: 0.09),
        ),
        DetectedElement(
          id: 'elem_stu_4',
          name: 'Student ID Number ("STU-884920-CS")',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.critical,
          confidence: 0.97,
          description: 'Unique university matriculation and student portal ID.',
          opsecImpact:
              'Can be used to reset university portal passwords or impersonate student in registrar/library.',
          boundingBox: BoundingBox(left: 0.33, top: 0.43, width: 0.38, height: 0.09),
        ),
        DetectedElement(
          id: 'elem_stu_5',
          name: 'Machine-Readable Barcode',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.critical,
          confidence: 0.95,
          description: 'Standard Code-39/128 barcode encoding matriculation data.',
          opsecImpact:
              'Can be digitally scanned off screen to clone physical magnetic/barcode campus access badges.',
          boundingBox: BoundingBox(left: 0.07, top: 0.78, width: 0.52, height: 0.12),
        ),
      ],
      inferredInsights: [
        InferredInsight(
          id: 'inf_stu_1',
          category: ExposureCategory.location,
          directObservation: 'Institution Name: Pacific State University',
          inferredInsight:
              'Geographic base in Pacific state area; physical presence on campus between 2024 and 2027.',
          attackerThreatProfile:
              'Attacker can establish physical stalking routines, class schedules, and primary metropolitan area.',
          severity: RiskLevel.high,
          confidence: 0.94,
        ),
        InferredInsight(
          id: 'inf_stu_2',
          category: ExposureCategory.identity,
          directObservation: 'DOB 04/12/2003 & Degree: Computer Science',
          inferredInsight:
              'Student is ~21-23 years old, undergraduate/graduate candidate graduating summer 2027.',
          attackerThreatProfile:
              'Used for security question bypass (birth year, university mascot) and targeted student job scam phishing.',
          severity: RiskLevel.critical,
          confidence: 0.96,
        ),
        InferredInsight(
          id: 'inf_stu_3',
          category: ExposureCategory.digital,
          directObservation: 'Institutional Barcode & Format',
          inferredInsight:
              'Direct access to campus LMS, internal library proxy, and building door turnstiles.',
          attackerThreatProfile:
              'Credential cloner can reconstruct barcode image and gain unauthorized physical entrance.',
          severity: RiskLevel.critical,
          confidence: 0.92,
        ),
      ],
      recommendations: [
        Recommendation(
          id: 'rec_stu_1',
          priority: RiskLevel.critical,
          title: 'Redact Barcode & Student ID Number Immediately',
          action:
              'Never share images with scannable barcodes or institutional identifiers on Instagram, TikTok, or LinkedIn.',
          type: 'blur',
        ),
        Recommendation(
          id: 'rec_stu_2',
          priority: RiskLevel.high,
          title: 'Blur or Crop Facial Portrait',
          action:
              'Crop the badge out entirely if showing graduation celebrations; keep personal identification private.',
          type: 'crop',
        ),
        Recommendation(
          id: 'rec_stu_3',
          priority: RiskLevel.critical,
          title: 'Do Not Post Online in Public Feeds',
          action:
              'University IDs are classified as Tier-1 sensitive personal credentials. Sharing compromises campus OPSEC.',
          type: 'do_not_share',
        ),
      ],
      scanDurationMs: 1140,
    ),
  );

  static final SampleScenario _boardingPassScenario = SampleScenario(
    id: 'sample_boarding_pass',
    title: 'Airline Boarding Pass & Travel PNR',
    subtitle: 'PNR booking code, e-ticket #, and unencrypted BCBP barcode',
    assetPath: 'assets/samples/sample_boarding_pass.png',
    expectedRiskScore: 92,
    riskLevel: RiskLevel.critical,
    tag: 'Transit & Travel',
    report: PrivacyAuditReport(
      id: 'audit_sample_boarding_pass',
      timestamp: DateTime.now(),
      sampleAsset: 'assets/samples/sample_boarding_pass.png',
      overallScore: 92,
      riskLevel: RiskLevel.critical,
      title: 'Critical Travel PNR & Passenger Security Breach',
      summary:
          'Image contains complete airline reservation record (PNR), passenger legal name, flight number, seat, frequent flyer tier, and scannable 2D barcode containing unencrypted passenger record.',
      categoryScores: {
        ExposureCategory.identity: 75,
        ExposureCategory.location: 85,
        ExposureCategory.digital: 30,
        ExposureCategory.personalInfo: 95,
        ExposureCategory.transportation: 98,
      },
      detectedElements: [
        DetectedElement(
          id: 'elem_bp_1',
          name: 'Passenger Name Record (PNR: "Q89KL2")',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.critical,
          confidence: 0.99,
          description: '6-character airline booking locator code.',
          opsecImpact:
              'Allows anyone on the airline website to view full passport details, phone number, seat change, or cancel the flight.',
          boundingBox: BoundingBox(left: 0.35, top: 0.15, width: 0.40, height: 0.08),
        ),
        DetectedElement(
          id: 'elem_bp_2',
          name: '2D Aztec / PDF417 Barcode',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.critical,
          confidence: 0.98,
          description: 'IATA standard Bar Coded Boarding Pass (BCBP).',
          opsecImpact:
              'Freely readable by any smartphone camera. Contains PNR, ticket number, and frequent flyer account.',
          boundingBox: BoundingBox(left: 0.72, top: 0.27, width: 0.21, height: 0.34),
        ),
        DetectedElement(
          id: 'elem_bp_3',
          name: 'Frequent Flyer Number & Status',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.high,
          confidence: 0.95,
          description: 'Platinum loyalty number linked to passenger identity.',
          opsecImpact:
              'Can be used for airline account takeover or identity triangulation.',
          boundingBox: BoundingBox(left: 0.07, top: 0.56, width: 0.36, height: 0.10),
        ),
        DetectedElement(
          id: 'elem_bp_4',
          name: 'Flight Route ("SFO → LHR")',
          category: ExposureCategory.location,
          riskLevel: RiskLevel.high,
          confidence: 0.97,
          description: 'San Francisco to London Heathrow scheduled transit.',
          opsecImpact:
              'Broadcasts real-time absence from home residence, creating burglary risk.',
          boundingBox: BoundingBox(left: 0.07, top: 0.27, width: 0.38, height: 0.12),
        ),
      ],
      inferredInsights: [
        InferredInsight(
          id: 'inf_bp_1',
          category: ExposureCategory.location,
          directObservation: 'Flight SFO to LHR on specific date',
          inferredInsight:
              'Traveler will be out of country for 1-3 weeks; home in San Francisco will be vacant.',
          attackerThreatProfile:
              'Home robbery planning, physical surveillance, and target absence exploitation.',
          severity: RiskLevel.critical,
          confidence: 0.95,
        ),
        InferredInsight(
          id: 'inf_bp_2',
          category: ExposureCategory.personalInfo,
          directObservation: 'PNR + Last Name combination',
          inferredInsight:
              'Instant access to airline "Manage Booking" portal containing passport #, email, and billing address.',
          attackerThreatProfile:
              'Identity theft, travel hijacking, unauthorized cancellation, or passport data extraction.',
          severity: RiskLevel.critical,
          confidence: 0.99,
        ),
      ],
      recommendations: [
        Recommendation(
          id: 'rec_bp_1',
          priority: RiskLevel.critical,
          title: 'NEVER Post Photos of Boarding Passes',
          action:
              'Even if you blur your name, the 2D Aztec barcode stores your complete unencrypted PNR and passport data.',
          type: 'do_not_share',
        ),
        Recommendation(
          id: 'rec_bp_2',
          priority: RiskLevel.high,
          title: 'Delay Travel Posts Until Return',
          action:
              'Announcing current flights informs adversaries that your residence is unoccupied.',
          type: 'do_not_share',
        ),
      ],
      scanDurationMs: 1210,
    ),
  );

  static final SampleScenario _workstationScenario = SampleScenario(
    id: 'sample_workstation_screen',
    title: 'Developer Desk & Secrets Leak',
    subtitle: 'Terminal with AWS keys, DB credentials, and office Wi-Fi note',
    assetPath: 'assets/samples/sample_workstation_screen.png',
    expectedRiskScore: 96,
    riskLevel: RiskLevel.critical,
    tag: 'Digital & Credentials',
    report: PrivacyAuditReport(
      id: 'audit_sample_workstation_screen',
      timestamp: DateTime.now(),
      sampleAsset: 'assets/samples/sample_workstation_screen.png',
      overallScore: 96,
      riskLevel: RiskLevel.critical,
      title: 'Catastrophic Cloud & Infrastructure Credential Exposure',
      summary:
          'Monitor terminal clearly displays AWS Access Keys, secret keys, internal PostgreSQL connection strings with cleartext passwords, corporate Slack messages, and a physical sticky note with office Wi-Fi & alarm PIN.',
      categoryScores: {
        ExposureCategory.identity: 35,
        ExposureCategory.location: 60,
        ExposureCategory.digital: 99,
        ExposureCategory.personalInfo: 85,
        ExposureCategory.transportation: 0,
      },
      detectedElements: [
        DetectedElement(
          id: 'elem_ws_1',
          name: 'AWS Access Key & Secret Key',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.critical,
          confidence: 0.99,
          description: 'Active cloud provider IAM credentials in environment export.',
          opsecImpact:
              'Full compromise of AWS infrastructure, cloud data exfiltration, or cryptomining extortion.',
          boundingBox: BoundingBox(left: 0.06, top: 0.27, width: 0.65, height: 0.16),
        ),
        DetectedElement(
          id: 'elem_ws_2',
          name: 'PostgreSQL Database URI with Password',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.critical,
          confidence: 0.98,
          description: 'Production database endpoint containing admin credentials.',
          opsecImpact:
              'Direct remote database takeover and complete customer data leak.',
          boundingBox: BoundingBox(left: 0.06, top: 0.44, width: 0.65, height: 0.08),
        ),
        DetectedElement(
          id: 'elem_ws_3',
          name: 'Sticky Note with Wi-Fi & Alarm PIN',
          category: ExposureCategory.personalInfo,
          riskLevel: RiskLevel.critical,
          confidence: 0.97,
          description: 'Physical post-it note on monitor bezel with SSID, password, and alarm code.',
          opsecImpact:
              'Physical facility breach, parking lot Wi-Fi sniffing, and alarm system bypass.',
          boundingBox: BoundingBox(left: 0.72, top: 0.61, width: 0.20, height: 0.23),
        ),
        DetectedElement(
          id: 'elem_ws_4',
          name: 'Internal Slack Notification & IP Addresses',
          category: ExposureCategory.digital,
          riskLevel: RiskLevel.high,
          confidence: 0.94,
          description: 'Internal VPN subnet 192.168.1.x and deployment messages.',
          opsecImpact:
              'Reveals internal network topology and project codenames for targeted intrusions.',
          boundingBox: BoundingBox(left: 0.06, top: 0.56, width: 0.65, height: 0.12),
        ),
      ],
      inferredInsights: [
        InferredInsight(
          id: 'inf_ws_1',
          category: ExposureCategory.digital,
          directObservation: 'AWS Credentials & DB URI',
          inferredInsight:
              'Developer possesses production admin access; company operates on AWS us-east-1 and PostgreSQL.',
          attackerThreatProfile:
              'Automated credential scraping bots can drain cloud infrastructure within 90 seconds of posting.',
          severity: RiskLevel.critical,
          confidence: 0.99,
        ),
        InferredInsight(
          id: 'inf_ws_2',
          category: ExposureCategory.location,
          directObservation: 'Office Wi-Fi SSID "ApexGuest_5G" & Alarm 8092',
          inferredInsight:
              'Physical office location of Apex Corp; alarm code for facility entry.',
          attackerThreatProfile:
              'Social engineering against night security or unauthorized after-hours building entry.',
          severity: RiskLevel.critical,
          confidence: 0.96,
        ),
      ],
      recommendations: [
        Recommendation(
          id: 'rec_ws_1',
          priority: RiskLevel.critical,
          title: 'Immediately Revoke & Rotate AWS & DB Keys',
          action:
              'These credentials must be treated as permanently compromised immediately.',
          type: 'rotate',
        ),
        Recommendation(
          id: 'rec_ws_2',
          priority: RiskLevel.critical,
          title: 'Remove Sticky Notes from Workspace',
          action:
              'Never write down Wi-Fi passwords, facility alarm PINs, or OTP recovery keys on paper near camera lines of sight.',
          type: 'general',
        ),
        Recommendation(
          id: 'rec_ws_3',
          priority: RiskLevel.critical,
          title: 'Lock Terminal & Blur Background in Desk Selfies',
          action:
              'Casual desk photos ("desk setup" posts) frequently leak sensitive browser tabs and terminal history.',
          type: 'blur',
        ),
      ],
      scanDurationMs: 1320,
    ),
  );

  static final SampleScenario _streetHouseScenario = SampleScenario(
    id: 'sample_street_house',
    title: 'Suburban House & Vehicle Plate',
    subtitle: 'Street sign, house number, and visible car registration',
    assetPath: 'assets/samples/sample_street_house.png',
    expectedRiskScore: 72,
    riskLevel: RiskLevel.high,
    tag: 'Location Exposure',
    report: PrivacyAuditReport(
      id: 'audit_sample_street_house',
      timestamp: DateTime.now(),
      sampleAsset: 'assets/samples/sample_street_house.png',
      overallScore: 72,
      riskLevel: RiskLevel.high,
      title: 'High Physical Location & Vehicle Tracking Exposure',
      summary:
          'Image combines an exact house street number ("742"), readable street name sign ("Evergreen Ter"), state vehicle license plate ("7XYZ890"), and distinct architectural layout enabling precise address geocoding.',
      categoryScores: {
        ExposureCategory.identity: 30,
        ExposureCategory.location: 92,
        ExposureCategory.digital: 0,
        ExposureCategory.personalInfo: 45,
        ExposureCategory.transportation: 78,
      },
      detectedElements: [
        DetectedElement(
          id: 'elem_st_1',
          name: 'Street Sign ("EVERGREEN TER")',
          category: ExposureCategory.location,
          riskLevel: RiskLevel.critical,
          confidence: 0.97,
          description: 'Public municipal street sign in green reflective standard format.',
          opsecImpact:
              'Reduces geographic search radius to a specific town and road.',
          boundingBox: BoundingBox(left: 0.06, top: 0.34, width: 0.19, height: 0.08),
        ),
        DetectedElement(
          id: 'elem_st_2',
          name: 'House Number ("742")',
          category: ExposureCategory.location,
          riskLevel: RiskLevel.critical,
          confidence: 0.95,
          description: 'Clear residential building address digits next to front entrance.',
          opsecImpact:
              'Combined with street sign, pinpoints the user’s exact front door in Google Maps.',
          boundingBox: BoundingBox(left: 0.48, top: 0.40, width: 0.04, height: 0.04),
        ),
        DetectedElement(
          id: 'elem_st_3',
          name: 'Vehicle License Plate ("7XYZ890 / California")',
          category: ExposureCategory.transportation,
          riskLevel: RiskLevel.high,
          confidence: 0.96,
          description: 'Automobile registration plate in private driveway.',
          opsecImpact:
              'DMV record databases or private investigator tools can link plate to registered owner name.',
          boundingBox: BoundingBox(left: 0.63, top: 0.78, width: 0.09, height: 0.06),
        ),
      ],
      inferredInsights: [
        InferredInsight(
          id: 'inf_st_1',
          category: ExposureCategory.location,
          directObservation: '742 Evergreen Ter + California Plate',
          inferredInsight:
              'Exact residential domicile coordinates in California; owner resides at this exact property.',
          attackerThreatProfile:
              'Physical stalking, unsolicited deliveries, doxxing, and SWATing harassment.',
          severity: RiskLevel.critical,
          confidence: 0.98,
        ),
        InferredInsight(
          id: 'inf_st_2',
          category: ExposureCategory.transportation,
          directObservation: 'Blue sedan parked in primary driveway',
          inferredInsight:
              'Vehicle model and registration tied to the homeowner or household resident.',
          attackerThreatProfile:
              'Vehicle tracking, daily commuting pattern correlation, and insurance lookup.',
          severity: RiskLevel.high,
          confidence: 0.91,
        ),
      ],
      recommendations: [
        Recommendation(
          id: 'rec_st_1',
          priority: RiskLevel.critical,
          title: 'Blur Street Sign and House Numbers',
          action:
              'Apply privacy blur over street signs and building numbers before posting neighborhood photos.',
          type: 'blur',
        ),
        Recommendation(
          id: 'rec_st_2',
          priority: RiskLevel.high,
          title: 'Obscure Vehicle License Plates',
          action:
              'Black out license plates of any cars parked in personal driveways or regular commuting spots.',
          type: 'blur',
        ),
        Recommendation(
          id: 'rec_st_3',
          priority: RiskLevel.high,
          title: 'Scrub EXIF GPS Metadata',
          action:
              'Smartphone photos embed exact latitude and longitude in file headers. Zenith automatically warns you.',
          type: 'scrub_exif',
        ),
      ],
      scanDurationMs: 1100,
    ),
  );

  static final SampleScenario _cleanLandscapeScenario = SampleScenario(
    id: 'sample_clean_landscape',
    title: 'Mountain Lake Landscape (Clean OPSEC)',
    subtitle: 'Wilderness scenery with zero identifiable PII or markers',
    assetPath: 'assets/samples/sample_clean_landscape.png',
    expectedRiskScore: 8,
    riskLevel: RiskLevel.low,
    tag: 'Safe Baseline',
    report: PrivacyAuditReport(
      id: 'audit_sample_clean_landscape',
      timestamp: DateTime.now(),
      sampleAsset: 'assets/samples/sample_clean_landscape.png',
      overallScore: 8,
      riskLevel: RiskLevel.low,
      title: 'Optimal OPSEC: Safe for Public Sharing',
      summary:
          'No personal identifiable information (PII), human faces, credentials, license plates, barcodes, or sensitive location signages were detected. Safe for public social media distribution.',
      categoryScores: {
        ExposureCategory.identity: 0,
        ExposureCategory.location: 12,
        ExposureCategory.digital: 0,
        ExposureCategory.personalInfo: 0,
        ExposureCategory.transportation: 0,
      },
      detectedElements: [
        DetectedElement(
          id: 'elem_cl_1',
          name: 'Natural Landscape / Alpine Ridge',
          category: ExposureCategory.location,
          riskLevel: RiskLevel.low,
          confidence: 0.92,
          description: 'Generic mountain topography without unique signage or landmarks.',
          opsecImpact:
              'Extremely low risk unless paired with high-precision EXIF GPS metadata.',
        ),
      ],
      inferredInsights: [
        InferredInsight(
          id: 'inf_cl_1',
          category: ExposureCategory.location,
          directObservation: 'Mountain range and pine trees',
          inferredInsight:
              'Subject is likely outdoors in a temperate mountainous region.',
          attackerThreatProfile:
              'Insufficient distinctiveness to isolate specific GPS coordinates without EXIF headers.',
          severity: RiskLevel.low,
          confidence: 0.70,
        ),
      ],
      recommendations: [
        Recommendation(
          id: 'rec_cl_1',
          priority: RiskLevel.low,
          title: 'Ensure EXIF Location Tagging is Disabled',
          action:
              'The visual image is safe. Just ensure your camera app does not attach GPS coordinates when uploading to forums.',
          type: 'scrub_exif',
        ),
        Recommendation(
          id: 'rec_cl_2',
          priority: RiskLevel.low,
          title: 'Approved for Social Distribution',
          action:
              'Zenith OPSEC verified: this photo presents negligible privacy exposure.',
          type: 'general',
        ),
      ],
      scanDurationMs: 890,
    ),
  );
}
