import os
import json
from PIL import Image, ImageDraw

os.makedirs('fixtures', exist_ok=True)
os.makedirs('assets/samples', exist_ok=True)

def make_img(w, h, color):
    return Image.new('RGB', (w, h), color=color)

def save(img, path):
    img.save(path)
    assert os.path.exists(path) and os.path.getsize(path) > 0

print("Generating 120 test cases & fixtures for Project Zenith...")

cases = []

# Helper generator for document/badge/card images
def make_card_img(path, bg_color, header_text, body_lines, accent_color=(30, 80, 180)):
    img = make_img(640, 480, (240, 242, 245))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([40, 40, 600, 440], radius=16, fill=bg_color, outline=(180, 190, 205), width=2)
    d.rectangle([40, 40, 600, 110], fill=accent_color)
    d.text((60, 65), header_text, fill=(255, 255, 255))
    y = 135
    for line in body_lines:
        d.text((65, y), line, fill=(30, 35, 45))
        y += 28
    save(img, path)

# -------------------------------------------------------------
# 1-20: FOUNDATIONAL 20 BENCHMARK THREAT TEST CASES
# -------------------------------------------------------------
standard_20 = [
    {
        "id": "TC-01-CLEAN",
        "name": "Clean Alpine Mountain Landscape",
        "description": "Nature scenery with zero human PII, faces, or credentials.",
        "category": "clean_photographs",
        "inputFixtureReference": "assets/samples/sample_clean_landscape.png",
        "expectedDetections": [],
        "expectedSeverity": "low",
        "minExpectedScore": 0,
        "maxExpectedScore": 25,
        "expectedRecommendations": ["No privacy redaction required."],
        "groundTruthAnnotations": [],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-02-FACES",
        "name": "Portrait of Individual in Public Setting",
        "description": "High-resolution facial portrait exposed in ordinary public setting.",
        "category": "faces_and_identity",
        "inputFixtureReference": "assets/samples/sample_ordinary_portrait.png",
        "expectedDetections": [{
            "category": "identity",
            "type": "human_face",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "low",
        "minExpectedScore": 0,
        "maxExpectedScore": 25,
        "expectedRecommendations": ["Blur or mask facial biometrics before sharing if privacy is desired."],
        "groundTruthAnnotations": [{
            "label": "Identifiable Face",
            "category": "identity",
            "boundingBox": [0.15, 0.30, 0.45, 0.70],
            "sensitiveText": None
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-03-STUDENT-ID",
        "name": "University Student Identification Card",
        "description": "Physical campus ID badge showing full name, student ID number, and barcode.",
        "category": "student_ids",
        "inputFixtureReference": "assets/samples/sample_student_id.png",
        "expectedDetections": [{
            "category": "identity",
            "type": "student_id_card",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 51,
        "maxExpectedScore": 90,
        "expectedRecommendations": ["Solid black redaction over student ID and photo."],
        "groundTruthAnnotations": [{
            "label": "Student ID Badge",
            "category": "identity",
            "boundingBox": [0.20, 0.20, 0.80, 0.80],
            "sensitiveText": "STU-9948201"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-04-EMPLOYEE-BADGE",
        "name": "Corporate Access Badge on Lanyard",
        "description": "Corporate access badge displaying company logo, clearance tier, and RFID chip.",
        "category": "employee_badges",
        "inputFixtureReference": "fixtures/corporate_badge.png",
        "expectedDetections": [{
            "category": "identity",
            "type": "employee_badge",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 51,
        "maxExpectedScore": 85,
        "expectedRecommendations": ["Redact organizational logos and employee badges."],
        "groundTruthAnnotations": [{
            "label": "Corporate Access Badge",
            "category": "identity",
            "boundingBox": [0.35, 0.40, 0.75, 0.65],
            "sensitiveText": None
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-05-GOV-ID",
        "name": "Government Passport Bio Page",
        "description": "Official national passport display with MRZ machine-readable zone, DOB, and passport number.",
        "category": "government_documents",
        "inputFixtureReference": "fixtures/passport_mrz.png",
        "expectedDetections": [{
            "category": "identity",
            "type": "government_passport",
            "minConfidence": 0.95,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 76,
        "maxExpectedScore": 100,
        "expectedRecommendations": ["DO NOT SHARE: Never post government identification documents online."],
        "groundTruthAnnotations": [{
            "label": "Passport Bio Page",
            "category": "identity",
            "boundingBox": [0.10, 0.10, 0.90, 0.90],
            "sensitiveText": "P<USA987654321"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-06-LICENSE-PLATE",
        "name": "Vehicle Registration License Plate",
        "description": "Public street vehicle displaying municipal registration numbers on bumper plate.",
        "category": "vehicle_plates",
        "inputFixtureReference": "fixtures/license_plate.png",
        "expectedDetections": [{
            "category": "location",
            "type": "vehicle_license_plate",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 40,
        "maxExpectedScore": 75,
        "expectedRecommendations": ["Mask vehicle license plates before posting."],
        "groundTruthAnnotations": [{
            "label": "License Plate",
            "category": "location",
            "boundingBox": [0.55, 0.40, 0.65, 0.60],
            "sensitiveText": "7XYZ890"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-07-ADDRESS-PLACARD",
        "name": "Residential Front Door House Placard",
        "description": "Front porch showing distinct house number and street plaque.",
        "category": "addresses_and_locations",
        "inputFixtureReference": "assets/samples/sample_street_house.png",
        "expectedDetections": [{
            "category": "location",
            "type": "residential_address_sign",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 51,
        "maxExpectedScore": 80,
        "expectedRecommendations": ["Mask house numbers and street name plaques."],
        "groundTruthAnnotations": [{
            "label": "House Number Placard",
            "category": "location",
            "boundingBox": [0.25, 0.35, 0.40, 0.50],
            "sensitiveText": "742 Evergreen"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-08-CONTACT-INFO",
        "name": "Business Card with Direct Contact Info",
        "description": "Direct personal mobile number and private email address on business card.",
        "category": "contact_information",
        "inputFixtureReference": "fixtures/business_card_contact.png",
        "expectedDetections": [{
            "category": "personal_info",
            "type": "contact_details",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 50,
        "maxExpectedScore": 80,
        "expectedRecommendations": ["Redact direct mobile phone numbers and email addresses."],
        "groundTruthAnnotations": [{
            "label": "Phone and Email Block",
            "category": "personal_info",
            "boundingBox": [0.45, 0.20, 0.70, 0.80],
            "sensitiveText": "+1-555-0199"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-09-QR-BARCODE",
        "name": "Wi-Fi Network Access QR Code",
        "description": "Wall placard showing 2D QR matrix encoding cleartext Wi-Fi network SSID and WPA2 key.",
        "category": "qr_and_barcodes",
        "inputFixtureReference": "fixtures/wifi_qr_code.png",
        "expectedDetections": [{
            "category": "digital_security",
            "type": "wifi_access_qr",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 55,
        "maxExpectedScore": 85,
        "expectedRecommendations": ["Scramble or obscure QR codes encoding network credentials."],
        "groundTruthAnnotations": [{
            "label": "Wi-Fi QR Code",
            "category": "digital_security",
            "boundingBox": [0.30, 0.30, 0.70, 0.70],
            "sensitiveText": None
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-10-TERMINAL-SCREEN",
        "name": "Engineer Terminal Display with Cloud Token",
        "description": "High-res photograph of developer monitor showing bash shell history and AWS access key.",
        "category": "computer_screens",
        "inputFixtureReference": "assets/samples/sample_workstation_screen.png",
        "expectedDetections": [{
            "category": "digital_security",
            "type": "screen_terminal_credential",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 80,
        "maxExpectedScore": 100,
        "expectedRecommendations": ["Revoke active tokens immediately and redact screen contents."],
        "groundTruthAnnotations": [{
            "label": "Terminal Shell Window",
            "category": "digital_security",
            "boundingBox": [0.15, 0.15, 0.75, 0.85],
            "sensitiveText": "AKIAIOSFODNN7EXAMPLE"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-11-BANK-STATEMENT",
        "name": "Bank Account Statement with Routing Info",
        "description": "Paper bank statement on desk showing account balance, bank routing number, and account number.",
        "category": "financial_documents",
        "inputFixtureReference": "fixtures/bank_statement.png",
        "expectedDetections": [{
            "category": "personal_info",
            "type": "bank_statement",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 76,
        "maxExpectedScore": 100,
        "expectedRecommendations": ["Do not share banking information or account numbers online."],
        "groundTruthAnnotations": [{
            "label": "Bank Account Number",
            "category": "personal_info",
            "boundingBox": [0.35, 0.20, 0.55, 0.80],
            "sensitiveText": "Routing: 122000496"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-12-BOARDING-PASS",
        "name": "Commercial Airline Boarding Pass",
        "description": "Airport gate photo displaying passenger name, flight number, 6-character PNR record locator, and barcode.",
        "category": "travel_documents",
        "inputFixtureReference": "assets/samples/sample_boarding_pass.png",
        "expectedDetections": [{
            "category": "personal_info",
            "type": "airline_boarding_pass",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 60,
        "maxExpectedScore": 85,
        "expectedRecommendations": ["Redact PNR record locators and PDF417 boarding barcodes."],
        "groundTruthAnnotations": [{
            "label": "Boarding Pass Stub",
            "category": "personal_info",
            "boundingBox": [0.25, 0.20, 0.75, 0.80],
            "sensitiveText": "PNR: AB789X"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-13-STICKY-PASSWORD",
        "name": "Monitor Sticky Note with Cleartext Password",
        "description": "Post-it adhesive note affixed to monitor bezel with written VPN password.",
        "category": "exposed_credentials",
        "inputFixtureReference": "fixtures/sticky_password.png",
        "expectedDetections": [{
            "category": "digital_security",
            "type": "plaintext_password_note",
            "minConfidence": 0.95,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 85,
        "maxExpectedScore": 100,
        "expectedRecommendations": ["Remove sticky note immediately and change credentials."],
        "groundTruthAnnotations": [{
            "label": "Sticky Note Credential",
            "category": "digital_security",
            "boundingBox": [0.60, 0.70, 0.80, 0.90],
            "sensitiveText": "Pwd: CorrectHorseBattery#9"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-14-EXIF-METADATA",
        "name": "Photograph with Embedded GPS EXIF Metadata",
        "description": "Image whose EXIF tags contain precise GPS coordinates pointing to private residence.",
        "category": "metadata_exposure",
        "inputFixtureReference": "fixtures/exif_gps_image.jpg",
        "expectedDetections": [{
            "category": "location",
            "type": "exif_gps_coordinates",
            "minConfidence": 0.99,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 50,
        "maxExpectedScore": 75,
        "expectedRecommendations": ["Strip EXIF metadata before publishing photograph online."],
        "groundTruthAnnotations": [{
            "label": "EXIF GPS Header",
            "category": "location",
            "boundingBox": [0.0, 0.0, 1.0, 1.0],
            "sensitiveText": "37.7749 N, 122.4194 W"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-15-COMPOUND-SCENE",
        "name": "Compound Scene: Badge + House Number + Vehicle",
        "description": "Selfie taken in driveway showing corporate badge, residential address sign, and parked vehicle.",
        "category": "multiple_exposures",
        "inputFixtureReference": "fixtures/compound_driveway_scene.png",
        "expectedDetections": [
            {"category": "identity", "type": "badge", "minConfidence": 0.8, "isDirectExposure": True},
            {"category": "location", "type": "address", "minConfidence": 0.8, "isDirectExposure": True}
        ],
        "expectedSeverity": "critical",
        "minExpectedScore": 65,
        "maxExpectedScore": 100,
        "expectedRecommendations": ["Apply multi-point redaction across badge and address markers."],
        "groundTruthAnnotations": [
            {"label": "Access Badge", "category": "identity", "boundingBox": [0.2, 0.2, 0.4, 0.4], "sensitiveText": None},
            {"label": "House Placard", "category": "location", "boundingBox": [0.6, 0.6, 0.8, 0.8], "sensitiveText": "No. 42"}
        ],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-16-BLURRED-DATA",
        "name": "Partially Blurred Credit Card Number",
        "description": "Payment card with Gaussian blur where first 12 digits remain partially decipherable.",
        "category": "blurred_information",
        "inputFixtureReference": "fixtures/partially_blurred_card.png",
        "expectedDetections": [{
            "category": "personal_info",
            "type": "partially_blurred_pan",
            "minConfidence": 0.70,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 50,
        "maxExpectedScore": 80,
        "expectedRecommendations": ["Use opaque solid block redaction rather than reversible blur."],
        "groundTruthAnnotations": [{
            "label": "Payment Card PAN",
            "category": "personal_info",
            "boundingBox": [0.40, 0.20, 0.60, 0.80],
            "sensitiveText": "4111 **** **** 1111"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-17-LOW-QUALITY",
        "name": "Low-Resolution Grainy Street Scene",
        "description": "Heavily compressed, noisy image where small background text is degraded.",
        "category": "low_quality_images",
        "inputFixtureReference": "fixtures/low_quality_grain.jpg",
        "expectedDetections": [],
        "expectedSeverity": "low",
        "minExpectedScore": 0,
        "maxExpectedScore": 35,
        "expectedRecommendations": ["No high-confidence privacy exposure identified."],
        "groundTruthAnnotations": [],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-18-AMBIGUOUS-TEXT",
        "name": "Fragmented Partial Digits on Discarded Paper",
        "description": "Torn slip with ambiguous 4-digit sequence (could be year, price, or PIN).",
        "category": "ambiguous_cases",
        "inputFixtureReference": "fixtures/ambiguous_digits.png",
        "expectedDetections": [{
            "category": "personal_info",
            "type": "ambiguous_numeric_token",
            "minConfidence": 0.50,
            "isDirectExposure": False
        }],
        "expectedSeverity": "moderate",
        "minExpectedScore": 20,
        "maxExpectedScore": 45,
        "expectedRecommendations": ["Review ambiguous numeric fragments before sharing."],
        "groundTruthAnnotations": [{
            "label": "Fragmented Numbers",
            "category": "personal_info",
            "boundingBox": [0.45, 0.40, 0.55, 0.60],
            "sensitiveText": "4820"
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-19-FALSE-POSITIVE",
        "name": "Movie Poster with Fictional Actor Identification",
        "description": "Theatrical cinema poster displaying fictional character name and barcode graphic.",
        "category": "false_positive_scenarios",
        "inputFixtureReference": "fixtures/movie_poster_prop.png",
        "expectedDetections": [],
        "expectedSeverity": "low",
        "minExpectedScore": 0,
        "maxExpectedScore": 35,
        "expectedRecommendations": ["Public promotional material; no personal risk detected."],
        "groundTruthAnnotations": [],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    },
    {
        "id": "TC-20-DEGRADED-DETECTOR",
        "name": "Detector Failure Fallback (Simulated Degraded State)",
        "description": "Pipeline executed with detector fault; system must enforce >= 50 safety floor.",
        "category": "analysis_failure_scenarios",
        "inputFixtureReference": "assets/samples/sample_student_id.png",
        "expectedDetections": [],
        "expectedSeverity": "moderate",
        "minExpectedScore": 50,
        "maxExpectedScore": 65,
        "expectedRecommendations": ["Manual review required: AI vision detectors encountered a fault."],
        "groundTruthAnnotations": [],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    }
]

cases.extend(standard_20)

# -------------------------------------------------------------
# 21-120: 100 NEW DIVERSE THREAT DOMAIN BENCHMARKS
# -------------------------------------------------------------

# 1. Badges & Physical Access (TC-21 to TC-30)
badge_scenarios = [
    ("TC-21-CORP-BADGE", "Global Tech Enterprise Access Badge", "Employee badge showing employee ID, full name, and high-security facility tier.", "fixtures/corporate_badge.png", "Alex Vance", "EMP-88391-Z"),
    ("TC-22-STUDENT-ID-2", "State University Student Identification Card", "Student photo ID exposing matriculation number, major, and campus RFID tag.", "fixtures/badge_student_photo.png", "Samantha Hayes", "STU-99201-A"),
    ("TC-23-HOSPITAL-STAFF", "Hospital Medical Staff ID Badge", "Emergency room nurse badge showing medical license number and floor access.", "fixtures/badge_hospital_nurse.png", "Sarah Jenkins, RN", "MED-LIC-44829"),
    ("TC-24-PRESS-CREDENTIAL", "Press & Media Access Pass", "Journalist media pass with press pass ID and backstage access zones.", "fixtures/badge_press_pass.png", "Marcus Vance", "PRESS-NYC-0092"),
    ("TC-25-DEFENSE-CONTRACT", "Defense Contractor Facility Clearance Badge", "Security clearance badge with level 5 badge clearance and barcoded serial.", "fixtures/badge_defense_contractor.png", "Evelyn Reed", "DOD-CTR-77218"),
    ("TC-26-CONF-ATTENDEE", "Cybersecurity Summit Attendee Badge", "Conference badge showing corporate affiliation, attendee QR code, and VIP tier.", "fixtures/badge_cyber_summit.png", "Liam Gallagher", "ATT-SUMMIT-2026"),
    ("TC-27-SERVER-ROOM", "Datacenter Biometric Keycard", "Data center biometric escort badge displaying cage assignment and access code.", "fixtures/badge_datacenter_key.png", "David K. Miller", "DC-ASHBURN-CAGE4"),
    ("TC-28-VISITOR-PASS", "Corporate Visitor Escort Pass", "Temporary guest pass showing host employee name, guest name, and visit date.", "fixtures/badge_corp_visitor.png", "VISITOR: Chloe Bennett", "HOST: Michael Wong"),
    ("TC-29-HOTEL-KEYCARD", "Hotel Room Key Envelope with Room Number", "Hotel paper sleeve displaying handwritten room 1408 and guest name.", "fixtures/badge_hotel_room_sleeve.png", "GUEST: Jennifer Lopez", "ROOM 1408 - SUITE"),
    ("TC-30-WRISTBAND-VIP", "Festival VIP Access Wristband Barcode", "Fabric festival wristband displaying unique barcoded serial number.", "fixtures/badge_vip_wristband.png", "VIP ACCESS TIER 1", "SERIAL: 98112-VIP-Z"),
]

for cid, name, desc, path, pii_name, pii_id in badge_scenarios:
    if not os.path.exists(path):
        make_card_img(path, (255, 255, 255), "FACILITY ACCESS IDENTIFICATION", [
            f"NAME: {pii_name}",
            f"ID / IDENTIFIER: {pii_id}",
            "ACCESS LEVEL: RESTRICTED ZONE",
            "RFID SERIAL: [|||||||||||||||||||||||]"
        ])
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "employee_badges",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "identity",
            "type": "employee_badge",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 51,
        "maxExpectedScore": 85,
        "expectedRecommendations": [
            "Blur organizational name, employee badge number, and barcode before sharing.",
            "Mask photos and facility access tier indicators."
        ],
        "groundTruthAnnotations": [{
            "label": "Organizational Access Badge",
            "category": "identity",
            "boundingBox": [0.2, 0.1, 0.8, 0.9],
            "sensitiveText": pii_id
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 2. Government & Official Identity Documents (TC-31 to TC-40)
gov_scenarios = [
    ("TC-31-PASSPORT-MRZ", "International Passport Machine Readable Zone", "Passport booklet bio page exposing MRZ strings, full name, DOB, and passport no.", "fixtures/passport_mrz.png", "P<USA987654321"),
    ("TC-32-DRIVERS-LICENSE", "State Real ID Driver's License", "Driver's license showing driver license number, home address, DOB, and organ donor status.", "fixtures/govid_drivers_license.png", "DL: D-8829104-CA"),
    ("TC-33-SSN-CARD", "Social Security Administration Number Card", "Paper SSN card showing full 9-digit social security identifier.", "fixtures/govid_ssn_card.png", "SSN: 000-12-3456"),
    ("TC-34-NATIONAL-ID", "National Citizen Biometric Smart Card", "Smartcard identity card with national citizen registry number and chip pins.", "fixtures/govid_national_id.png", "NAT-ID: 772-901-441-A"),
    ("TC-35-MILITARY-CAC", "Armed Forces Common Access Card", "Department of Defense CAC card displaying Geneva Convention category and rank.", "fixtures/govid_military_cac.png", "DOD-ID: 1049281042"),
    ("TC-36-VOTER-REG", "Municipal Voter Registration Certificate", "County board of elections certificate card showing precinct and voter ID.", "fixtures/govid_voter_reg.png", "VOTER-ID: VTR-881902"),
    ("TC-37-PERM-RESIDENT", "Permanent Resident Green Card", "USCIS permanent resident card showing alien registration number (A-Number).", "fixtures/govid_green_card.png", "USCIS#: 099-182-441"),
    ("TC-38-TAX-RETURN", "IRS Form 1040 Individual Tax Return Header", "Top portion of Form 1040 displaying taxpayer name, filing status, and SSN.", "fixtures/govid_tax_return.png", "FORM 1040 - SSN: 123-45-6789"),
    ("TC-39-BIRTH-CERT", "Official State Vital Records Birth Certificate", "Certified state registrar birth certificate showing parental names and record seal.", "fixtures/govid_birth_cert.png", "CERT-OF-BIRTH: 140-1988-991"),
    ("TC-40-DIPLOMATIC-ID", "Department of State Diplomatic Consular ID", "Consular diplomatic identity card showing diplomatic immunity tier.", "fixtures/govid_diplomatic_id.png", "DIP-CORPS: D-2026-0041"),
]

for cid, name, desc, path, gov_id in gov_scenarios:
    if not os.path.exists(path):
        make_card_img(path, (255, 255, 250), "OFFICIAL GOVERNMENT IDENTIFICATION", [
            "ISSUING AUTHORITY: OFFICIAL GOVERNMENT BODY",
            f"IDENTIFIER NUMBER: {gov_id}",
            "DATE OF BIRTH: 1988-04-12",
            "DOCUMENT CLASS: PRIMARY LEGAL IDENTITY"
        ], accent_color=(20, 60, 120))
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "government_documents",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "identity",
            "type": "government_identification",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 76,
        "maxExpectedScore": 100,
        "expectedRecommendations": [
            "DO NOT SHARE: Never publish government documents online.",
            "Solid opaque redaction required over all government identifiers."
        ],
        "groundTruthAnnotations": [{
            "label": "Government Identification Document",
            "category": "identity",
            "boundingBox": [0.1, 0.1, 0.9, 0.9],
            "sensitiveText": gov_id
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 3. Financial Instruments & Payment Privacy (TC-41 to TC-50)
fin_scenarios = [
    ("TC-41-CARD-FRONT", "Visa Signature Credit Card Front", "Payment card showing full 16-digit PAN embossed number and expiration date.", "fixtures/fin_card_front.png", "4111 2222 3333 4444", "04/28"),
    ("TC-42-CARD-BACK", "Payment Card Reverse CVV Security Code", "Reverse of Mastercard displaying 3-digit CVV security code and signature panel.", "fixtures/fin_card_back.png", "CVV: 789", "SIGNATURE: John Doe"),
    ("TC-43-CHECK-MICR", "Personal Bank Check Bottom MICR Line", "Paper bank check showing magnetic ink routing number and bank account number.", "fixtures/fin_check_micr.png", "T122000496T  1234567890O 101", "AMT: $1,250.00"),
    ("TC-44-ATM-RECEIPT", "Automated Teller Machine Balance Receipt", "Paper transaction slip showing remaining ledger balance and masked account ending.", "fixtures/fin_atm_receipt.png", "ACCT: *******8920  BAL: $14,920.12", "ATM LOC: 4492 BROADWAY"),
    ("TC-45-CRYPTO-SEED", "Cryptocurrency Hardware Wallet Recovery Sheet", "BIP-39 mnemonic phrase backup sheet showing 12 cleartext secret recovery seed words.", "fixtures/fin_crypto_seed.png", "SEED: apple forest climb victory ocean...", "WALLET: ETH / BTC COLD STORAGE"),
    ("TC-46-WIRE-INSTRUCT", "Commercial Escrow Wire Transfer Sheet", "Escrow wire instructions displaying SWIFT BIC, IBAN, and intermediary bank.", "fixtures/fin_wire_sheet.png", "IBAN: US92CHAS122000496123456", "SWIFT: CHASUS33"),
    ("TC-47-PAYSTUB-DETAIL", "Corporate Biweekly Earnings Paystub", "Earnings statement showing YTD gross compensation, tax withholding, and direct deposit.", "fixtures/fin_paystub.png", "NET PAY: $4,281.90  YTD: $85,000", "DEPOSIT: CHASE ****4921"),
    ("TC-48-BROKERAGE-STMT", "Investment Securities Portfolio Summary", "Brokerage statement showing equity positions, margin debt, and total portfolio equity.", "fixtures/fin_brokerage_stmt.png", "PORTFOLIO VALUE: $284,912.40", "ACCT NO: 884-91028-V"),
    ("TC-49-POS-TERMINAL", "Point of Sale Merchant Counter Slip", "Customer card slip showing cardholder signature and merchant transaction token.", "fixtures/fin_pos_slip.png", "AUTH CODE: 09921A  TRANSACTION #8819", "CARD: VISA DEBIT ****1928"),
    ("TC-50-MOBILE-BANK", "Smartphone Mobile Banking App Screen", "Mobile phone screen displaying active checking balance and recent Zelle transfers.", "fixtures/fin_mobile_banking.png", "AVAILABLE BALANCE: $8,491.22", "RECENT: ZELLE TO MIKE -$150"),
]

for cid, name, desc, path, fin_data1, fin_data2 in fin_scenarios:
    if not os.path.exists(path):
        make_card_img(path, (255, 255, 255), "FINANCIAL RECORD & PAYMENT DATA", [
            f"PRIMARY DATA: {fin_data1}",
            f"SECONDARY DATA: {fin_data2}",
            "PCI-DSS WARNING: RESTRICTED FINANCIAL INFORMATION",
            "REMEDIATION: FULL IRREVERSIBLE REDACTION"
        ], accent_color=(20, 100, 60))
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "financial_documents",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "personalInfo",
            "type": "financial_instrument",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 76,
        "maxExpectedScore": 100,
        "expectedRecommendations": [
            "PCI-DSS Violation: Redact payment account numbers immediately.",
            "Do not disclose bank routing numbers or financial balances."
        ],
        "groundTruthAnnotations": [{
            "label": "Financial Account Instrument",
            "category": "personalInfo",
            "boundingBox": [0.15, 0.20, 0.85, 0.80],
            "sensitiveText": fin_data1
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 4. Digital Credentials & Cyber OPSEC (TC-51 to TC-60)
sec_scenarios = [
    ("TC-51-STICKY-PASS", "Adhesive Note with Cleartext Password", "Sticky note affixed to workstation monitor bezel with written login credentials.", "fixtures/sticky_password.png", "Pwd: CorrectHorseBattery#9"),
    ("TC-52-AWS-KEY", "Workstation Code Window with AWS Access Key", "Code editor tab displaying hardcoded AWS access key ID and secret key string.", "fixtures/sec_aws_key.png", "AKIAIOSFODNN7EXAMPLE"),
    ("TC-53-SSH-KEY", "Terminal Window Displaying SSH Private Key", "Terminal window showing BEGIN OPENSSH PRIVATE KEY block header and key body.", "fixtures/sec_ssh_key.png", "-----BEGIN OPENSSH PRIVATE KEY-----"),
    ("TC-54-API-TOKEN", "Postman REST Client with Bearer Auth Token", "API client window showing Authorization Bearer JWT token header with signature.", "fixtures/sec_api_token.png", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."),
    ("TC-55-GITHUB-PAT", "Settings Tab Showing GitHub Personal Access Token", "Browser screenshot showing mock OAuth personal access token with repository scopes.", "fixtures/sec_github_pat.png", "ghp_EXAMPLE_MOCK_PAT_TOKEN_0194821a"),
    ("TC-56-DB-CONN-STR", "Application Config File Database Connection URI", "Dotenv or yaml file displaying postgresql:// user, password, and host endpoint.", "fixtures/sec_db_conn.png", "postgres://admin:Sup3rS3cr3t@db.internal:5432/prod"),
    ("TC-57-WIFI-WPA", "Router Base Sticker with Network WPA Key", "Photo of underside of Wi-Fi router showing factory default SSID and WPA2 passkey.", "fixtures/sec_wifi_wpa.png", "SSID: Netgear-5G  WPA_KEY: 8912-8821-4412"),
    ("TC-58-MFA-BACKUP", "Authenticator App Emergency Recovery Backup Codes", "Printed emergency sheet displaying eight 8-digit one-time 2FA recovery backup codes.", "fixtures/sec_mfa_backup.png", "MFA BACKUP: 8819 2014  9928 1042"),
    ("TC-59-STRIPE-SECRET", "Webhook Handler with Stripe Secret Live Key", "Python script showing Stripe payment gateway API secret test key.", "fixtures/sec_stripe_secret.png", "sk_test_51Hz89102839102834019284102_TEST"),
    ("TC-60-KUBE-CONFIG", "Cluster Admin Kubernetes Config File", "Kubeconfig YAML file showing client-certificate-data and cluster endpoint.", "fixtures/sec_kube_config.png", "apiVersion: v1 clusters: cluster-admin-auth"),
]

for cid, name, desc, path, secret_val in sec_scenarios:
    if not os.path.exists(path):
        img = make_img(640, 480, (20, 24, 30))
        d = ImageDraw.Draw(img)
        d.text((40, 40), "# CYBERSECURITY EXPOSURE - SENSITIVE CREDENTIAL", fill=(220, 50, 50))
        d.rectangle([40, 80, 600, 420], fill=(30, 35, 45), outline=(60, 70, 85))
        d.text((60, 100), f"CONFIG / SECRET EXPOSURE: {secret_val}", fill=(240, 220, 100))
        d.text((60, 140), "WARNING: REVOKE TOKEN IMMEDIATELY AND ROTATE KEYS", fill=(200, 200, 200))
        save(img, path)
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "exposed_credentials",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "digital",
            "type": "exposed_credential",
            "minConfidence": 0.90,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 85,
        "maxExpectedScore": 100,
        "expectedRecommendations": [
            "CRITICAL: Revoke exposed API token or password immediately.",
            "Never store plaintext credentials in photos or code repositories."
        ],
        "groundTruthAnnotations": [{
            "label": "Plaintext Credential Secret",
            "category": "digital",
            "boundingBox": [0.1, 0.15, 0.9, 0.85],
            "sensitiveText": secret_val
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 5. Workstation Screens & Internal Dashboards (TC-61 to TC-70)
screen_scenarios = [
    ("TC-61-DB-QUERY", "Production Database Customer Records Table", "Data administration GUI showing rows of customer full names, emails, and balances.", "fixtures/screen_db_query.png", "SELECT * FROM customers WHERE balance > 1000"),
    ("TC-62-SLACK-CHAT", "Internal Slack Communications Channel", "Team messaging workspace showing proprietary product launch dates and confidential discussions.", "fixtures/screen_slack_chat.png", "#exec-confidential: Project Titan Launch Oct 24"),
    ("TC-63-CRM-RECORD", "Salesforce Customer Relationship Profile", "Enterprise CRM client dashboard showing company revenue, decision maker phone, and deal value.", "fixtures/screen_crm_profile.png", "OPPORTUNITY: Acme Corp - $1.4M ARR"),
    ("TC-64-HIPAA-EMR", "Hospital Electronic Medical Record Portal", "Healthcare workstation screen showing patient oncology report and attending doctor notes.", "fixtures/screen_emr_portal.png", "PATIENT ID: 99182-B  DIAGNOSIS: CONFIDENTIAL"),
    ("TC-65-JENKINS-CI", "Jenkins CI/CD Build Pipeline Credentials", "Continuous integration build console displaying automated deploy environmental variables.", "fixtures/screen_jenkins_ci.png", "ENV: PROD_RELEASE_KEY=***masked***"),
    ("TC-66-FIN-TERMINAL", "Bloomberg Trading Terminal Window", "Financial market terminal displaying multi-million dollar equity order book and trader ID.", "fixtures/screen_bloomberg.png", "TRADER ID: NYC-FLOOR-88  EXECUTION ORDER: LONG"),
    ("TC-67-HR-PORTAL", "Workday HR Management Employee Record", "Human resources portal showing employee performance evaluation, salary grade, and address.", "fixtures/screen_hr_workday.png", "SALARY GRADE: L7  PERFORMANCE: EXCEEDS"),
    ("TC-68-SOURCE-CODE", "Proprietary Core Algorithm Source Code", "IDE workspace displaying trade secret proprietary trading execution logic.", "fixtures/screen_source_code.png", "def calculate_arbitrage_alpha(signals):"),
    ("TC-69-CAD-BLUEPRINT", "Confidential Hardware CAD Engineering Blueprint", "Industrial engineering schematic showing patent-pending drone propulsion assembly.", "fixtures/screen_cad_blueprint.png", "PROJECT CONDOR: ROTOR SCHEMATIC REV 4"),
    ("TC-70-WORKSTATION-SCREEN", "Multi-Monitor Workstation Overview", "Wide desktop photo showing terminal, Jira backlog, and calendar appointment schedule.", "assets/samples/sample_workstation_screen.png", "DESKTOP OVERVIEW - WORK IN PROGRESS"),
]

for cid, name, desc, path, screen_detail in screen_scenarios:
    if not os.path.exists(path):
        img = make_img(640, 480, (25, 30, 40))
        d = ImageDraw.Draw(img)
        d.text((40, 30), f"WORKSTATION DISPLAY: {screen_detail}", fill=(100, 200, 255))
        d.rectangle([40, 70, 600, 430], fill=(15, 20, 28), outline=(40, 50, 70))
        d.text((60, 90), f"INTERNAL SYSTEM DATA: {screen_detail}", fill=(200, 220, 240))
        d.text((60, 130), "SECURITY CLASSIFICATION: INTERNAL / PROPRIETARY", fill=(255, 120, 120))
        save(img, path)
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "computer_screens",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "digital",
            "type": "screen_display",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 75,
        "maxExpectedScore": 100,
        "expectedRecommendations": [
            "Screens in public photographs should be blurred or turned off.",
            "Proprietary dashboards must not be captured in office photos."
        ],
        "groundTruthAnnotations": [{
            "label": "Workstation Screen Display",
            "category": "digital",
            "boundingBox": [0.1, 0.1, 0.9, 0.9],
            "sensitiveText": screen_detail
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 6. Vehicles & Public Transportation (TC-71 to TC-80)
veh_scenarios = [
    ("TC-71-CAR-PLATE", "Sedan Vehicle License Plate in Driveway", "Automobile rear bumper displaying state municipal registration license plate.", "fixtures/license_plate.png", "7XYZ890"),
    ("TC-72-EURO-PLATE", "European Union Vehicle Registration Plate", "Front vehicle bumper displaying blue EU country strip and registration code.", "fixtures/veh_euro_plate.png", "B-MK 2026"),
    ("TC-73-COMMERCIAL-FLEET", "Commercial Delivery Van Fleet Number & DOT", "Side of commercial cargo van showing USDOT carrier number and fleet vehicle ID.", "fixtures/veh_commercial_van.png", "USDOT: 2891049  UNIT #402"),
    ("TC-74-TAXI-MEDALLION", "Metropolitan Taxi Cab Medallion Number", "Roof medallion beacon and door decal showing city taxi license number.", "fixtures/veh_taxi_medallion.png", "TAXI MEDALLION: 4W92"),
    ("TC-75-CAR-VIN", "Dashboard Vehicle Identification Number (VIN)", "Windshield base corner displaying 17-character VIN barcode and cleartext string.", "fixtures/veh_car_vin.png", "VIN: 1HGCR2F83HA009214"),
    ("TC-76-PARKING-PERMIT", "Residential Zone Street Parking Permit Sticker", "Front windshield adhesive decal showing neighborhood zone 4 permit and expiry.", "fixtures/veh_parking_permit.png", "ZONE 4 PERMIT #99182"),
    ("TC-77-TOLL-TRANSPONDER", "Electronic Toll Tag Serial & Barcode", "EZ-Pass transponder mounted behind rearview mirror displaying printed serial.", "fixtures/veh_toll_tag.png", "E-ZPASS: 022099182410"),
    ("TC-78-DISABILITY-PLACARD", "State Disability Parking Placard Hangtag", "Mirror hangtag displaying registered disability authorization number.", "fixtures/veh_disability_placard.png", "PLACARD: DP-8819204"),
    ("TC-79-MOTORCYCLE-TAG", "Motorcycle Tail Fender License Plate", "Motorcycle rear bracket displaying compact state motorcycle registration tag.", "fixtures/veh_motorcycle_tag.png", "MC-TAG: 88A921"),
    ("TC-80-TRANSIT-PASS", "City Metro Transit Smartcard Serial", "Plastic subway farecard displaying printed 16-digit cardholder transit serial.", "fixtures/veh_transit_pass.png", "METROCARD: 0881 9201 4410 8821"),
]

for cid, name, desc, path, tag_str in veh_scenarios:
    if not os.path.exists(path):
        img = make_img(640, 480, (210, 215, 220))
        d = ImageDraw.Draw(img)
        d.rectangle([120, 160, 520, 320], fill=(255, 255, 255), outline=(20, 20, 20), width=4)
        d.text((150, 220), f"REGISTRATION: {tag_str}", fill=(10, 10, 10))
        save(img, path)
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "vehicle_plates",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "transportation",
            "type": "vehicle_identifier",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 40,
        "maxExpectedScore": 75,
        "expectedRecommendations": [
            "Mask vehicle license plate numbers before posting photographs.",
            "Vehicle tags can be cross-referenced with DMV owner databases."
        ],
        "groundTruthAnnotations": [{
            "label": "Vehicle License Tag",
            "category": "transportation",
            "boundingBox": [0.2, 0.3, 0.8, 0.7],
            "sensitiveText": tag_str
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 7. Geolocation & Physical Addresses (TC-81 to TC-90)
geo_scenarios = [
    ("TC-81-HOUSE-PLACARD", "Residential Front Door House Placard", "Front porch showing distinct house number and street plaque.", "assets/samples/sample_street_house.png", "742 Evergreen"),
    ("TC-82-STREET-SIGN", "Suburban Street Intersection Road Signposts", "Intersecting green municipal signs showing 'Oak Ave' and 'Maple Blvd'.", "fixtures/geo_street_signs.png", "CORNER OF OAK & MAPLE"),
    ("TC-83-PACKAGE-LABEL", "Courier Delivery Parcel Shipping Label", "Cardboard delivery box showing recipient name, apartment number, and tracking barcode.", "fixtures/geo_shipping_label.png", "SHIP TO: John Doe, Apt 4B"),
    ("TC-84-MAILBOX-NUMBER", "Curbside Rural Mailbox Number & Name", "Black metal mailbox displaying reflective house digits and family surname.", "fixtures/geo_rural_mailbox.png", "10492 MILLER CREEK RD"),
    ("TC-85-INTERCOM-DIR", "Apartment Building Intercom Resident Directory", "Vestibule buzzer panel showing directory of tenant last names and unit codes.", "fixtures/geo_intercom_dir.png", "BUZZER 402: SMITH, R."),
    ("TC-86-LANDMARK-GEO", "Easily Identifiable Local Storefront & Address", "Boutique storefront displaying business registration and street address digits.", "fixtures/geo_storefront.png", "128 W 4th Street"),
    ("TC-87-FLIGHT-RADAR", "Private Aviation Hangar Tail Number & FBO", "Airfield hangar photo displaying private jet tail registration number.", "fixtures/geo_hangar_tail.png", "N-8921X - SIGNATURE FBO"),
    ("TC-88-MAP-PIN", "Smartphone Map Navigation Turn-by-Turn Route", "In-car phone mount displaying active navigation route to home address.", "fixtures/geo_gps_nav.png", "NAVIGATING TO HOME: 14 MILES"),
    ("TC-89-HOTEL-KEY-SVR", "Hotel Keycard Sleeve with Room & Guest Name", "Paper folder displaying handwritten room number 1408 and guest name.", "fixtures/geo_hotel_sleeve.png", "ROOM 1408 - J. VANCE"),
    ("TC-90-LEASE-AGREEMENT", "Residential Apartment Lease Agreement Cover", "Lease document showing tenant names, landlord name, and property address.", "fixtures/geo_lease_agreement.png", "LEASE: 742 Evergreen Terrace"),
]

for cid, name, desc, path, geo_data in geo_scenarios:
    if not os.path.exists(path):
        img = make_img(640, 480, (235, 230, 220))
        d = ImageDraw.Draw(img)
        d.rectangle([60, 100, 580, 380], fill=(255, 255, 255), outline=(150, 140, 130), width=2)
        d.text((80, 140), "PHYSICAL RESIDENCE / GEOLOCATION DATA", fill=(40, 40, 40))
        d.text((80, 180), f"ADDRESS MARKER: {geo_data}", fill=(180, 50, 30))
        d.text((80, 220), "PRIVACY IMPACT: REVEALS EXACT RESIDENTIAL LOCATION", fill=(80, 80, 80))
        save(img, path)
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "addresses_and_locations",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "location",
            "type": "residential_location",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 50,
        "maxExpectedScore": 80,
        "expectedRecommendations": [
            "Mask house numbers and street name signs to avoid doxxing.",
            "Avoid sharing shipping parcel labels showing delivery addresses."
        ],
        "groundTruthAnnotations": [{
            "label": "Residential Address Marker",
            "category": "location",
            "boundingBox": [0.15, 0.2, 0.85, 0.8],
            "sensitiveText": geo_data
        }],
        "evaluationCriteria": "severity_match",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 8. Travel, Logistics & Communications (TC-91 to TC-100)
travel_scenarios = [
    ("TC-91-BOARDING-PASS", "Commercial Airline Boarding Pass PNR & Barcode", "Gate photograph showing passenger name, flight number, and 6-char PNR locator.", "assets/samples/sample_boarding_pass.png", "PNR: AB789X"),
    ("TC-92-LUGGAGE-TAG", "Airport Checked Baggage Barcode Tag", "Suitcase tag showing traveler cell phone, flight route, and baggage tracking ID.", "fixtures/trv_luggage_tag.png", "BAG TAG: UA-991824 - CELL: 555-0199"),
    ("TC-93-TRAIN-TICKET", "High-Speed Rail e-Ticket Booking QR Code", "Train ticket showing passenger reservation reference and departure time.", "fixtures/trv_train_ticket.png", "BOOKING: EURO-882194 - SEAT 42A"),
    ("TC-94-HOTEL-FOLIO", "Hotel Checkout Itemized Billing Statement", "Invoice showing guest home address, dates of stay, and room charges.", "fixtures/trv_hotel_folio.png", "FOLIO #88194 - GUEST: MARK SPENCER"),
    ("TC-95-RENTAL-CAR", "Rental Car Vehicle Agreement Contract", "Rental envelope displaying driver license copy, rental agreement, and credit card.", "fixtures/trv_car_rental.png", "AGREEMENT: HERTZ-GOLD-99182"),
    ("TC-96-CRUISE-CARD", "Cruise Ship SeaPass Stateroom Card", "Plastic cruise keycard showing ship name, stateroom number, and passenger name.", "fixtures/trv_cruise_card.png", "CABIN: 8140 - SHIP: OCEANIA PEARL"),
    ("TC-97-CUSTOMS-DEC", "International Customs Border Declaration Form", "Immigration customs slip showing passport number and destination address.", "fixtures/trv_customs_dec.png", "CUSTOMS: DECLARED CURRENCY & GOODS"),
    ("TC-98-CONCERT-TICK", "Arena Concert Ticket Barcode & Section", "Paper concert ticket showing row, seat, and transferable barcode string.", "fixtures/trv_concert_ticket.png", "EVENT: MADISON SQ GARDEN - SEC 102"),
    ("TC-99-PARKING-STUB", "Airport Valet Parking Claim Ticket", "Valet claim receipt displaying vehicle key tag number and license plate.", "fixtures/trv_valet_stub.png", "VALET TICKET #04921 - LOT C"),
    ("TC-100-CAR-RETURN", "Airport Car Rental Return Fuel Slip", "Digital handheld receipt showing mileage, fuel charge, and driver name.", "fixtures/trv_fuel_receipt.png", "RETURN: SFO TERMINAL 2 - MILES: 42,109"),
]

for cid, name, desc, path, trv_data in travel_scenarios:
    if not os.path.exists(path):
        make_card_img(path, (255, 255, 255), "TRAVEL DOCUMENTATION & RESERVATION", [
            f"DATA / RECORD: {trv_data}",
            "RISK: REVEALS TRAVEL SCHEDULE AND CONTACT DETAILS",
            "RECOMMENDATION: DO NOT POST BOARDING PASSES BEFORE FLIGHT"
        ], accent_color=(30, 90, 150))
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "travel_documents",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "personalInfo",
            "type": "travel_document",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "high",
        "minExpectedScore": 55,
        "maxExpectedScore": 85,
        "expectedRecommendations": [
            "Never post photographs of boarding passes before travel is completed.",
            "Barcodes on boarding passes contain full reservation passenger records."
        ],
        "groundTruthAnnotations": [{
            "label": "Travel Record",
            "category": "personalInfo",
            "boundingBox": [0.1, 0.1, 0.9, 0.9],
            "sensitiveText": trv_data
        }],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 9. Health, Medical & Fitness Records (TC-101 to TC-110)
med_scenarios = [
    ("TC-101-PILL-BOTTLE", "Prescription Medication Pharmacy Bottle Label", "Orange pill container label showing patient name, drug name, dosage, and Rx number.", "fixtures/med_pill_bottle.png", "Rx #991829 - Atorvastatin 20mg"),
    ("TC-102-LAB-RESULTS", "Clinical Blood Test Diagnostic Laboratory Report", "Lab report showing patient full name, glucose levels, cholesterol, and physician.", "fixtures/med_lab_results.png", "PATIENT: Jane Doe  GLUCOSE: 104"),
    ("TC-103-PATIENT-WRIST", "Hospital Patient Admission Wristband Barcode", "Hospital wristband showing patient medical record number (MRN), DOB, and allergies.", "fixtures/med_patient_wristband.png", "MRN: 8819204  ALLERGY: Penicillin"),
    ("TC-104-VACCINE-CARD", "CDC Vaccination Immunization Record Card", "Official paper record displaying vaccine lot numbers, dates, and healthcare clinic.", "fixtures/med_vaccine_card.png", "COVID-19 VACCINE  LOT: EL9284"),
    ("TC-105-INSURANCE-CARD", "Health Insurance Member ID Card", "Health benefit card displaying policy number, group number, and copay tiers.", "fixtures/med_insurance_card.png", "MEMBER ID: H-991820491  GRP: 8820"),
    ("TC-106-INTAKE-FORM", "Physical Therapy Medical Intake Questionnaire", "First page of medical history form displaying chronic conditions and emergency contact.", "fixtures/med_intake_form.png", "EMERGENCY CONTACT: (415) 555-0188"),
    ("TC-107-FITNESS-LOG", "Wearable Fitness Tracker Health Metrics Log", "Smartwatch application screen displaying heart rate history and sleep apnea events.", "fixtures/med_fitness_log.png", "AVG HR: 72 BPM  SLEEP: 6h 14m"),
    ("TC-108-DENTAL-INVOICE", "Dental Clinic Treatment Estimate Invoice", "Itemized dental surgery invoice showing patient insurance and procedure codes.", "fixtures/med_dental_invoice.png", "PROCEDURE: D7210 SURGICAL EXTRACTION"),
    ("TC-109-CLINIC-CARD", "Mental Health Clinic Appointment Reminder Card", "Paper appointment card showing therapist name, clinic specialty, and appointment time.", "fixtures/med_clinic_card.png", "APPNT: Dr. Adams, Clinical Psych"),
    ("TC-110-PATHOLOGY-REPORT", "Pathology Biopsy Diagnostic Specimen Header", "Specialist pathology report header displaying specimen ID and diagnostic biopsy code.", "fixtures/med_pathology_report.png", "BIOPSY #SP-2026-9918  SPECIMEN A"),
]

for cid, name, desc, path, med_data in med_scenarios:
    if not os.path.exists(path):
        make_card_img(path, (255, 250, 250), "CONFIDENTIAL MEDICAL & HEALTH RECORD", [
            "HEALTHCARE RECORD: PROTECTED HEALTH INFORMATION (PHI)",
            f"MEDICAL DATA: {med_data}",
            "HIPAA COMPLIANCE WARNING: SENSITIVE HEALTH DATA",
            "REMEDIATION: FULL REDACTION OF PATIENT IDENTITY AND RX"
        ], accent_color=(160, 30, 40))
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": "medical_records",
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "personalInfo",
            "type": "medical_record",
            "minConfidence": 0.85,
            "isDirectExposure": True
        }],
        "expectedSeverity": "critical",
        "minExpectedScore": 70,
        "maxExpectedScore": 100,
        "expectedRecommendations": [
            "Protected Health Information (PHI) must never be shared publicly.",
            "Redact patient names, prescription numbers, and clinic titles."
        ],
        "groundTruthAnnotations": [{
            "label": "Medical Record",
            "category": "personalInfo",
            "boundingBox": [0.15, 0.15, 0.85, 0.85],
            "sensitiveText": med_data
        }],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

# 10. Adversarial & Edge Cases (TC-111 to TC-120)
edge_scenarios = [
    ("TC-111-BLURRED-CARD", "Partially Blurred Credit Card Digits", "Payment card where center digits are blurred but first 4 and last 4 remain legible.", "fixtures/partially_blurred_card.png", "4111 **** **** 1111", "blurred_information", "high", 50, 80),
    ("TC-112-PIXELATED-BADGE", "Pixelated Identity Badge Photo", "Access badge where photo is pixelated but printed name remains legible.", "fixtures/edge_pixelated_badge.png", "NAME: Alex Vance", "employee_badges", "moderate", 25, 60),
    ("TC-113-LOW-QUALITY-GRAIN", "Severely Degraded Grainy Night Photo", "Low-light photograph with heavy ISO noise and grain, no legible text.", "fixtures/low_quality_grain.jpg", None, "low_quality_images", "low", 0, 35),
    ("TC-114-GLARE-REFLECTION", "Sunlight Glare Reflection Across Display Screen", "Monitor screen with intense sunlight reflection making text unreadable.", "fixtures/edge_glare_screen.png", None, "adversarial_edge_cases", "low", 0, 35),
    ("TC-115-OCCLUDED-PLATE", "Partially Occluded License Plate by Bike Rack", "Vehicle plate with two digits obscured by bicycle rack frame.", "fixtures/edge_occluded_plate.png", "7X**890", "vehicle_plates", "moderate", 25, 55),
    ("TC-116-MOVIE-PROP", "Theatrical Movie Prop Identification Card", "Prop ID card stating 'REPUBLIC OF FICTION - PROP ONLY' in corner.", "fixtures/movie_poster_prop.png", None, "false_positive_scenarios", "low", 0, 35),
    ("TC-117-AMBIGUOUS-DIGITS", "Isolated Ambiguous 4-Digit Sequence", "Handwritten scrap of paper showing '8921' with no contextual label.", "fixtures/ambiguous_digits.png", "8921", "ambiguous_cases", "moderate", 20, 45),
    ("TC-118-TRUNCATED-BARCODE", "Truncated Barcode Edge Fragment", "Photograph capturing only the left 20% of an unreadable barcode.", "fixtures/edge_truncated_barcode.png", None, "adversarial_edge_cases", "low", 0, 35),
    ("TC-119-OVEREXPOSED-DOC", "Overexposed Washed-Out Paper Document", "Flash photography artifact rendering paper completely washed out white.", "fixtures/edge_overexposed_doc.png", None, "adversarial_edge_cases", "low", 0, 30),
    ("TC-120-DEGRADED-DETECTOR", "Pipeline Sensor Fault Recovery Simulation", "Test simulating detector subsystem exception to verify fail-safe floor >= 50.", "assets/samples/sample_student_id.png", None, "analysis_failure_scenarios", "moderate", 50, 65),
]

for cid, name, desc, path, text_data, cat, sev, min_s, max_s in edge_scenarios:
    if not os.path.exists(path):
        img = make_img(640, 480, (220, 225, 230))
        d = ImageDraw.Draw(img)
        d.text((80, 200), f"TEST FIXTURE: {name}", fill=(80, 80, 80))
        if text_data:
            d.text((80, 240), f"PARTIAL EVIDENCE: {text_data}", fill=(30, 30, 30))
        save(img, path)
    cases.append({
        "id": cid,
        "name": name,
        "description": desc,
        "category": cat,
        "inputFixtureReference": path,
        "expectedDetections": [{
            "category": "personalInfo",
            "type": cat,
            "minConfidence": 0.50,
            "isDirectExposure": False
        }] if text_data else [],
        "expectedSeverity": sev,
        "minExpectedScore": min_s,
        "maxExpectedScore": max_s,
        "expectedRecommendations": [
            "Handle ambiguous or partially occluded elements with conservative risk bounds."
        ],
        "groundTruthAnnotations": [{
            "label": name,
            "category": cat,
            "boundingBox": [0.2, 0.2, 0.8, 0.8],
            "sensitiveText": text_data
        }] if text_data else [],
        "evaluationCriteria": "score_within_range",
        "createdAt": "2026-10-12T10:00:00.000000",
        "updatedAt": "2026-10-12T10:00:00.000000",
        "version": 1,
        "isEnabled": True
    })

print(f"Total test cases compiled: {len(cases)}")
assert len(cases) == 120

with open('data/test_cases.json', 'w') as f:
    json.dump(cases, f, indent=2)

print(f"Successfully saved 120 test cases to data/test_cases.json!")
