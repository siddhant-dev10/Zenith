import 'dart:convert';
import 'dart:io';

import 'test_case_models.dart';

/// Persistent JSON file repository for Zenith backend test cases.
class ZenithTestCaseRepository {
  final File _file;

  ZenithTestCaseRepository({String filePath = 'data/test_cases.json'})
    : _file = File(filePath);

  Future<void> _ensureFile() async {
    if (!await _file.exists()) {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode([]), flush: true);
    }
  }

  Future<List<ZenithTestCaseRecord>> getAll() async {
    await _ensureFile();
    try {
      final raw = await _file.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => ZenithTestCaseRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ZenithTestCaseRecord?> getById(String id) async {
    final all = await getAll();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<ZenithTestCaseRecord> save(ZenithTestCaseRecord record) async {
    final all = await getAll();
    final index = all.indexWhere((e) => e.id == record.id);
    if (index >= 0) {
      all[index] = record;
    } else {
      all.add(record);
    }
    await _persist(all);
    return record;
  }

  Future<ZenithTestCaseRecord?> patch(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final record = await getById(id);
    if (record == null) return null;

    final updated = record.copyWith(
      name: updates['name'] as String?,
      description: updates['description'] as String?,
      category: updates['category'] as String?,
      inputFixtureReference: updates['inputFixtureReference'] as String?,
      expectedSeverity: updates['expectedSeverity'] as String?,
      minExpectedScore: (updates['minExpectedScore'] as num?)?.toInt(),
      maxExpectedScore: (updates['maxExpectedScore'] as num?)?.toInt(),
      evaluationCriteria: updates['evaluationCriteria'] as String?,
      version: record.version + 1,
      isEnabled: updates['isEnabled'] as bool?,
      updatedAt: DateTime.now(),
    );

    return save(updated);
  }

  Future<bool> delete(String id) async {
    final all = await getAll();
    final initialLen = all.length;
    all.removeWhere((e) => e.id == id);
    if (all.length != initialLen) {
      await _persist(all);
      return true;
    }
    return false;
  }

  Future<void> _persist(List<ZenithTestCaseRecord> list) async {
    await _ensureFile();
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await _file.writeAsString(jsonStr, flush: true);
  }
}

/// Persistent JSON file repository for Zenith test evaluation runs.
class ZenithTestRunRepository {
  final File _file;

  ZenithTestRunRepository({String filePath = 'data/test_runs.json'})
    : _file = File(filePath);

  Future<void> _ensureFile() async {
    if (!await _file.exists()) {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode([]), flush: true);
    }
  }

  Future<List<ZenithTestRunRecord>> getAllRuns() async {
    await _ensureFile();
    try {
      final raw = await _file.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => ZenithTestRunRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ZenithTestRunRecord?> getRunById(String id) async {
    final all = await getAllRuns();
    for (final run in all) {
      if (run.runId == id) return run;
    }
    return null;
  }

  Future<ZenithTestRunRecord> saveRun(ZenithTestRunRecord run) async {
    final all = await getAllRuns();
    all.insert(0, run); // latest first
    await _ensureFile();
    final jsonStr = jsonEncode(all.map((e) => e.toJson()).toList());
    await _file.writeAsString(jsonStr, flush: true);
    return run;
  }
}

/// Idempotent seeder that populates the 20 required threat benchmark test cases.
class ZenithTestCaseSeeder {
  final ZenithTestCaseRepository repository;

  ZenithTestCaseSeeder(this.repository);

  /// Seeds the 20 standard threat categories idempotently.
  Future<int> seedInitialCases() async {
    final existing = await repository.getAll();
    final existingIds = existing.map((e) => e.id).toSet();
    int addedCount = 0;

    final standardDefinitions = _buildStandard20Cases();
    for (final testCase in standardDefinitions) {
      if (!existingIds.contains(testCase.id)) {
        await repository.save(testCase);
        addedCount++;
      }
    }
    return addedCount;
  }

  static List<ZenithTestCaseRecord> _buildStandard20Cases() {
    final now = DateTime.now();

    return [
      // 1. Clean photographs
      ZenithTestCaseRecord(
        id: 'TC-01-CLEAN',
        name: 'Clean Alpine Mountain Landscape',
        description:
            'Nature scenery with zero human PII, faces, or credentials.',
        category: 'clean_photographs',
        inputFixtureReference: 'assets/samples/sample_clean_landscape.png',
        expectedDetections: [],
        expectedSeverity: 'low',
        minExpectedScore: 0,
        maxExpectedScore: 25,
        expectedRecommendations: ['No privacy redaction required.'],
        groundTruthAnnotations: [],
        evaluationCriteria: 'score_within_range',
        createdAt: now,
        updatedAt: now,
      ),

      // 2. Faces and identity exposure
      ZenithTestCaseRecord(
        id: 'TC-02-FACES',
        name: 'Portrait of Individual in Public Setting',
        description: 'High-resolution facial portrait exposed without consent.',
        category: 'faces_and_identity',
        inputFixtureReference: 'fixtures/identity_portrait.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'identity',
            type: 'human_face',
            minConfidence: 0.85,
          ),
        ],
        expectedSeverity: 'moderate',
        minExpectedScore: 26,
        maxExpectedScore: 65,
        expectedRecommendations: [
          'Blur or mask facial biometrics before sharing.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Identifiable Face',
            category: 'identity',
            boundingBox: [0.15, 0.30, 0.45, 0.70],
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 3. Student identification cards
      ZenithTestCaseRecord(
        id: 'TC-03-STUDENT-ID',
        name: 'University Student Identification Card',
        description: 'Physical campus ID badge showing full name, student ID number, and barcode.',
        category: 'student_ids',
        inputFixtureReference: 'assets/samples/sample_student_id.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'identity',
            type: 'student_id_card',
            minConfidence: 0.90,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 51,
        maxExpectedScore: 90,
        expectedRecommendations: [
          'Solid black redaction over student ID and photo.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Student Card',
            category: 'identity',
            boundingBox: [0.20, 0.20, 0.80, 0.80],
            sensitiveText: 'STU-9948201',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 4. Employee badges
      ZenithTestCaseRecord(
        id: 'TC-04-EMPLOYEE-BADGE',
        name: 'Corporate Access Badge on Lanyard',
        description: 'Corporate access badge displaying company logo, clearance tier, and RFID chip.',
        category: 'employee_badges',
        inputFixtureReference: 'fixtures/corporate_badge.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'identity',
            type: 'employee_badge',
            minConfidence: 0.85,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 51,
        maxExpectedScore: 85,
        expectedRecommendations: [
          'Redact organizational logos and employee badges.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Corporate Lanyard Badge',
            category: 'identity',
            boundingBox: [0.35, 0.40, 0.75, 0.65],
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 5. Government identification documents
      ZenithTestCaseRecord(
        id: 'TC-05-GOV-ID',
        name: 'Government Passport Bio Page',
        description: 'Official national passport display with MRZ machine-readable zone, DOB, and passport number.',
        category: 'government_documents',
        inputFixtureReference: 'fixtures/passport_mrz.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'identity',
            type: 'government_passport',
            minConfidence: 0.95,
          ),
        ],
        expectedSeverity: 'critical',
        minExpectedScore: 76,
        maxExpectedScore: 100,
        expectedRecommendations: [
          'DO NOT SHARE: Never post government identification documents online.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Passport Bio Page',
            category: 'identity',
            boundingBox: [0.10, 0.10, 0.90, 0.90],
            sensitiveText: 'P<USA987654321',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 6. Vehicle registration plates
      ZenithTestCaseRecord(
        id: 'TC-06-LICENSE-PLATE',
        name: 'Vehicle Registration License Plate',
        description: 'Public street vehicle displaying municipal registration numbers on bumper plate.',
        category: 'vehicle_plates',
        inputFixtureReference: 'fixtures/license_plate.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'location',
            type: 'vehicle_license_plate',
            minConfidence: 0.85,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 40,
        maxExpectedScore: 75,
        expectedRecommendations: [
          'Mask vehicle license plates before posting.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'License Plate',
            category: 'location',
            boundingBox: [0.55, 0.40, 0.65, 0.60],
            sensitiveText: '7XYZ890',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 7. Addresses and location clues
      ZenithTestCaseRecord(
        id: 'TC-07-ADDRESS-PLACARD',
        name: 'Residential Front Door House Placard',
        description:
            'Front porch showing distinct house number and street plaque.',
        category: 'addresses_and_locations',
        inputFixtureReference: 'assets/samples/sample_street_house.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'location',
            type: 'residential_address_sign',
            minConfidence: 0.85,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 51,
        maxExpectedScore: 80,
        expectedRecommendations: [
          'Mask house numbers and street name plaques.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'House Number Placard',
            category: 'location',
            boundingBox: [0.25, 0.35, 0.40, 0.50],
            sensitiveText: '742 Evergreen',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 8. Phone numbers and email addresses
      ZenithTestCaseRecord(
        id: 'TC-08-CONTACT-INFO',
        name: 'Business Card with Direct Contact Info',
        description: 'Direct personal mobile number and private email address on business card.',
        category: 'contact_information',
        inputFixtureReference: 'fixtures/business_card_contact.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'personal_info',
            type: 'contact_details',
            minConfidence: 0.85,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 50,
        maxExpectedScore: 80,
        expectedRecommendations: [
          'Redact direct mobile phone numbers and email addresses.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Phone and Email Block',
            category: 'personal_info',
            boundingBox: [0.45, 0.20, 0.70, 0.80],
            sensitiveText: '+1-555-0199',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 9. QR codes and barcodes
      ZenithTestCaseRecord(
        id: 'TC-09-QR-BARCODE',
        name: 'Wi-Fi Network Access QR Code',
        description: 'Wall placard showing 2D QR matrix encoding cleartext Wi-Fi network SSID and WPA2 key.',
        category: 'qr_and_barcodes',
        inputFixtureReference: 'fixtures/wifi_qr_code.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'digital_security',
            type: 'wifi_access_qr',
            minConfidence: 0.90,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 55,
        maxExpectedScore: 85,
        expectedRecommendations: [
          'Scramble or obscure QR codes encoding network credentials.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Wi-Fi QR Code',
            category: 'digital_security',
            boundingBox: [0.30, 0.30, 0.70, 0.70],
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 10. Sensitive computer screens
      ZenithTestCaseRecord(
        id: 'TC-10-TERMINAL-SCREEN',
        name: 'Engineer Terminal Display with Cloud Token',
        description: 'High-res photograph of developer monitor showing bash shell history and AWS access key.',
        category: 'computer_screens',
        inputFixtureReference: 'assets/samples/sample_workstation_screen.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'digital_security',
            type: 'screen_terminal_credential',
            minConfidence: 0.90,
          ),
        ],
        expectedSeverity: 'critical',
        minExpectedScore: 80,
        maxExpectedScore: 100,
        expectedRecommendations: [
          'Revoke active tokens immediately and redact screen contents.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Terminal Shell Window',
            category: 'digital_security',
            boundingBox: [0.15, 0.15, 0.75, 0.85],
            sensitiveText: 'AKIAIOSFODNN7EXAMPLE',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 11. Financial documents
      ZenithTestCaseRecord(
        id: 'TC-11-BANK-STATEMENT',
        name: 'Bank Account Statement with Routing Info',
        description: 'Paper bank statement on desk showing account balance, bank routing number, and account number.',
        category: 'financial_documents',
        inputFixtureReference: 'fixtures/bank_statement.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'personal_info',
            type: 'bank_statement',
            minConfidence: 0.90,
          ),
        ],
        expectedSeverity: 'critical',
        minExpectedScore: 76,
        maxExpectedScore: 100,
        expectedRecommendations: [
          'Do not share banking information or account numbers online.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Bank Account Number',
            category: 'personal_info',
            boundingBox: [0.35, 0.20, 0.55, 0.80],
            sensitiveText: 'Routing: 122000496',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 12. Travel documents and boarding passes
      ZenithTestCaseRecord(
        id: 'TC-12-BOARDING-PASS',
        name: 'Commercial Airline Boarding Pass',
        description: 'Airport gate photo displaying passenger name, flight number, 6-character PNR record locator, and barcode.',
        category: 'travel_documents',
        inputFixtureReference: 'assets/samples/sample_boarding_pass.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'personal_info',
            type: 'airline_boarding_pass',
            minConfidence: 0.90,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 60,
        maxExpectedScore: 85,
        expectedRecommendations: [
          'Redact PNR record locators and PDF417 boarding barcodes.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Boarding Pass Stub',
            category: 'personal_info',
            boundingBox: [0.25, 0.20, 0.75, 0.80],
            sensitiveText: 'PNR: AB789X',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 13. Exposed credentials
      ZenithTestCaseRecord(
        id: 'TC-13-STICKY-PASSWORD',
        name: 'Monitor Sticky Note with Cleartext Password',
        description: 'Post-it adhesive note affixed to monitor bezel with written VPN password.',
        category: 'exposed_credentials',
        inputFixtureReference: 'fixtures/sticky_password.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'digital_security',
            type: 'plaintext_password_note',
            minConfidence: 0.95,
          ),
        ],
        expectedSeverity: 'critical',
        minExpectedScore: 85,
        maxExpectedScore: 100,
        expectedRecommendations: [
          'Remove sticky note immediately and change credentials.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Sticky Note Credential',
            category: 'digital_security',
            boundingBox: [0.60, 0.70, 0.80, 0.90],
            sensitiveText: 'Pwd: CorrectHorseBattery#9',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 14. Metadata exposure
      ZenithTestCaseRecord(
        id: 'TC-14-EXIF-METADATA',
        name: 'Photograph with Embedded GPS EXIF Metadata',
        description: 'Image whose EXIF tags contain precise GPS coordinates pointing to private residence.',
        category: 'metadata_exposure',
        inputFixtureReference: 'fixtures/exif_gps_image.jpg',
        expectedDetections: [
          const ExpectedDetection(
            category: 'location',
            type: 'exif_gps_coordinates',
            minConfidence: 0.99,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 50,
        maxExpectedScore: 75,
        expectedRecommendations: [
          'Strip EXIF metadata before publishing photograph online.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'EXIF GPS Header',
            category: 'location',
            sensitiveText: '37.7749 N, 122.4194 W',
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 15. Multiple simultaneous exposures
      ZenithTestCaseRecord(
        id: 'TC-15-COMPOUND-SCENE',
        name: 'Compound Scene: Badge + House Number + Vehicle',
        description: 'Selfie taken in driveway showing corporate badge, residential address sign, and parked vehicle.',
        category: 'multiple_exposures',
        inputFixtureReference: 'fixtures/compound_driveway_scene.png',
        expectedDetections: [
          const ExpectedDetection(category: 'identity', type: 'badge'),
          const ExpectedDetection(category: 'location', type: 'address'),
        ],
        expectedSeverity: 'critical',
        minExpectedScore: 65,
        maxExpectedScore: 100,
        expectedRecommendations: [
          'Apply multi-point redaction across badge and address markers.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(label: 'Badge', category: 'identity'),
          const GroundTruthAnnotation(label: 'House No', category: 'location'),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 16. Blurred or partially obstructed information
      ZenithTestCaseRecord(
        id: 'TC-16-BLURRED-DATA',
        name: 'Partially Blurred Credit Card Number',
        description: 'Payment card with Gaussian blur where first 12 digits remain partially decipherable.',
        category: 'blurred_information',
        inputFixtureReference: 'fixtures/partially_blurred_card.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'personal_info',
            type: 'partially_blurred_pan',
            minConfidence: 0.70,
          ),
        ],
        expectedSeverity: 'high',
        minExpectedScore: 50,
        maxExpectedScore: 80,
        expectedRecommendations: [
          'Use opaque solid block redaction rather than reversible blur.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Weakly Blurred PAN',
            category: 'personal_info',
            boundingBox: [0.40, 0.20, 0.60, 0.80],
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 17. Low-quality images
      ZenithTestCaseRecord(
        id: 'TC-17-LOW-QUALITY',
        name: 'Low-Resolution Grainy Street Scene',
        description: 'Heavily compressed, noisy image where small background text is degraded.',
        category: 'low_quality_images',
        inputFixtureReference: 'fixtures/low_quality_grain.jpg',
        expectedDetections: [],
        expectedSeverity: 'low',
        minExpectedScore: 0,
        maxExpectedScore: 35,
        expectedRecommendations: [
          'No high-confidence privacy exposure identified.',
        ],
        groundTruthAnnotations: [],
        evaluationCriteria: 'score_within_range',
        createdAt: now,
        updatedAt: now,
      ),

      // 18. Ambiguous cases
      ZenithTestCaseRecord(
        id: 'TC-18-AMBIGUOUS-TEXT',
        name: 'Fragmented Partial Digits on Discarded Paper',
        description: 'Torn slip with ambiguous 4-digit sequence (could be year, price, or PIN).',
        category: 'ambiguous_cases',
        inputFixtureReference: 'fixtures/ambiguous_digits.png',
        expectedDetections: [
          const ExpectedDetection(
            category: 'personal_info',
            type: 'ambiguous_numeric_token',
            minConfidence: 0.50,
          ),
        ],
        expectedSeverity: 'moderate',
        minExpectedScore: 20,
        maxExpectedScore: 45,
        expectedRecommendations: [
          'Review ambiguous numeric fragments before sharing.',
        ],
        groundTruthAnnotations: [
          const GroundTruthAnnotation(
            label: 'Fragmented Numbers',
            category: 'personal_info',
            boundingBox: [0.45, 0.40, 0.55, 0.60],
          ),
        ],
        evaluationCriteria: 'severity_match',
        createdAt: now,
        updatedAt: now,
      ),

      // 19. False-positive scenarios
      ZenithTestCaseRecord(
        id: 'TC-19-FALSE-POSITIVE',
        name: 'Movie Poster with Fictional Actor Identification',
        description: 'Theatrical cinema poster displaying fictional character name and barcode graphic.',
        category: 'false_positive_scenarios',
        inputFixtureReference: 'fixtures/movie_poster_prop.png',
        expectedDetections: [],
        expectedSeverity: 'low',
        minExpectedScore: 0,
        maxExpectedScore: 35,
        expectedRecommendations: [
          'Public promotional material; no personal risk detected.',
        ],
        groundTruthAnnotations: [],
        evaluationCriteria: 'score_within_range',
        createdAt: now,
        updatedAt: now,
      ),

      // 20. Analysis failure scenarios
      ZenithTestCaseRecord(
        id: 'TC-20-DEGRADED-DETECTOR',
        name: 'Detector Failure Fallback (Simulated Degraded State)',
        description: 'Pipeline executed with detector fault; system must enforce >= 50 safety floor.',
        category: 'analysis_failure_scenarios',
        inputFixtureReference: 'assets/samples/sample_student_id.png',
        expectedDetections: [],
        expectedSeverity: 'moderate',
        minExpectedScore: 50,
        maxExpectedScore: 65,
        expectedRecommendations: [
          'Manual review required: AI vision detectors encountered a fault.',
        ],
        groundTruthAnnotations: [],
        evaluationCriteria: 'score_within_range',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
