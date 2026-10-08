# Zenith 🛡️

### AI-Powered Privacy & Security Risk Assessment System (v1.0 MVP)

> **"Identify, explain, and prevent privacy leaks before a photo is shared online."**

Zenith is an AI-powered OPSEC (Operational Security) assistant that analyzes photos using multimodal AI models to identify sensitive personal information, evaluate exposure risks, and—crucially—**infer what an attacker could deduce** from visible contextual cues.

---

## 🌟 Key Differentiators

Unlike generic photo editors or basic blur tools, Zenith evaluates photos through the lens of an adversarial threat analyst:
1. **Direct Visibility Analysis**: Detects visible student IDs, badges, license plates, monitors with credentials, barcodes, and house numbers.
2. **Attacker Inference Engine**: Predicts what an OSINT researcher or stalker can deduce:
   - *Visible Student ID* ➔ Inferred: Institution, graduation cohort, age, campus schedules, email reset vectors.
   - *Visible Building / House Number* ➔ Inferred: Domicile coordinates, commuting routines, physical absence risk.
   - *Visible Terminal / Code* ➔ Inferred: Cloud provider IAM accounts, database connection strings, company infrastructure.
3. **Interactive Privacy Shield (Auto-Redact)**: An onboard sandbox that lets users apply solid black censorship bars or Gaussian privacy blur over detected threat regions with 1-tap download.
4. **Offline Simulator & Live Gemini Multimodal Vision**: Fully functional out of the box with 5 bundled realistic threat scenarios, plus seamless integration with Google's latest `gemini-2.5-flash` / `gemini-1.5-flash` multimodal APIs.

---

## 📱 App Architecture & Screens

```
lib/
├── main.dart                               # Riverpod ProviderScope, AppTheme, Entrypoint
├── core/
│   ├── theme/
│   │   ├── app_colors.dart                 # Cyber dark & high-contrast light palettes
│   │   └── app_theme.dart                  # Material 3 typography & glass card styling
│   └── constants/
│       └── app_constants.dart              # Global constants & SharedPreferences keys
├── models/
│   ├── risk_level.dart                     # Low (0-25), Moderate (26-50), High (51-75), Critical (76-100)
│   ├── exposure_category.dart              # Identity, Location, Digital, Personal Data, Transportation
│   ├── detected_element.dart               # Bounding boxes, severity, confidence, OPSEC impact
│   ├── inferred_insight.dart               # Direct observation vs Attacker insight vs Exploitation vector
│   ├── recommendation.dart                 # Actionable mitigation steps
│   ├── privacy_audit_report.dart           # Master assessment model with JSON serialization
│   └── user_settings.dart                  # API key, selected model, sensitivity mode
├── services/
│   ├── gemini_vision_service.dart          # REST client for Gemini Multimodal API with JSON schema
│   ├── mock_analysis_service.dart          # Onboard heuristic simulation engine
│   ├── sample_data_service.dart            # 5 pre-calibrated realistic threat scenarios
│   └── storage_service.dart                # Local audit history & preferences persistence
├── providers/
│   ├── audit_provider.dart                 # Riverpod Notifier for optical ingestion & scan pipeline
│   └── settings_provider.dart              # Riverpod Notifier for user preferences
└── screens/
    ├── splash_screen.dart                  # Animated OPSEC shield radar intro
    ├── home_screen.dart                    # Threat radar status, stats, quick actions, sample carousel
    ├── camera_screen.dart                  # Cyber viewfinder HUD with grid, flash, and photo review
    ├── analysis_screen.dart                # 4-stage laser scanning HUD with progress ticker
    ├── results_screen.dart                 # Circular risk meter, forensic overlay, exposure bars, inferences
    ├── history_screen.dart                 # Saved audit archive with search, filter chips, and dismissal
    ├── settings_screen.dart                # Gemini API key verification, model selection, sensitivity
    └── widgets/
        ├── risk_meter_gauge.dart           # Custom radial score dial with glow sweep
        ├── image_inspection_overlay.dart   # Interactive image viewer with bounding box markers
        ├── auto_redact_preview_modal.dart  # Privacy Shield redaction sandbox with category toggles
        ├── exposure_category_card.dart     # Category-specific % progress bar card
        ├── inference_card.dart             # Attacker threat deduction flowchart card
        ├── detected_element_tile.dart      # Identified threat element card with OPSEC impact
        ├── recommendation_card.dart        # Mitigation checklist with interactive completed check
        ├── cyber_glass_card.dart           # Glassmorphism container with backdrop blur
        └── glowing_scanner_hud.dart        # Real-time laser scanning HUD animation
```

---

## 🎯 5 Built-in Threat Scenarios

Users can instantly test Zenith's threat engine with zero setup:
1. **Student ID Card & Campus Badge** (`88/100 • Critical Risk`): Unredacted university ID containing name, registration number, major, portrait, and 1D barcode.
2. **Airline Boarding Pass & Travel PNR** (`92/100 • Critical Risk`): 6-character PNR booking code, passenger legal name, flight route, and unencrypted 2D Aztec BCBP barcode.
3. **Developer Desk & Credentials Leak** (`96/100 • Critical Risk`): Terminal monitor displaying AWS credentials, production PostgreSQL URI with password, and desk sticky note with Wi-Fi & alarm PIN.
4. **Suburban House & Vehicle Plate** (`72/100 • High Risk`): Residential house number (`742`), municipal street sign (`Evergreen Ter`), and state vehicle license plate.
5. **Mountain Lake Wilderness** (`8/100 • Low Risk`): Clean nature landscape with zero identifiable PII—demonstrating a safe OPSEC rating.

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.16+ (Dart 3.x)
- Chrome (for web) or macOS / Android / iOS device

### Run the App
```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run on Chrome
flutter run -d chrome

# Build for Web
flutter build web
```

### Configure Live Gemini Multimodal AI
1. Obtain an API key from [Google AI Studio](https://aistudio.google.com/).
2. Open Zenith, tap the **Settings** icon (top right).
3. Paste your Gemini API key and tap **Test Connection**.
4. Once verified, all camera captures and gallery uploads will be analyzed live by `gemini-2.5-flash`!

---

## 🛡️ Risk Categories & Scoring
| Risk Level | Score Range | Meaning |
| :--- | :--- | :--- |
| **Low Risk** | 0 – 25 | Minimal exposure. Safe for public social media sharing. |
| **Moderate Risk** | 26 – 50 | Some identifiable details. Crop background or blur before posting. |
| **High Risk** | 51 – 75 | Significant location tracing, facial recognition, or transit vectors. |
| **Critical Risk** | 76 – 100 | Severe OPSEC breach: visible passwords, unblurred IDs, barcodes, or PNRs. |

---

## 📄 License
Zenith Version 1.0 MVP — Designed and developed for privacy and OPSEC protection.
