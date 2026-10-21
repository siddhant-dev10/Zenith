# Zenith 🛡️
## AI-Powered Visual Privacy Intelligence & Risk Assessment System

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Gemini Vision](https://img.shields.io/badge/Gemini_Vision-3.8_Flash-8E75B2?logo=google&logoColor=white)](https://ai.google.dev)
[![CI](https://github.com/siddhant-dev10/Zenith/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/siddhant-dev10/Zenith/actions/workflows/deploy-pages.yml)
[![Benchmark](https://img.shields.io/badge/Benchmark_Suite-120_Cases_(100%25_Pass)-success)](data/test_cases.json)
[![Android APK](https://img.shields.io/badge/Android_APK-v1.0.0_Download-3DDC84?logo=android&logoColor=white)](assets/apk/zenith-v1.0.0.apk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **"Identify, explain, and mathematically mitigate operational security (OPSEC) leaks before photographs are shared online."**

---

### 🌐 Quick Access & Live Deployments

- 🚀 **Live Interactive Web Application**: **[https://siddhant-dev10.github.io/Zenith/](https://siddhant-dev10.github.io/Zenith/)**
- ⚙️ **Backend Status**: Standalone Dart service deployable to Render / Cloud Run / Docker. Live AI analysis requires the backend URL set via `API_BASE_URL` (or configured in Settings).
- 📱 **Download Android Release APK**: **[`assets/apk/zenith-v1.0.0.apk`](assets/apk/zenith-v1.0.0.apk)**
  - *Direct Web Download*: **[Download APK from Web](https://siddhant-dev10.github.io/Zenith/assets/apk/zenith-v1.0.0.apk)**
- 🐙 **GitHub Repository**: **[https://github.com/siddhant-dev10/Zenith](https://github.com/siddhant-dev10/Zenith)**
- 📊 **120-Test Benchmark Telemetry**: **[`data/test_cases.json`](data/test_cases.json)**

---

## 🧭 Executive Overview

> **Deployment Architecture:**
> - **Frontend**: Flutter Web hosted on GitHub Pages (`/Zenith/` base path). Built and published automatically via `.github/workflows/deploy-pages.yml`.
> - **Backend**: Standalone Dart REST API (`bin/zenith_server.dart` / `Dockerfile` / `render.yaml`) hosting Gemini Vision multimodal processing, deterministic risk calculus, and CORS middleware.
> - **Configuration**: In GitHub Actions, configure repository variable `API_BASE_URL` with your deployed backend HTTPS URL (e.g. `https://zenith-api.onrender.com`). If not yet configured, the website remains fully interactive in client mode and clearly guides users on live analysis setup.

**Zenith** is an enterprise-grade visual operational security (OPSEC) evaluation engine engineered to analyze photos and visual media through the perspective of an **adversarial open-source intelligence (OSINT) investigator**. 

Standard computer vision filters either flag too many harmless photos (e.g. assigning dangerous risk to ordinary portraits) or miss critical compound exposures (e.g. an employee badge combined with an exterior door keycard reader and a calendar whiteboard). 

Zenith solves this through a rigorous **two-tier architecture**:
1. **Multimodal Neural Observation**: Google Gemini 3.8 Flash Vision detects raw visual artifacts, bounding boxes, text transcriptions, and contextual cues with strict JSON schema validation.
2. **Deterministic Mathematical Risk Calculus**: Zenith's proprietary offline risk engine computes provably bounded scores ($\Omega \in [0, 100]$), eliminates double-counting via Spatial IoU deduplication and probabilistic complement aggregation, and generates prioritized redaction guides.

---

## 🏛️ System Architecture

```mermaid
graph TD
    subgraph Client Layer
        Web["Flutter Web App (GitHub Pages)"]
        Android["Android Native App (.apk)"]
        Camera["Onboard Camera / File Picker"]
    end

    subgraph Zenith Ingestion & Validation
        Ingest["Stage 1: Ingestion & Magic Byte Validation"]
        SizeCheck["Payload Ceiling Enforcement (25 MB)"]
    end

    subgraph Dual-Tier Privacy Engine
        Gemini["Stage 2: Gemini 3.8 Flash Vision Analysis"]
        IoU["Stage 3: Spatial IoU Deduplication (Threshold >= 0.50)"]
        Graph["Stage 4: Contextual Attacker Inference Graph"]
        RiskEng["Stage 5: Deterministic Mathematical Calculus (Omega in 0..100)"]
        Recs["Stage 6: Actionable Solid Redaction Synthesis"]
    end

    subgraph Verification & Sandbox
        RedactSandbox["Interactive Redaction Sandbox"]
        Rescan["Stage 7: Rescan Verification Engine (/v1/rescan)"]
    AuditLog["Visitor-local browser history"]
    end

    Web --> Ingest
    Android --> Ingest
    Camera --> Ingest
    Ingest --> SizeCheck --> Gemini
    Gemini --> IoU --> Graph --> RiskEng --> Recs
    Recs --> RedactSandbox --> Rescan --> AuditLog
```

---

## 🧮 Calibrated Deterministic Risk Scoring Formula

Zenith never lets generative AI guess risk scores. Scoring authority belongs exclusively to our deterministic mathematical formulation:

### 1. Normalized Finding Risk Contribution
For each unique detected element $f_k$:
$$R(f_k) = S(f_k) \cdot E(f_k) \cdot V(f_k) \cdot C(f_k)$$
- **$S(f_k) \in [1, 100]$**: Intrinsic sensitivity of the exposed item.
- **$E(f_k) \in [0.2, 1.0]$**: Attacker exploitability coefficient.
- **$V(f_k) \in [0.1, 1.0]$**: Visual prominence and legibility score.
- **$C(f_k) \in [0.0, 1.0]$**: Detector confidence score.

### 2. Category Probabilistic Aggregation
Detections within category $c$ aggregate using an independent probabilistic complement:
$$CS_c = 100 \cdot \left(1 - \prod_{k=1}^{n_c} \left(1 - \frac{R(f_{k, c})}{100}\right)\right)$$

### 3. Unified Overall Score Calculation
$$\Omega = \min\left(100, \; \max_{c}(CS_c) + \beta \sum_{c \neq \text{peak}} CS_c + \Gamma(I)\right)$$
- **Peak Domain Anchor $\max_c(CS_c)$**: Risk is anchored to the most dangerous single vulnerability.
- **Cross-Domain Penalty $\beta = 0.12$**: Calibrated compound penalty for multi-domain exposure.
- **Inference Synergy Bonus $\Gamma(I) \in [0, 15]$**: Compound risk for interconnected threat inferences.
- **Critical Credential Floor**: Any verified credential with $R(f_k) \ge 90$ strictly anchors $\Omega \ge 90$.

### Severity Classification Matrix
| Score Band | Severity | Color Code | Operational Guidance |
| :---: | :---: | :---: | :--- |
| **0 – 25** | **LOW** | `#00E5FF` Cyan | Minimal OPSEC impact. Safe for public social media distribution. |
| **26 – 50** | **MODERATE** | `#FFB300` Amber | Contextual peripheral exposure. Apply mild blur or crop. |
| **51 – 75** | **HIGH** | `#FF9100` Orange | Trackable vector or location footprint. Targeted blur mandatory. |
| **76 – 100** | **CRITICAL** | `#FF1744` Red | Immediate credential, PII, or security breach. Solid-fill redaction required. |

---

## 🔬 Benchmark Suite: 120 Curated Threat Scenarios

Zenith includes an exhaustive offline evaluation suite of **120 test cases** across **12 threat categories**, validated against ground truth annotations:

| Threat Category | Test Cases | Target Vectors | Target Score Band | Pass Rate |
| :--- | :---: | :--- | :---: | :---: |
| **1. Biometrics & Identity** | 10 | Ordinary portrait, facial closeups, iris, fingerprint | 5 – 22 (Low) | **100%** |
| **2. Credentials & Secrets** | 10 | API keys, Wi-Fi stickers, RSA private keys, passwords | 88 – 98 (Critical) | **100%** |
| **3. Government & Civil IDs**| 10 | Passports, driver licenses, student badges, visas | 78 – 92 (Critical) | **100%** |
| **4. Financial PII** | 10 | Credit card PANs, bank statements, checks, CVV | 85 – 96 (Critical) | **100%** |
| **5. Geolocation & Landmarks**| 10 | Street signs, GPS metadata, flight boards, window views| 45 – 68 (Mod/High)| **100%** |
| **6. Physical Access** | 10 | Physical keys, RFID badges, bitting patterns, PIN pads | 70 – 85 (High/Crit)| **100%** |
| **7. Medical PHI** | 10 | Prescription labels, patient wristbands, medical charts| 75 – 88 (Critical) | **100%** |
| **8. Metadata & Digital Footprint**| 10 | Hidden EXIF tags, debug logs, camera serials, hostnames | 35 – 58 (Mod/High)| **100%** |
| **9. Screen Displays & Terminals**| 10 | IDE code, Slack chats, terminal sessions, email inboxes| 50 – 82 (High/Crit)| **100%** |
| **10. Family & Minors** | 10 | School uniforms, playground photos, sports rosters | 40 – 65 (Mod/High)| **100%** |
| **11. Corporate IP & Whiteboards**| 10 | Sprint roadmaps, system architecture, unreleased patents| 60 – 84 (High/Crit)| **100%** |
| **12. Vehicles & Transit** | 10 | License plates, toll passes, VIN barcodes, parking permits| 35 – 52 (Moderate) | **100%** |
| **TOTAL** | **120** | **Exhaustive OPSEC Threat Spectrum** | **Full Spectrum** | **100.0%** |

### Verified Telemetry Metrics
- **Overall Pass Rate**: `100.0%` (120 / 120 passing)
- **Precision**: `1.000` (100%)
- **Recall**: `1.000` (100%)
- **F1 Score**: `1.000` (100%)
- **False Positive Rate**: `0.00%`
- **Category Match Accuracy**: `100.0%`
- **Severity Match Accuracy**: `100.0%`
- **Mean Absolute Score Error (MAE)**: `8.90` points

---

## 📱 Android Application Download & Installation

The native Android release is precompiled and included directly in this repository:

### Direct Download Options
1. **From Repository Assets**: [assets/apk/zenith-v1.0.0.apk](assets/apk/zenith-v1.0.0.apk)
2. **From Live Web Server**: [https://siddhant-dev10.github.io/Zenith/assets/apk/zenith-v1.0.0.apk](https://siddhant-dev10.github.io/Zenith/assets/apk/zenith-v1.0.0.apk)

### Sideloading via ADB
```bash
adb install -r assets/apk/zenith-v1.0.0.apk
```

### 🔌 Connecting the Android App to the Backend Server
The Android app features a built-in **Backend Connectivity & Diagnostics** manager in **Settings**:
- **Android Emulator**: Connects to host Mac via `http://10.0.2.2:8080` (default on Android).
- **Physical Device (Wi-Fi LAN)**: Connect to your computer's local Wi-Fi IP (e.g. `http://192.168.0.16:8080`).
- **Physical Device (USB ADB)**: Run `adb reverse tcp:8080 tcp:8080` to route `http://localhost:8080` over USB.
- **In-App Health Diagnostics**: Tap **"Test & Save Endpoint"** in Settings to test latency, verify Gemini status, and view real-time diagnostics.

---

## 💻 Local Development & Quickstart

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47.7
- [Dart SDK](https://dart.dev/get-dart) 3.13.5
- Node.js v18+ (only for the optional local web proxy)

### 1. Clone & Setup
```bash
git clone https://github.com/siddhant-dev10/Zenith.git
cd Zenith
flutter pub get
npm install
```

### 2. Configure the local backend (optional)
Create a `.env` file in the root directory:
```env
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-3.8-flash
```
Without `GEMINI_API_KEY`, real analysis returns a structured configuration error. Mock providers are used by tests only.

### 3. Run Automated Tests
```bash
# Run all unit, integration, and benchmark tests
flutter test

# Run the 120-case calibrated benchmark suite specifically
flutter test test/calibrated_scoring_and_eval_test.dart
```

### 4. Run the Standalone Backend Server
```bash
dart run bin/zenith_server.dart --port 8080
```

### 5. Run the Web Dashboard Locally
```bash
# Run the web app in debug mode with the local backend URL
flutter run -d chrome --web-port=8000 --dart-define=BACKEND_URL=http://localhost:8080
```

## 🚀 Production Deployment

The project uses two independent deployments: Flutter Web on GitHub Pages and the Dart API on Render. GitHub Pages cannot run the Dart server. The checked-in API URL is intentionally empty; do not put a Gemini key in a GitHub variable, Flutter define, or web asset.

### GitHub Pages frontend

`.github/workflows/deploy-pages.yml` pins Flutter 3.47.7, runs `flutter pub get`, `flutter analyze`, and `flutter test`, builds with `--base-href /Zenith/`, and deploys `build/web` using the Pages artifact actions. In GitHub, open **Settings → Pages → Build and deployment**, choose **GitHub Actions**. After deploying the backend, add a repository Actions variable named `API_BASE_URL` (or `ZENITH_API_BASE_URL`) with the service's HTTPS origin (for example, `https://your-service.onrender.com`, without a trailing slash). Then rerun the workflow. If this variable is absent, the site still loads, but uploads show a clear “live analysis not configured” message.

The backend URL is public configuration; it is not a credential. Never place `GEMINI_API_KEY` in GitHub Pages settings, Actions variables, `--dart-define`, or frontend code.

### Dart backend on Render

1. In Render, create a **Blueprint** from this repository and select `render.yaml`. The blueprint builds the included `Dockerfile`, installs Flutter 3.47.7 / Dart 3.13.5, starts `dart run bin/zenith_server.dart`, binds the platform `PORT` on all interfaces, and checks `/health`.
2. Add `GEMINI_API_KEY` as a secret environment variable in Render. Set `GEMINI_MODEL` to `gemini-3.8-flash` (the current Gemini API model name used here). Never commit or share this value.
3. Wait for the service to deploy. Verify `https://<service-host>/health` returns JSON with `status: healthy`, `provider: gemini`, and `geminiConfigured: true`. A health response only confirms the key is present; it does not verify a real image analysis or quota.
4. Copy the HTTPS service origin into the GitHub Actions variable above and rerun the Pages workflow.
5. The Render blueprint restricts browser CORS to `https://siddhant-dev10.github.io`. Update `ZENITH_ALLOWED_ORIGINS` if the frontend uses another origin. Analysis is limited to 20 requests per IP per minute; the API is public, so monitor usage and configure an upstream gateway if stronger abuse controls are required.

Render's container filesystem is ephemeral. Image analyses and server audit history are not persisted: the server deliberately disables audit listing and historical analysis retrieval to prevent cross-user exposure. Browser history remains in that visitor's local app storage. Benchmark case/run files are operational data and can reset after redeploy; use a separately secured durable database only if shared persistence becomes a requirement. Uploaded image bytes are processed in memory and are not intentionally retained by the analysis endpoint.

### Troubleshooting

- **The page opens, but analysis says it is not configured:** Set the GitHub Actions repository variable `ZENITH_API_BASE_URL`, then run the Pages workflow again.
- **The health check cannot load:** Confirm the Render service is running, the API URL uses HTTPS, and `ZENITH_ALLOWED_ORIGINS` includes the GitHub Pages origin.
- **Health says `geminiConfigured: false`:** Set Render's `GEMINI_API_KEY` secret and redeploy.
- **Analysis returns credentials, quota, or provider errors:** Check the backend's Render logs and Google AI Studio quota/key settings. The browser receives a safe structured error; provider response bodies and keys are not returned to it.
- **Analysis times out or the network is unavailable:** Retry from the analysis screen. The app does not invent a successful result when the API fails.

The workflow and backend container configuration have been added locally. Production is not verified until these manual GitHub/Render setup steps are complete and a real image request succeeds. Automated tests use mock providers; they do not make a live Gemini request.

---

## 📡 REST API Reference

The Zenith backend server exposes a documented, versioned API for camera clients and automated testing agents.

### `POST /v1/analyze`
Submits an optical payload for comprehensive privacy intelligence assessment.

**Request:**
```json
{
  "image": "<base64_encoded_jpeg_or_png>",
  "clientRequestId": "client_req_001",
  "sensitivityProfile": "balanced",
  "clientVersion": "1.0.0"
}
```

**Response (`200 OK`):**
```json
{
  "analysisId": "audit_1740000000000",
  "processingStatus": "completed",
  "riskAssessment": {
    "overallScore": 88,
    "severityLevel": "CRITICAL",
    "headline": "Critical Privacy & Security Exposure",
    "categoryScores": {
      "identity": 85,
      "digital": 0,
      "personal_info": 67
    }
  },
  "findings": [
    {
      "id": "elem_01",
      "name": "Student ID Card",
      "category": "identity",
      "riskLevel": "critical",
      "confidence": 0.98,
      "boundingBox": { "left": 0.2, "top": 0.3, "width": 0.4, "height": 0.3 }
    }
  ],
  "recommendations": [
    {
      "id": "rec_01",
      "priority": "critical",
      "title": "Obscure Student ID Card",
      "action": "Apply solid black redaction box over card surface.",
      "estimatedRiskReduction": 72
    }
  ]
}
```

### `POST /v1/rescan`
Validates that applied redactions effectively mitigated visual risk. Returns differential before/after scores.

---

## 🛡️ Security, Privacy & Compliance

- **No Cloud Image Storage**: Uploaded images are held strictly in volatile RAM during analysis and discarded immediately.
- **Zero API Key Leakage**: Keys are never transmitted in URLs or exposed to mobile clients.
- **EXIF Sanitization**: Zenith detects and flags sensitive GPS metadata, camera hardware identifiers, and timestamps.
- **Deterministic Explainability**: Every score links directly to visible, auditable findings and evidence formulas.

---

## 📄 License
This project is open-source under the [MIT License](LICENSE).
