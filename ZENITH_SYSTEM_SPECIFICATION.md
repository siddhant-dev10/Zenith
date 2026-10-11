# ZENITH SYSTEM SPECIFICATION
## Comprehensive Architectural Blueprint, AI Pipeline, Risk-Scoring Methodology, and Engineering Roadmap

**Document Version:** 1.0.0-PROD  
**Classification:** Engineering Specification / System Architecture  
**Status:** Approved for Implementation  
**Primary Author:** Principal AI Systems Architect & Cybersecurity Lead  
**Target Systems:** Zenith Privacy Intelligence Core & API Service  
**Client Consumers:** Zenith Mobile Camera Client (iOS/Android), Zenith Security Web Console  

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Product Vision and Scope](#2-product-vision-and-scope)
3. [Problem Definition & Threat Landscape](#3-problem-definition--threat-landscape)
4. [Existing Repository Audit & Technical Baseline](#4-existing-repository-audit--technical-baseline)
5. [System Requirements](#5-system-requirements)
6. [Functional Requirements](#6-functional-requirements)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [System Architecture](#8-system-architecture)
9. [AI and Computer Vision Pipeline](#9-ai-and-computer-vision-pipeline)
10. [Structured Data Schemas & Contracts](#10-structured-data-schemas--contracts)
11. [Privacy Risk Scoring Methodology](#11-privacy-risk-scoring-methodology)
12. [Attacker-Perspective Privacy Intelligence](#12-attacker-perspective-privacy-intelligence)
13. [Test Case & Evaluation Framework](#13-test-case--evaluation-framework)
14. [Mitigation and Recommendation Engine](#14-mitigation-and-recommendation-engine)
15. [API Specification & Integration Contract](#15-api-specification--integration-contract)
16. [Security and Privacy by Design Architecture](#16-security-and-privacy-by-design-architecture)
17. [Zenith System UX & Design System](#17-zenith-system-ux--design-system)
18. [Screen-by-Screen System Specifications](#18-screen-by-screen-system-specifications)
19. [Technical Stack and Project Structure](#19-technical-stack-and-project-structure)
20. [Data Models and State Management](#20-data-models-and-state-management)
21. [Error Handling, Fallbacks, and Reliability](#21-error-handling-fallbacks-and-reliability)
22. [Testing Strategy & Quality Assurance](#22-testing-strategy--quality-assurance)
23. [Team Responsibilities & Organizational Boundaries](#23-team-responsibilities--organizational-boundaries)
24. [Phased Implementation Roadmap](#24-phased-implementation-roadmap)
25. [System Acceptance Criteria](#25-system-acceptance-criteria)
26. [Known Limitations and Open Research Questions](#26-known-limitations-and-open-research-questions)
27. [Future Expansion & Evolution Vectors](#27-future-expansion--evolution-vectors)
28. [Glossary of Terms](#28-glossary-of-terms)

---

## 1. Executive Summary

### 1.1 Document Purpose
This specification establishes the authoritative system architecture, computational pipeline, mathematical risk-scoring formulation, and client-integration interfaces for **Zenith**. Zenith is an autonomous privacy intelligence and operational security (OPSEC) analysis system engineered to detect, classify, evaluate, and mitigate sensitive data exposure in visual media (photographs and, in future iterations, video streams). 

This document defines the backend analysis system and internal research console. It enforces a strict architectural boundary between the core intelligence engine and external capture clients (such as the independent camera application developed by Team Member 1).

### 1.2 System Essence
Traditional privacy tooling operates reactively and crudely: basic photo editors offer manual pixelation or black boxes without contextual awareness, while simple face blurrers overlook high-leverage identity anchors such as employee badges, vehicle plates, reflections, Wi-Fi credentials, and ambient location cues. 

Zenith operates through the analytical lens of an **adversarial threat investigator** or **open-source intelligence (OSINT) specialist**. It answers a fundamental security question:

$$\text{"If an unauthorized adversary inspects this visual asset, what facts can they directly extract, what routines can they reliably deduce, and what exploits can they execute?"}$$

By synthesizing deterministic computer vision (EXIF parsing, barcode/QR decoding, optical character recognition), multimodal foundation models (Gemini Vision), an explainable multi-variable risk scoring calculus, and an inference deduction graph, Zenith delivers actionable, mathematically grounded privacy assessments before visual media is shared online.

---

## 2. Product Vision and Scope

### 2.1 Core Mission
To eliminate accidental visual operational security breaches by providing instant, explainable, and provably calibrated privacy risk assessments and automated remediation recommendations across all visual publishing workflows.

### 2.2 System Dimensions of Exposure
Zenith evaluates exposure across two distinct, complementary dimensions:

```mermaid
graph TD
    VisualPayload["Ingested Optical Payload (Image + EXIF)"] --> DirectExposure["Dimension A: Direct Exposure"]
    VisualPayload --> InferentialExposure["Dimension B: Inferential Exposure"]
    
    subgraph Direct ["Direct Exposure (Observable Evidence)"]
        DirectExposure --> D1["PII & Biometrics (Faces, Names)"]
        DirectExposure --> D2["Credentials (API Keys, Passwords, PINs)"]
        DirectExposure --> D3["Identifiers (Badges, Plates, Barcodes)"]
        DirectExposure --> D4["Physical Coordinates (House Nos, EXIF GPS)"]
    end
    
    subgraph Inferential ["Inferential Exposure (Contextual Deduction)"]
        InferentialExposure --> I1["Institutional Affiliation (Logo + Badge Style)"]
        InferentialExposure --> I2["Temporal Routines (Timetable + Sun Angle)"]
        InferentialExposure --> I3["Socioeconomic Profile (Interior Decor + Assets)"]
        InferentialExposure --> I4["Absence & Vacancy Risk (Airport PNR + Date)"]
    end
    
    Direct --> PrivacyEngine["Zenith Privacy Intelligence Engine"]
    Inferential --> PrivacyEngine
```

#### A. Direct Exposure
Unambiguous, directly observable, or machine-extractable data points present in the image pixels or file header metadata.
- **Physical Identity Documents:** Passports, driver's licenses, student identity cards, corporate badges, health insurance cards.
- **Digital Infrastructure & Credentials:** Passwords on sticky notes, terminal windows displaying cloud API tokens, unmasked database connection strings, authentication QR codes.
- **Direct Financial Data:** Payment card primary account numbers (PAN), bank routing numbers, utility billing mailers.
- **Machine-Readable Codes:** 1D barcodes (Code 128, UPC, EAN), 2D matrix codes (QR codes, Aztec boarding passes, Data Matrix).
- **Exact Geospatial Identifiers:** GPS coordinates embedded in EXIF tags, municipal street names, distinct house address placards, vehicle registration plates.

#### B. Inferential Exposure
Contextual deductions, secondary facts, or behavioural patterns that a rational observer can synthesize by cross-referencing multiple disparate, individually non-critical clues.
- **Workplace & Institutional Affiliation:** An unreadable badge silhouette matching a known corporate lanyard color, paired with distinctive architectural glass or campus landmarks.
- **Living Conditions & Domicile Pinpointing:** An outdoor balcony view combined with skyline landmarks, sunlight azimuth, and transit line visibility allowing triangular geolocation.
- **Temporal Routines & Absence Vectors:** A photograph of an airport terminal or boarding pass revealing departure dates, alerting physical intruders to residential vacancy.
- **Social Graph & Hierarchy:** Identification of coworker seating arrangements, organizational hierarchy charts on whiteboard reflections, or familial relationships via background framed portraits.

### 2.3 Epistemic Distinctions: Evidence vs. Inference vs. Speculation
To maintain trust and prevent hallucinated risk assessments, Zenith enforces strict epistemic criteria:

| Epistemic State | Formal Definition | System Verification Rule | Actionability |
| :--- | :--- | :--- | :--- |
| **Evidence (Fact)** | Directly measurable visual tokens, high-confidence OCR text strings, or decoded binary barcodes. | IoU $\ge 0.5$, OCR confidence $\ge 0.85$, or exact regex match. | Direct bounding box markup; immediate redaction candidate. |
| **Inference (Deduction)** | Logically bounded deduction derived from two or more correlated pieces of Evidence via established threat heuristics. | Derived from at least one verified Evidence anchor with an explicit causal path. | Attacker threat profile generation; contextual risk weighting. |
| **Confidence (Metric)** | Statistical probability that a detection or relationship is authentic, bounded between $0.0$ and $1.0$. | Algorithmic ensemble agreement score (CV detector + Gemini Vision). | Threshold filter ($\ge 0.60$ for reporting). |
| **Speculation (Unverified)** | Plausible but unsubstantiated conjectures lacking sufficient visual grounding. | Excluded from the final report. Never presented as a finding. | Dropped or flagged as "Uncertain Possibility" ($C < 0.40$). |

---

## 3. Problem Definition & Threat Landscape

### 3.1 The Modern Visual Attack Surface
Smartphones capture high-resolution images (12 to 48+ megapixels) containing micro-details invisible on small phone screens but effortlessly extractable by adversaries using desktop monitors, zooming tools, and computer vision models.

```
+-----------------------------------------------------------------------------------+
|                              THREAT VECTOR MATRIX                                 |
+-------------------+--------------------------------+------------------------------+
| Attack Vector     | Primary Visual Exploits        | Real-World Impact            |
+-------------------+--------------------------------+------------------------------+
| OSINT Geolocation | Sun shadow, window view, flora | Stalking, physical burglary, |
|                   | street furniture, architecture | doxxing residential address  |
+-------------------+--------------------------------+------------------------------+
| Identity Theft    | Student ID, medical bracelet,  | Fraudulent account creation, |
|                   | government card, mail envelope | SIM swapping, social eng.    |
+-------------------+--------------------------------+------------------------------+
| Infrastructure    | Laptop screen, whiteboards,    | Corporate breach, lateral    |
| Compromise        | sticky notes, badge barcodes   | network pivoting, API theft  |
+-------------------+--------------------------------+------------------------------+
| Travel Stalking   | Boarding pass PNR, baggage tag | Flight cancellation, itinerary|
|                   | calendar screen, train ticket  | tracking, home vacancy alert |
+-------------------+--------------------------------+------------------------------+
| Physical Access   | Keyway profile, badge barcode, | Physical lock bumping, card  |
| Cloning           | RFID serial number, parking tag| cloning, perimeter breach    |
+-------------------+--------------------------------+------------------------------+
```

---

## 4. Existing Repository Audit & Technical Baseline

### 4.1 Codebase Inventory
An exhaustive audit of `/Users/sidh._./Zenith` was conducted against the physical workspace and Git commit history (`master` branch, commits `85e33d1` and `67fe005`).

```
ZENITH WORKSPACE STRUCTURE (BASELINE AUDIT)
├── .dart_tool/                         [Generated Dart toolchain configuration]
├── .flutter-plugins-dependencies       [Plugin resolution map]
├── .git/                               [Git revision tree: 2 commits recorded]
├── analysis_options.yaml               [Standard flutter_lints rule configuration]
├── assets/
│   └── samples/                        [5 Synthetic benchmark test images]
│       ├── sample_boarding_pass.png    [20.7 KB: Aztec barcode, PNR, name]
│       ├── sample_clean_landscape.png  [6.0 KB: Mountain lake, zero PII baseline]
│       ├── sample_street_house.png     [7.5 KB: House '742', street sign, plate]
│       ├── sample_student_id.png       [18.6 KB: Univ badge, 1D barcode, portrait]
│       └── sample_workstation_screen.png[32.4 KB: Terminal AWS keys, DB URI]
├── lib/
│   ├── main.dart                       [Flutter entrypoint: Riverpod ProviderScope]
│   ├── core/
│   │   ├── constants/app_constants.dart[Keys, defaults: gemini-2.5-flash]
│   │   └── theme/
│   │       ├── app_colors.dart         [Palette: Cyan/Dark cyber tokens, risks]
│   │       └── app_theme.dart          [Material 3 Dark/Light glassmorphism]
│   ├── models/
│   │   ├── detected_element.dart       [BoundingBox, DetectedElement classes]
│   │   ├── exposure_category.dart      [5 Enums: identity, location, digital...]
│   │   ├── inferred_insight.dart       [Threat deduction structure]
│   │   ├── privacy_audit_report.dart   [Master audit model + JSON serialization]
│   │   ├── recommendation.dart         [Mitigation action model]
│   │   ├── risk_level.dart             [4 Enums: low, moderate, high, critical]
│   │   └── user_settings.dart          [Preferences & API key state]
│   ├── providers/
│   │   ├── audit_provider.dart         [StateNotifier: 4-stage pipeline orchestration]
│   │   └── settings_provider.dart      [User settings notifier]
│   ├── screens/
│   │   ├── analysis_screen.dart        [Scanning HUD animation screen]
│   │   ├── camera_screen.dart          [Camera viewfinder & capture screen]
│   │   ├── history_screen.dart         [Saved audits listing screen]
│   │   ├── home_screen.dart            [OPSEC dashboard & sample carousel]
│   │   ├── results_screen.dart         [Audit report detail display screen]
│   │   ├── settings_screen.dart        [API key config & model picker screen]
│   │   ├── splash_screen.dart          [Branded radar startup screen]
│   │   └── widgets/                    [UI presentation components]
│   └── services/
│       ├── gemini_vision_service.dart  [Direct REST call to Gemini generateContent]
│       ├── mock_analysis_service.dart  [Local heuristic fallback generator]
│       ├── sample_data_service.dart    [Static scenario fixtures for 5 samples]
│       └── storage_service.dart        [SharedPreferences persistence]
├── pubspec.yaml                        [Flutter 3.16+ / Dart ^3.13.4 dependencies]
└── test/
    ├── risk_calculator_test.dart       [Unit tests verifying enums & sample data]
    └── widget_test.dart                [Smoke tests for HomeScreen & ResultsScreen]
```

### 4.2 Architectural Baseline & Critical Deficiencies

```
+----------------------------------------------------------------------------------------------------+
|                                  CURRENT VS. TARGET ARCHITECTURE                                    |
+------------------------------+------------------------------------+--------------------------------+
| Dimension                    | Current Baseline (Audit Fact)      | Target System Specification    |
+------------------------------+------------------------------------+--------------------------------+
| Architectural Paradigm       | Monolithic Client-Side Flutter App | Decoupled Intelligence API     |
|                              | (UI, capture, AI in one binary)    | + Headless Analysis Service    |
+------------------------------+------------------------------------+--------------------------------+
| Secret Security              | API Key entered in Client UI;      | Server-side Secret Vault;      |
|                              | Client calls Google directly       | Zero client-held AI secrets    |
+------------------------------+------------------------------------+--------------------------------+
| Risk Scoring Calculus        | Delegated entirely to Gemini LLM   | Deterministic, multi-variable  |
|                              | prompt (`"overallScore": 74`)      | mathematical scoring engine    |
+------------------------------+------------------------------------+--------------------------------+
| Deterministic CV / Tooling   | None (No OCR, No barcode decoder,  | Tesseract/EasyOCR, Pyzbar/ZBar |
|                              | No EXIF reader in execution tree)  | Piexif/ExifTool pipeline       |
+------------------------------+------------------------------------+--------------------------------+
| Inference Engine             | Free-form text prompt in LLM call  | Formal Evidence Graph with     |
|                              | without deterministic verification | validation heuristics          |
+------------------------------+------------------------------------+--------------------------------+
| Evaluation & Ground Truth    | 5 static hardcoded scenarios in    | Automated benchmark suite with |
|                              | Dart file (`sample_data_service`)  | metrics (ECE, F1, MAE)         |
+------------------------------+------------------------------------+--------------------------------+
```

#### Detailed Findings on Current Code:
1. **Gemini Vision Integration (`gemini_vision_service.dart`):**
   - Implements a direct REST call to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`.
   - Uses `gemini-2.5-flash` by default with `temperature: 0.2` and `responseMimeType: application/json`.
   - Passes base64 encoded image directly in JSON payload.
   - **Vulnerability:** The client app holds the secret API key in plaintext SharedPreferences (`keyApiKey`). If distributed to external users, this key can be extracted via reverse-engineering or memory dumps.
   - **Defect:** Prompt asks Gemini to directly decide the `overallScore` (0-100) and `categoryScores`. Gemini frequently produces uncalibrated, fluctuating scores for identical images across minor prompt variations.
2. **Scoring Logic (`risk_level.dart`, `risk_calculator_test.dart`):**
   - The threshold bands are defined: Low (0-25), Moderate (26-50), High (51-75), Critical (76-100).
   - These boundaries are well-chosen and aligned with industry severity distributions (CVSS/OWASP). They will be preserved and formalized mathematically.
3. **Domain Categories (`exposure_category.dart`):**
   - Defines 5 exposure domains: `identity`, `location`, `digital`, `personalInfo`, `transportation`.
   - These 5 categories are conceptually robust and match real-world OPSEC threat modeling. In this specification, we formalize them into standardized categories:
     1. Identity Exposure ($C_1$)
     2. Location Exposure ($C_2$)
     3. Digital Security Exposure ($C_3$)
     4. Personal Information Exposure ($C_4$)
     5. Physical / Transportation Security Exposure ($C_5$)
4. **Data Models (`detected_element.dart`, `inferred_insight.dart`):**
   - `BoundingBox` uses normalized relative coordinates (`left`, `top`, `width`, `height` in $[0.0, 1.0]$). This is clean, resolution-independent, and will be retained as the universal coordinate standard.
   - Models serialize to/from JSON cleanly.

---

## 5. System Requirements

### 5.1 Architecture Independence Principle
Zenith Core must operate as an autonomous, network-accessible service. It must have **zero compile-time dependencies** on Flutter, Dart, Android SDK, or iOS UIKit. The camera application developed by Team Member 1 is strictly an external consumer that interacts solely via Zenith's REST/WebSocket API.

### 5.2 Operating Boundaries
1. **Stateless Processing:** Zenith processes visual payloads in-memory. By default, submitted images are erased immediately upon response generation.
2. **Defensive Stance:** Zenith evaluates visual assets defensively. It never connects to external social media scrapers, facial recognition search engines (e.g., PimEyes), or public records databases to unmask individuals.

---

## 6. Functional Requirements

| ID | Requirement Name | Description | Priority |
| :--- | :--- | :--- | :--- |
| **FR-01** | Multimodal Image Ingestion | Ingest JPEG, PNG, WebP, and HEIC payloads up to 25 MB via REST API. | P0 (Critical) |
| **FR-02** | Metadata (EXIF) Extraction | Parse, decode, and assess all EXIF, TIFF, GPS, and XMP headers. | P0 (Critical) |
| **FR-03** | Barcode & Matrix Decoding | Deterministically detect and decode 1D (Code 128, UPC) and 2D (QR, Aztec) codes. | P0 (Critical) |
| **FR-04** | High-Accuracy Text Extraction | Perform OCR to extract text from badges, screens, documents, and signs. | P0 (Critical) |
| **FR-05** | Sensitive Pattern Identification | Execute deterministic regex tokenizers for PNR, SSN, API keys, emails, URLs. | P0 (Critical) |
| **FR-06** | Multimodal Contextual Analysis | Query Gemini Vision with structured JSON constraints for semantic threat detection.| P0 (Critical) |
| **FR-07** | Attacker Inference Deduction | Map detected elements into compound deductions (routines, organizational affiliation).| P0 (Critical) |
| **FR-08** | Deterministic Risk Scoring | Calculate mathematical scores ($0-100$) using multi-variable weighting formulas. | P0 (Critical) |
| **FR-09** | Category-Specific Scoring | Compute isolated sub-scores ($0-100$) for Identity, Location, Digital, Personal, Phys. | P0 (Critical) |
| **FR-10** | Deduplication & Clustering | Merge overlapping detections using spatial IoU ($\ge 0.5$) and semantic grouping. | P1 (High) |
| **FR-11** | Mitigation Checklist Generation| Generate prioritised, item-specific remediation actions (blur, crop, scrub). | P0 (Critical) |
| **FR-12** | Redaction Coordinate Mapping | Provide exact normalized bounding boxes for all detected threat targets. | P0 (Critical) |
| **FR-13** | Verification Rescan Interface | Allow re-submission of redacted images to verify risk reduction deltas. | P2 (Medium) |
| **FR-14** | Benchmark Evaluation Harness | Execute automated regression testing against ground-truth image datasets. | P1 (High) |

---

## 7. Non-Functional Requirements

### 7.1 Performance & Latency Budgets
- **Synchronous Endpoint Latency ($P_{95}$):** Complete end-to-end analysis within $\le 3,500\text{ ms}$ for standard images ($\le 4\text{ MB}$ at $1080\text{p}$).
- **Preprocessing & Local CV Latency:** EXIF parsing, barcode decoding, and local OCR must complete within $\le 450\text{ ms}$.
- **Foundation Model Timeout Budget:** Gemini Vision API call bounded by a strict $5,000\text{ ms}$ timeout before triggering graceful fallback.

### 7.2 Scalability & Concurrency
- Minimum throughput capacity of 25 concurrent image analysis streams per worker instance without memory degradation.
- Zero disk-bound I/O bottlenecks: Image payloads must reside in volatile memory (`RAM` or `tmpfs`).

### 7.3 Reliability & Availability
- Service availability target: $99.9\%$ uptime.
- Deterministic graceful degradation: If Gemini Vision times out or returns HTTP 5xx, the system falls back to the deterministic CV engine (EXIF + Barcode + Local OCR + Regex) and flags the report as `degraded_analysis: true`.

### 7.4 Precision & Calibration
- **False Negative Rate (FNR) on Critical Credentials:** $< 2\%$ across benchmark evaluations (no unflagged private keys or passwords).
- **Expected Calibration Error (ECE):** Risk confidence calibration error $\le 0.12$.

---

## 8. System Architecture

### 8.1 Architectural Topology
Zenith follows a modular, pipeline-oriented hexagonal architecture. The core domain logic is decoupled from external delivery mechanisms (FastAPI REST service, WebSocket gateway) and external AI foundation models.

```mermaid
flowchart TB
    subgraph Clients ["External Client Ecosystem"]
        CameraClient["Team Member 1: Camera App (iOS/Android)"]
        ResearchWeb["Zenith Research & Evaluation Console"]
        ThirdParty["CI/CD Automated Test Runner"]
    end

    subgraph Gateway ["API Ingestion & Boundary Layer"]
        ReverseProxy["Reverse Proxy / TLS 1.3 Termination"]
        AuthRateLimit["API Key Authenticator & Rate Limiter"]
        Validator["Payload & Magic Byte Sanitizer"]
    end

    subgraph Pipeline ["Zenith Multi-Stage Intelligence Pipeline"]
        direction TB
        Stage1["1. Preprocessor & EXIF Inspector (Piexif / Libvips)"]
        Stage2["2. Deterministic CV Engine (Pyzbar Barcode + OCR Engine)"]
        Stage3["3. Multimodal Foundation Service (Gemini 2.5 Flash Adapter)"]
        Stage4["4. Normalization & Deduplication Broker (IoU Clusterer)"]
        Stage5["5. Adversarial Inference Engine (Evidence Graph Deduction)"]
        Stage6["6. Deterministic Risk Scoring Calculus (Mathematical Formula)"]
        Stage7["7. Mitigation & Action Planner (Remediation Generator)"]
    end

    subgraph Storage ["Ephemeral & Benchmark Storage"]
        RAMCache[("Volatile Image RAM / tmpfs (Zero Persistence)")]
        BenchStore[("Isolated Ground-Truth Benchmark DB")]
        AuditLog[("Sanitized Telemetry & Metrics Store")]
    end

    CameraClient --> ReverseProxy
    ResearchWeb --> ReverseProxy
    ThirdParty --> ReverseProxy

    ReverseProxy --> AuthRateLimit --> Validator
    Validator --> Stage1
    Stage1 --> Stage2
    Stage1 --> Stage3
    Stage2 --> Stage4
    Stage3 --> Stage4
    Stage4 --> Stage5
    Stage5 --> Stage6
    Stage6 --> Stage7

    Validator -. In-Memory Buffer .-> RAMCache
    Stage6 -. Anonymized Evaluation Metrics .-> AuditLog
    ThirdParty -. Test Fixtures .-> BenchStore
```

### 8.2 End-to-End Analysis Sequence
The diagram below illustrates the complete sequence of an image analysis request:

```mermaid
sequenceDiagram
    autonumber
    actor Client as Camera App / Client
    participant API as Ingestion API (FastAPI)
    participant Pre as Preprocessor & EXIF
    participant CV as Deterministic CV & OCR
    participant Gemini as Gemini Vision Adapter
    participant Agg as Deduplication & Inference
    participant Score as Risk Scoring Engine
    participant Mit as Mitigation Engine

    Client->>API: POST /v1/analyze (Multipart/form-data: image bytes)
    API->>API: Validate Magic Bytes & Rate Limits
    API->>Pre: Ingest into memory buffer (RAM)
    
    par Parallel Pre-Analysis
        Pre->>Pre: Parse EXIF & GPS Headers
        Pre->>CV: Execute Pyzbar (Barcodes) & Local OCR
    and Multimodal Vision
        Pre->>Gemini: Dispatch Image + Strict JSON Schema Prompt
    end

    CV-->>Agg: Return Decoded Codes, OCR Tokens, Regex Matches
    Gemini-->>Agg: Return Model Findings, Contextual Semantics
    
    Note over Agg: Cluster detections by IoU >= 0.5<br/>Deduplicate OCR vs Gemini findings<br/>Build Attacker Evidence Graph
    
    Agg->>Agg: Synthesize Inferences & Threat Vectors
    Agg->>Score: Pass Unified Findings List
    Score->>Score: Calculate Deterministic Risk Score (0-100)<br/>Compute 5 Category Scores
    Score->>Mit: Pass Scored Findings & Risk Levels
    Mit->>Mit: Generate Prioritized Mitigations & Bounding Boxes
    Mit-->>API: Package Unified PrivacyAuditReport
    API-->>Client: 200 OK (JSON Audit Payload)
    API->>API: Securely wipe in-memory image buffer
```

### 8.3 Data Flow Architecture

```mermaid
flowchart LR
    RawImage["Raw Binary Image Stream"] --> MagicBytes{"Magic Byte Verification"}
    MagicBytes -- Valid --> ExifStrip["EXIF & Metadata Parser"]
    MagicBytes -- Invalid --> ErrReject["422 Unprocessable Payload"]
    
    ExifStrip --> ExifData["Extracted Geolocation & Device Tags"]
    ExifStrip --> ScaledRAM["Memory Normalized RGB Buffer"]
    
    ScaledRAM --> ZBar["ZBar / Pyzbar Decoder"]
    ScaledRAM --> LocalOCR["OCR Engine (Text + Regex)"]
    ScaledRAM --> GeminiVision["Gemini Multimodal Vision"]
    
    ZBar --> ZBarTokens["Raw Barcode / QR Payloads"]
    LocalOCR --> OCRTokens["Text Tokens + Regex Matches"]
    GeminiVision --> GeminiTokens["Semantic Objects & Scene Graph"]
    
    ExifData --> Normalizer["Unified Finding Normalizer"]
    ZBarTokens --> Normalizer
    OCRTokens --> Normalizer
    GeminiTokens --> Normalizer
    
    Normalizer --> Deduplicator["Spatial & Semantic Deduplication"]
    Deduplicator --> InferenceEngine["Attacker Context & Inference Engine"]
    InferenceEngine --> RiskEngine["Deterministic Risk Calculator"]
    RiskEngine --> RecommendationEngine["Mitigation Engine"]
    RecommendationEngine --> ResponseFormatter["Response Serializer"]
```

### 8.4 Component Specifications

```
+-------------------------------------------------------------------------------------------------------------------------+
|                                           ZENITH COMPONENT REGISTRY                                                     |
+----+-----------------------------+-------------------------------+------------------------------+-----------------------+
| ID | Component Name              | Primary Responsibility        | Primary Dependencies         | Failure Mode Handling |
+----+-----------------------------+-------------------------------+------------------------------+-----------------------+
| 01 | External Client Layer       | Exposes HTTP/WS API contracts | FastAPI, Uvicorn, Pydantic   | HTTP 400/401/429/500  |
| 02 | Ingestion & Sanitizer       | Magic bytes, size check, dims | python-magic, Pillow         | Immediate 422 discard |
| 03 | EXIF & Metadata Inspector   | GPS extraction, camera serial | piexif, exifread             | Graceful empty map    |
| 04 | Barcode & Matrix Decoder    | 1D/2D code payload recovery   | pyzbar, libzbar              | Empty array if none   |
| 05 | Local OCR & Pattern Matcher | High-density text + regex     | Tesseract / EasyOCR, re      | Degraded text search  |
| 06 | Gemini Vision Adapter       | Multimodal scene understanding| google-genai SDK, httpx      | Fallback to local CV  |
| 07 | Normalizer & Deduplicator   | Merges duplicate discoveries  | Shapely, numpy (IoU matrix)  | Keep higher confidence|
| 08 | Adversarial Inference Engine| Threat vector synthesis       | NetworkX (Inference DAG)     | Emit direct obs only  |
| 09 | Privacy Risk Scoring Calculus| Deterministic 0-100 score     | Zenith Math Formulation      | Clamp to range [0,100]|
| 10 | Recommendation Generator    | Actionable mitigation matrix  | Rule Engine                  | Default "Hold Image"  |
| 11 | Evaluation & Benchmark Hub  | Ground-truth regression suite | Pytest, Scikit-learn         | CI pipeline abort     |
| 12 | Telemetry & Audit Logger    | PII-sanitized observability   | Structlog, Prometheus        | Silent drop on error  |
+----+-----------------------------+-------------------------------+------------------------------+-----------------------+
```

---

## 9. AI and Computer Vision Pipeline

### 9.1 The Hybrid Analysis Paradigm
A critical architectural decision of Zenith is that **foundation multimodal LLMs must not be relied upon for deterministic tasks**. Multimodal LLMs frequently hallucinate character sequences in barcodes, miss small credentials in dense text, and output non-deterministic risk scores.

Therefore, Zenith employs a **hybrid pipeline**:

```
+-------------------------------------------------------------------------------------------------------+
|                                    PIPELINE RESPONSIBILITY DIVISION                                    |
+----------------------------------+----------------------------------+---------------------------------+
| Deterministic Specialized Tools  | Gemini Multimodal Foundation AI  | Deterministic Post-Processing   |
+----------------------------------+----------------------------------+---------------------------------+
| - EXIF GPS & Device Extraction   | - Broad scene categorization     | - Spatial IoU Deduplication     |
| - 1D/2D Barcode payload decoding | - Facial demographic anonymity   | - Regex token validation        |
| - Screen reflection detection    | - Human activity & posture       | - Mathematical risk calculus    |
| - High-contrast text binarization| - Complex architectural context  | - Inference DAG resolution      |
| - High-density OCR scanning      | - Cross-object semantic ties     | - Mitigation action sequencing  |
+----------------------------------+----------------------------------+---------------------------------+
```

### 9.2 Gemini Vision Integration & Structured Schema Enforcement
Zenith configures Gemini Vision using Google's `google-genai` SDK targeting model `gemini-2.5-flash` with strict JSON schema constraints.

```json
{
  "scene_description": "Office workstation with laptop displaying active terminal",
  "detected_elements": [
    {
      "name": "AWS Access Key ID in Terminal",
      "category": "digital",
      "information_type": "credential",
      "description": "Terminal window displays plaintext AWS key AKIAIOSFODNN7EXAMPLE",
      "evidence_snippet": "AKIAIOSFODNN7EXAMPLE",
      "bounding_box": {
        "top": 0.28,
        "left": 0.42,
        "width": 0.22,
        "height": 0.05
      },
      "confidence": 0.98,
      "visibility": "clear",
      "opsec_threat": "Direct account compromise via automated credential scrapers"
    }
  ],
  "inferred_insights": [
    {
      "category": "digital",
      "supporting_evidence_ids": ["AWS Access Key ID in Terminal"],
      "inference_statement": "Organization utilizes Amazon Web Services infrastructure with unmasked IAM roles",
      "adversarial_threat_vector": "Adversary will attempt AWS API reconnaissance against S3 buckets and IAM privileges",
      "confidence": 0.94,
      "severity": "critical"
    }
  ]
}
```

### 9.3 Validation Rules for Model Outputs
1. **Coordinate Normalization Check:** Every bounding box coordinate must satisfy $0.0 \le \text{coord} \le 1.0$ and $\text{width} > 0, \text{height} > 0$. Any bounding box violating these bounds is clamped or discarded.
2. **Hallucination Shield:** If Gemini reports a specific text string (e.g., an email address or license plate number), but the local deterministic OCR engine finds zero substring or fuzzy match within that bounding box region, the finding is marked with `flag_unverified_text: true` and its confidence is dampened by $0.40$.
3. **No Numerical Authority:** Gemini is **never** permitted to calculate the final `overall_risk_score`. Any numerical score generated in the LLM output is stripped and superseded by Zenith's Deterministic Risk Scoring Engine.

---

## 10. Structured Data Schemas & Contracts

### 10.1 Finding Entity Schema
Every atomic security discovery conforms to the following strict schema:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ZenithFinding",
  "type": "object",
  "required": [
    "finding_id",
    "category",
    "information_type",
    "description",
    "detection_source",
    "confidence",
    "visibility_score",
    "base_severity_score",
    "actionable_mitigation"
  ],
  "properties": {
    "finding_id": { "type": "string", "pattern": "^fnd_[a-z0-9_]{8,24}$" },
    "category": { 
      "type": "string", 
      "enum": ["identity", "location", "digital_security", "personal_info", "physical_security"] 
    },
    "information_type": { "type": "string" },
    "description": { "type": "string" },
    "detection_source": { 
      "type": "string", 
      "enum": ["exif_parser", "barcode_decoder", "local_ocr", "gemini_vision", "inference_engine"] 
    },
    "evidence_text": { "type": ["string", "null"] },
    "bounding_box": {
      "type": ["object", "null"],
      "properties": {
        "top": { "type": "number", "minimum": 0, "maximum": 1 },
        "left": { "type": "number", "minimum": 0, "maximum": 1 },
        "width": { "type": "number", "minimum": 0, "maximum": 1 },
        "height": { "type": "number", "minimum": 0, "maximum": 1 }
      },
      "required": ["top", "left", "width", "height"]
    },
    "confidence": { "type": "number", "minimum": 0.0, "maximum": 1.0 },
    "visibility_score": { "type": "number", "minimum": 0.1, "maximum": 1.0 },
    "base_severity_score": { "type": "integer", "minimum": 1, "maximum": 100 },
    "actionable_mitigation": { "type": "string" }
  }
}
```

### 10.2 Inference Entity Schema
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ZenithInference",
  "type": "object",
  "required": [
    "inference_id",
    "category",
    "supporting_evidence_ids",
    "direct_observation",
    "inferred_deduction",
    "adversarial_threat_vector",
    "confidence",
    "epistemic_level"
  ],
  "properties": {
    "inference_id": { "type": "string", "pattern": "^inf_[a-z0-9_]{8,24}$" },
    "category": { 
      "type": "string", 
      "enum": ["identity", "location", "digital_security", "personal_info", "physical_security"] 
    },
    "supporting_evidence_ids": { 
      "type": "array", 
      "items": { "type": "string" },
      "minItems": 1
    },
    "direct_observation": { "type": "string" },
    "inferred_deduction": { "type": "string" },
    "adversarial_threat_vector": { "type": "string" },
    "confidence": { "type": "number", "minimum": 0.0, "maximum": 1.0 },
    "epistemic_level": { 
      "type": "string", 
      "enum": ["corroborated_deduction", "contextual_probability", "uncertain_hypothesis"] 
    }
  }
}
```

---

## 11. Privacy Risk Scoring Methodology

### 11.1 Mathematical Formulation
The overall privacy risk score is computed deterministically through a multi-factor mathematical formulation. It maps the set of validated findings $F = \{f_1, f_2, \dots, f_n\}$ and inferences $I = \{i_1, i_2, \dots, i_m\}$ into a single continuous scale bounded between $0$ and $100$.

#### 1. Individual Finding Risk Impact ($R_k$)
For each finding $f_k$, the standalone risk contribution is calculated as:

$$R(f_k) = S(f_k) \times E(f_k) \times V(f_k) \times C(f_k)$$

Where:
- $S(f_k) \in [1, 100]$: **Intrinsic Sensitivity Weight**. The inherent privacy impact of the data type (e.g., Plaintext Password = $100$; Face Silhouette = $30$).
- $E(f_k) \in [0.2, 1.0]$: **Exploitability Factor**. Ease of weaponization (e.g., Direct API key = $1.0$; partial unresolvable phone prefix = $0.3$).
- $V(f_k) \in [0.1, 1.0]$: **Visibility & Clarity Multiplier**. Legibility, pixel density, focus, or occlusion of the detected target.
- $C(f_k) \in [0.0, 1.0]$: **Empirical Confidence Factor**. Model detection confidence.

#### 2. Deduplication & Spatial Clustering
Before aggregation, any findings sharing spatial overlap where $\text{IoU}(f_a, f_b) \ge 0.50$ and semantic classification equivalence are consolidated into a single finding $f^*$:

$$S(f^*) = \max(S(f_a), S(f_b)), \quad C(f^*) = \max(C(f_a), C(f_b)), \quad V(f^*) = \frac{V(f_a) + V(f_b)}{2}$$

#### 3. Category Score Formulation ($CS_c$)
For each of the 5 exposure categories $c \in \{1, 2, 3, 4, 5\}$, findings belonging to category $c$ are aggregated using a **bounded probabilistic sum** to model diminishing marginal risk while preventing score explosion:

$$CS_c = 100 \times \left( 1 - \prod_{f_k \in F_c} \left( 1 - \frac{R(f_k)}{100} \right) \right)$$

This formula possesses essential mathematical properties:
1. **Monotonicity:** Adding a new risk always increases the category score.
2. **Strict Boundedness:** $CS_c$ asymptotically approaches $100$ but can never exceed it.
3. **Severe Dominance:** A single critical finding ($R = 95$) guarantees a critical category score regardless of other elements.

#### 4. Unified Overall Risk Score ($\Omega$)
The overall system risk score synthesizes the peak category vulnerability with compound cross-category breadth and contextual threat deductions:

$$\Omega = \min\left(100, \; \max_{c}(CS_c) + \beta \sum_{c \neq \text{peak}} CS_c + \Gamma(I)\right)$$

Where:
- $\max_{c}(CS_c)$: **Peak Category Anchor**. Guarantees that a system's overall exposure is at minimum as severe as its single worst compromised domain, preventing severe vulnerabilities from being mathematically diluted by non-exposed domains.
- $\beta = 0.12$: **Secondary Breadth Coefficient**. Imposes a compound penalty when multiple independent threat surfaces are simultaneously compromised.
- $\Gamma(I) \in [0, 15]$: **Inference Synergy Amplifier**. Additional penalty added when the Inference Engine detects cross-domain correlation:

$$\Gamma(I) = \min\left(15, \; \sum_{i_j \in I} 5.0 \times C(i_j)\right)$$

- **Critical Credential Floor:** If any individual finding $f_k$ exhibits standalone risk $R(f_k) \ge 90$ (e.g., unmasked AWS secret key, plaintext credentials, or unredacted payment PAN), an overall floor of $\Omega \ge 90$ is strictly enforced.

### 11.2 Calibrated Severity Thresholds
The continuous score $\Omega$ maps deterministically into four calibrated operational bands:

```
+----------------------------------------------------------------------------------------------------+
|                                    RISK SEVERITY BANDS                                             |
+--------------+-------------+------------------------------------+----------------------------------+
| Score Range  | Severity    | Operational Meaning                | Default Recommended Mitigation   |
+--------------+-------------+------------------------------------+----------------------------------+
| 0 – 25       | LOW         | Minimal to zero identifiable PII.  | Safe for public sharing.         |
|              |             | No actionable attacker vectors.    | Optional EXIF strip.             |
+--------------+-------------+------------------------------------+----------------------------------+
| 26 – 50      | MODERATE    | Noticeable identifiable attributes | Review background details.       |
|              |             | or unlinked secondary markers.     | Crop non-essential regions.      |
+--------------+-------------+------------------------------------+----------------------------------+
| 51 – 75      | HIGH        | Definite PII, residential location | Apply targeted blur to badges,   |
|              |             | tracing, or vehicle tracking.      | plates, or text before posting.  |
+--------------+-------------+------------------------------------+----------------------------------+
| 76 – 100     | CRITICAL    | Severe OPSEC compromise: unmasked  | DO NOT SHARE. Strip credentials, |
|              |             | credentials, barcodes, home PII.   | solid black censor required.     |
+--------------+-------------+------------------------------------+----------------------------------+
```

### 11.3 Worked Scoring Examples

#### Example 1: Ordinary Clean Photograph (Scenic Nature Park)
- **Input:** Landscape photo of mountains and a lake. EXIF metadata contains camera model but GPS was disabled at capture.
- **Detections:**
  - $f_1$: Natural Landscape (`location`, $S=5$, $E=0.2$, $V=1.0$, $C=0.99$) $\implies R(f_1) = 5 \times 0.2 \times 1.0 \times 0.99 = 0.99$.
  - $f_2$: Camera EXIF Model Tag (`digital_security`, $S=10$, $E=0.2$, $V=1.0$, $C=1.0$) $\implies R(f_2) = 10 \times 0.2 \times 1.0 \times 1.0 = 2.0$.
- **Category Calculations:**
  - $CS_{\text{location}} = 100 \times (1 - (1 - 0.0099)) = 1.0$.
  - $CS_{\text{digital}} = 100 \times (1 - (1 - 0.020)) = 2.0$.
  - Other categories = $0.0$.
- **Overall Score ($\Omega$):**
  - $\max(CS) = 2.0$, $\text{mean}(CS) = 0.60$, $\Gamma(I) = 0$.
  - $\Omega = 0.70(2.0) + 0.30(0.60) + 0 = 1.40 + 0.18 = \mathbf{2} \implies \text{\textbf{LOW RISK}}$.

#### Example 2: Vehicle Registration Plate in Public Street
- **Input:** Street photograph with a parked vehicle showing an unblurred state license plate ("CALIFORNIA 7XYZ123").
- **Detections:**
  - $f_1$: Vehicle License Plate (`physical_security`, $S=70$, $E=0.8$, $V=0.9$, $C=0.96$) $\implies R(f_1) = 70 \times 0.8 \times 0.9 \times 0.96 = 48.38$.
  - $f_2$: Street Curbside & Asphalt (`location`, $S=15$, $E=0.3$, $V=0.8$, $C=0.90$) $\implies R(f_2) = 15 \times 0.3 \times 0.8 \times 0.90 = 3.24$.
- **Category Calculations:**
  - $CS_{\text{physical}} = 100 \times (1 - (1 - 0.4838)) = 48.4$.
  - $CS_{\text{location}} = 3.2$.
- **Overall Score ($\Omega$):**
  - $\max(CS) = 48.4$, $\text{mean}(CS) = 10.32$, $\Gamma(I) = 0$.
  - $\Omega = 0.70(48.4) + 0.30(10.32) + 0 = 33.88 + 3.10 = \mathbf{37} \implies \text{\textbf{MODERATE RISK}}$.

#### Example 3: Student Identity Card with Barcode
- **Input:** Table snapshot showing a university card: Student name ("Alexander Morgan"), student ID number, portrait, and 1D barcode.
- **Detections:**
  - $f_1$: Full Legal Name (`personal_info`, $S=65$, $E=0.8$, $V=1.0$, $C=0.98$) $\implies R(f_1) = 50.96$.
  - $f_2$: Student ID Number (`identity`, $S=75$, $E=0.85$, $V=1.0$, $C=0.96$) $\implies R(f_2) = 61.20$.
  - $f_3$: Institutional Barcode (`personal_info`, $S=85$, $E=0.95$, $V=1.0$, $C=0.99$) $\implies R(f_3) = 79.94$.
  - $f_4$: Biometric Face Photo (`identity`, $S=50$, $E=0.7$, $V=0.9$, $C=0.95$) $\implies R(f_4) = 29.92$.
- **Inference Deduction:**
  - $i_1$: Educational institution + Active cohort + Graduation year ($C=0.95$). $\Gamma(I) = 5.0 \times 0.95 = 4.75$.
- **Category Calculations:**
  - $CS_{\text{identity}} = 100 \times (1 - (1 - 0.6120)(1 - 0.2992)) = 100 \times (1 - 0.388 \times 0.7008) = 72.8$.
  - $CS_{\text{personal\_info}} = 100 \times (1 - (1 - 0.5096)(1 - 0.7994)) = 100 \times (1 - 0.4904 \times 0.2006) = 90.2$.
- **Overall Score ($\Omega$):**
  - $\max(CS) = 90.2$, $\text{mean}(CS) = 32.6$, $\Gamma(I) = 4.75$.
  - $\Omega = 0.70(90.2) + 0.30(32.6) + 4.75 = 63.14 + 9.78 + 4.75 = \mathbf{78} \implies \text{\textbf{CRITICAL RISK}}$.

#### Example 4: Laptop Screen Exposing AWS Credentials
- **Input:** Office desk photo with an open terminal on a laptop showing unmasked AWS access keys and a production PostgreSQL connection URI.
- **Detections:**
  - $f_1$: Cloud API Secret Key (`digital_security`, $S=100$, $E=1.0$, $V=0.95$, $C=0.98$) $\implies R(f_1) = 93.1$.
  - $f_2$: Database Connection URI (`digital_security`, $S=95$, $E=0.95$, $V=0.90$, $C=0.95$) $\implies R(f_2) = 77.16$.
  - $f_3$: Internal Hostname / IP (`digital_security`, $S=60$, $E=0.7$, $V=0.85$, $C=0.92$) $\implies R(f_3) = 32.84$.
- **Category Calculations:**
  - $CS_{\text{digital}} = 100 \times (1 - (1 - 0.931)(1 - 0.7716)(1 - 0.3284)) = 100 \times (1 - 0.069 \times 0.2284 \times 0.6716) = 98.9$.
- **Overall Score ($\Omega$):**
  - $\max(CS) = 98.9$, $\text{mean}(CS) = 19.78$, $\Gamma(I) = 0$.
  - $\Omega = 0.70(98.9) + 0.30(19.78) = 69.23 + 5.93 = \mathbf{75.16} \to \mathbf{96}$ (Boosted by direct critical credential multiplier: $R_k \ge 90 \implies \Omega \ge 90$).
  - $\Omega = \mathbf{96} \implies \text{\textbf{CRITICAL RISK}}$.

#### Example 5: Compound Multi-Vector Exposure
- **Input:** Balcony selfie with moderate background details: A company lanyard hanging around the neck (unreadable text), a street sign visible down the road ("Pine St"), an open calendar on a phone screen on the table, and residential building facades.
- **Detections:**
  - $f_1$: Corporate Lanyard & Badge Shape (`identity`, $S=40$, $E=0.5$, $V=0.7$, $C=0.85$) $\implies R(f_1) = 11.9$.
  - $f_2$: Municipal Street Sign (`location`, $S=65$, $E=0.7$, $V=0.75$, $C=0.90$) $\implies R(f_2) = 30.71$.
  - $f_3$: Recognizable Building Skyline (`location`, $S=55$, $E=0.6$, $V=0.8$, $C=0.88$) $\implies R(f_3) = 23.23$.
  - $f_4$: Phone Screen with Meeting Schedule (`digital_security`, $S=50$, $E=0.6$, $V=0.6$, $C=0.80$) $\implies R(f_4) = 14.4$.
- **Inference Deduction:**
  - $i_1$: Pine St + Skyline = Triangulated city district ($C=0.88$).
  - $i_2$: Corporate badge style + District = Probable tech employer campus ($C=0.78$).
  - $i_3$: Meeting schedule + Employer = Typical arrival/departure commute routines ($C=0.82$).
  - $\Gamma(I) = \min(15, \; 5.0(0.88) + 5.0(0.78) + 5.0(0.82)) = \min(15, 12.4) = 12.4$.
- **Category Calculations:**
  - $CS_{\text{location}} = 100 \times (1 - (1 - 0.3071)(1 - 0.2323)) = 100 \times (1 - 0.6929 \times 0.7677) = 46.8$.
  - $CS_{\text{identity}} = 11.9$, $CS_{\text{digital}} = 14.4$.
- **Overall Score ($\Omega$):**
  - $\max(CS) = 46.8$, $\text{mean}(CS) = 14.62$, $\Gamma(I) = 12.4$.
  - $\Omega = 0.70(46.8) + 0.30(14.62) + 12.4 = 32.76 + 4.39 + 12.4 = \mathbf{50} \implies \text{\textbf{MODERATE RISK (Threshold of HIGH)}}$.
  - Demonstrates how individually low/moderate clues combine through inferences to elevate the overall risk posture.

---

## 12. Attacker-Perspective Privacy Intelligence

### 12.1 The Adversary Mental Model
Zenith simulates an adversary possessing modern OSINT toolkits, automated scrapers, and deductive correlation skills. The analysis breaks down threat modeling into four progressive tiers:

```mermaid
graph TD
    T1["Tier 1: Directly Visible Elements (Raw Sight)"]
    T2["Tier 2: Machine Extracted Entities (OCR & Metadata)"]
    T3["Tier 3: Contextual Inferences (Logical Deductions)"]
    T4["Tier 4: Weaponization Vectors (Adversarial Exploit)"]

    T1 -->|Extraction| T2
    T2 -->|Synthesis| T3
    T3 -->|Threat Modeling| T4

    subgraph Examples ["Concrete Threat Flow"]
        Ex1["Photo of Boarding Pass"] --> Ex2["Extracts PNR 'K9P2X1' & Passenger Name"]
        Ex2 --> Ex3["Deduces Absence Window: Oct 12-19 from JFK to LHR"]
        Ex3 --> Ex4["Physical Residential Burglary during vacant interval"]
    end
```

### 12.2 Inference Synthesis Matrix
The following table formalizes the logical rules Zenith uses to deduce inferential exposure without speculation:

```
+---------------------------------------------------------------------------------------------------------------------------------+
|                                                 INFERENCE DEDUCTION MATRIX                                                      |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
| Grounded Visible Evidence (T1/T2)  | Synthesized Deduction (T3)         | Weaponization Vector (T4)      | Epistemic Validation |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
| Student ID card + university crest | Affiliation, academic cohort,      | Targeted spear-phishing, campus| Verified by crest    |
| + visible graduation year          | physical presence routine          | social engineering             | and ID text match    |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
| Residential house number placard   | Specific street domicile address   | Physical stalking, home invasion| Requires street sign |
| + visible municipal street sign    | pin-pointed on map                 | swatting vector                | or distinct building |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
| Laptop terminal with shell prompt  | Cloud provider, internal repo name,| Lateral network pivoting,      | Regex match on AWS/  |
| displaying AWS IAM username        | organizational engineering stack   | targeted employee credential phish| GCP key patterns    |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
| Boarding pass Aztec barcode        | Travel route, departure date,      | Home vacancy exploitation,     | Barcode decodes to   |
| + flight confirmation code (PNR)   | seat number, frequent flyer tier   | reservation hijacking online   | IATA BCBP standard   |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
| Desk mail envelope with blurred    | Primary banking institution,       | Vishing (voice phishing)       | Bank logo matched,   |
| name + visible bank corporate logo | financial relationship             | financial impersonation        | text unreadable      |
+------------------------------------+------------------------------------+--------------------------------+----------------------+
```

### 12.3 Defensive Guardrails (Anti-Doxxing Controls)
To prevent the system from being abused as an offensive surveillance tool:
1. **No External Entity Resolution:** Zenith **never** queries live external identity databases, social network APIs, or reverse image search engines.
2. **Abstract Threat Modeling:** When an inference describes a domicile risk, it outputs `"Reveals residential street address"`. It does **not** fetch the homeowner's name from county property records.
3. **No Facial Recognition Database Linking:** Facial features are evaluated solely for biometric clarity and reverse-search vulnerability; they are never queried against biometric face clusters.

---

## 13. Test Case & Evaluation Framework

### 13.1 Benchmark Dataset Strategy
To evaluate Zenith safely and rigorously, evaluation datasets must adhere to ethical boundaries:
- **Zero Real-World PII:** Absolutely no photos of non-consenting individuals, real passwords, or authentic personal identity cards.
- **Synthetic Ground-Truth Generation:** Test images are constructed using synthetic data:
  - Fictional government/student IDs generated with mock names and fake barcode payloads.
  - Test development monitors displaying dummy API keys (e.g., `AKIAIOSFODNN7EXAMPLE`).
  - Public domain architectural and scenic photos with zero private indicators.
- **Consented Calibration Sets:** High-variance photos captured in staged environments under signed security consent.

### 13.2 Automated Test Case Suite (17 Comprehensive Classes)

```
+-------------------------------------------------------------------------------------------------------------------------+
|                                             ZENITH BENCHMARK TEST SUITE                                                 |
+---------+-------------------------------+---------------------+--------------------+---------------+--------------------+
| Test ID | Scenario Class Description    | Key Visual Targets  | Expected Severity  | Expected Cat. | Acceptance Metric  |
+---------+-------------------------------+---------------------+--------------------+---------------+--------------------+
| TC-01   | Clean Nature Landscape        | Mountains, trees    | LOW (0 - 10)       | Location      | False Pos Rate < 1%|
| TC-02   | Indoor Clean Studio Portrait  | Consented face only | LOW-MOD (15 - 30)  | Identity      | Face bbox IoU > 0.8|
| TC-03   | University Student ID Badge   | Badge, barcode, name| CRITICAL (76 - 90) | Identity/PII  | Recall = 100%      |
| TC-04   | Printed Bank Statement on Desk| IBAN, account bal.  | CRITICAL (80 - 95) | Personal Info | OCR recall > 95%   |
| TC-05   | Parked Vehicle with State Plate| California Plate    | MODERATE (30 - 48) | Physical Sec. | Plate bbox IoU >0.7|
| TC-06   | Standalone Wi-Fi QR Code      | QR matrix on card   | CRITICAL (76 - 88) | Digital Sec.  | QR payload decoded |
| TC-07   | Workstation Screen with Code  | VS Code, API tokens | CRITICAL (85 - 100)| Digital Sec.  | Token detected     |
| TC-08   | Front Porch with House Number | '742' + Street sign | HIGH (55 - 75)     | Location      | Number detected    |
| TC-09   | Credit Card on Restaurant Desk| Card PAN & Expiry   | CRITICAL (90 - 100)| Personal Info | Zero false neg.    |
| TC-10   | Airline Boarding Pass on Knee | Aztec code + PNR    | CRITICAL (85 - 98) | Transportation| BCBP standard parse|
| TC-11   | Window Reflection with Monitor| Blurred code reflect| MODERATE (26 - 45) | Digital Sec.  | Reflection flagged |
| TC-12   | JPEG with Rich GPS EXIF Header| Lat/Long tags       | HIGH (51 - 70)     | Location      | GPS extracted      |
| TC-13   | Compound Risk Multi-Target    | Badge + Sign + Cal. | CRITICAL (76 - 92) | Multi (4 cats)| Compound amp > 10  |
| TC-14   | False Positive Control: Noise | Texture, barcodes-like| LOW (0 - 15)      | Any           | FP rejected        |
| TC-15   | Obstructed / Occluded Badge   | Finger over name    | MODERATE (30 - 50) | Identity      | Occlusion noted    |
| TC-16   | Severe Motion Blur on Screen  | Unreadable terminal | LOW-MOD (15 - 35)  | Digital Sec.  | Low confidence tag |
| TC-17   | Ambiguous Corporate Lanyard   | Lanyard, no logo    | LOW-MOD (20 - 35)  | Identity      | Marked uncertain   |
+---------+-------------------------------+---------------------+--------------------+---------------+--------------------+
```

### 13.3 Quantitative Evaluation Metrics
The evaluation harness computes the following statistical metrics across test suites:

$$\text{Precision} = \frac{TP}{TP + FP}, \quad \text{Recall} = \frac{TP}{TP + FN}, \quad F_1 = 2 \cdot \frac{\text{Precision} \cdot \text{Recall}}{\text{Precision} + \text{Recall}}$$

$$\text{Risk Score Mean Absolute Error (MAE)} = \frac{1}{N} \sum_{k=1}^{N} |\Omega_{\text{calculated}} - \Omega_{\text{ground\_truth}}|$$

$$\text{Expected Calibration Error (ECE)} = \sum_{m=1}^{M} \frac{|B_m|}{N} |\text{acc}(B_m) - \text{conf}(B_m)|$$

Acceptance Gate: CI/CD test runs fail if $\text{Recall}_{\text{critical}} < 0.98$, $\text{MAE}_{\Omega} > 6.5$, or $\text{ECE} > 0.15$.

---

## 14. Mitigation and Recommendation Engine

### 14.1 Remediation Action Taxonomy
Every detected privacy risk is paired with actionable mitigations ranked by threat reduction impact:

```
+----------------------------------------------------------------------------------------------------+
|                                    MITIGATION ACTION TAXONOMY                                      |
+-------------------+--------------------+------------------------+----------------------------------+
| Action Identifier | Execution Method   | Algorithmic Complexity | Typical Target Element           |
+-------------------+--------------------+------------------------+----------------------------------+
| `solid_censor`    | Solid Black Box    | Low (Deterministic)    | Passwords, API keys, Barcodes    |
| `gaussian_blur`   | 25px Gaussian Blur | Low (GPU/Shader)       | Human portraits, House numbers   |
| `bounding_crop`   | Crop image bounds  | Low (Canvas slice)     | Background reflections, Monitors |
| `strip_exif`      | Header sanitization| Low (Binary rewrite)   | GPS coordinates, Camera serials  |
| `hold_publish`    | User refusal advis.| Zero (Human policy)    | Identity cards, Boarding passes  |
+-------------------+--------------------+------------------------+----------------------------------+
```

### 14.2 Verification Rescan Protocol
Zenith supports a closed-loop verification workflow:
1. Client submits raw photo $\implies$ receives findings and suggested bounding box redactions.
2. Client applies redactions locally (or requests server-side auto-redact preview).
3. Client dispatches redacted image to `POST /v1/rescan` with original `analysis_id`.
4. Zenith executes differential analysis, calculating:

$$\Delta\Omega = \Omega_{\text{original}} - \Omega_{\text{redacted}}$$

The rescan endpoint returns verification status: `MITIGATION_VERIFIED` (if $\Omega \le 25$) or `RESIDUAL_RISK_DETECTED` with remaining unredacted coordinates.

---

## 15. API Specification & Integration Contract

### 15.1 Integration Principles
The API follows RESTful principles with JSON payloads and standard multipart image uploads. Secrets are strictly managed on the server. Client applications (such as Team Member 1's Camera App) authenticate using temporary client session tokens or static application client IDs, while server-to-Gemini credentials reside strictly in backend environment variables.

### 15.2 Primary API Endpoints

#### Endpoint 1: Analyze Optical Payload
- **Route:** `POST /v1/analyze`
- **Content-Type:** `multipart/form-data`
- **Request Form Fields:**
  - `image` (File, Required): Binary image stream (JPEG, PNG, WebP, HEIC). Max 25 MB.
  - `sensitivity_profile` (String, Optional): `conservative` | `balanced` (Default) | `maximum_opsec`.
  - `client_request_id` (String, Optional): UUIDv4 generated by client for idempotency.
- **Headers:**
  - `X-Zenith-Client-Id`: `camera-app-v1.0`
  - `Authorization`: `Bearer <zenith_client_jwt_token>`

#### Realistic Success Response (`200 OK`):
```json
{
  "analysis_id": "aud_01J9X8K2M4P6Q8V0W2Y4Z6A8B0",
  "timestamp": "2026-10-11T20:15:30.124Z",
  "processing_duration_ms": 1420,
  "engine_version": "zenith-core-1.0.0",
  "degraded_analysis": false,
  "risk_assessment": {
    "overall_score": 78,
    "severity_level": "CRITICAL",
    "headline": "Critical Identity & Institutional Exposure",
    "executive_summary": "Image contains an unredacted university student ID with high-density barcode and visible legal name, creating significant identity theft and impersonation vulnerabilities.",
    "category_scores": {
      "identity": 73,
      "location": 20,
      "digital_security": 5,
      "personal_info": 90,
      "physical_security": 10
    }
  },
  "findings_count": 3,
  "findings": [
    {
      "finding_id": "fnd_stu_barcode_01",
      "category": "personal_info",
      "information_type": "Institutional Barcode (Code 128)",
      "description": "High-contrast 1D barcode on lower quadrant of student ID card",
      "detection_source": "barcode_decoder",
      "evidence_text": "STU-9948201-2027",
      "bounding_box": {
        "top": 0.65,
        "left": 0.12,
        "width": 0.76,
        "height": 0.18
      },
      "confidence": 0.99,
      "visibility_score": 1.0,
      "base_severity_score": 85,
      "actionable_mitigation": "Apply solid black censorship bar over barcode"
    },
    {
      "finding_id": "fnd_stu_name_02",
      "category": "identity",
      "information_type": "Full Legal Name",
      "description": "Printed student name in sans-serif typography",
      "detection_source": "local_ocr",
      "evidence_text": "Alexander Morgan",
      "bounding_box": {
        "top": 0.42,
        "left": 0.35,
        "width": 0.50,
        "height": 0.08
      },
      "confidence": 0.96,
      "visibility_score": 0.95,
      "base_severity_score": 65,
      "actionable_mitigation": "Apply Gaussian blur over full name"
    },
    {
      "finding_id": "fnd_stu_portrait_03",
      "category": "identity",
      "information_type": "Biometric Face Portrait",
      "description": "Clear frontal identification portrait",
      "detection_source": "gemini_vision",
      "evidence_text": null,
      "bounding_box": {
        "top": 0.25,
        "left": 0.08,
        "width": 0.24,
        "height": 0.42
      },
      "confidence": 0.95,
      "visibility_score": 0.90,
      "base_severity_score": 50,
      "actionable_mitigation": "Apply Gaussian blur over biometric portrait"
    }
  ],
  "inferred_insights": [
    {
      "inference_id": "inf_cohort_01",
      "category": "identity",
      "supporting_evidence_ids": ["fnd_stu_barcode_01", "fnd_stu_name_02"],
      "direct_observation": "Student ID card with barcode STU-9948201-2027 and name Alexander Morgan",
      "inferred_deduction": "Enrolled undergraduate student at Pacific State University with active class of 2027 standing",
      "adversarial_threat_vector": "Adversary can impersonate student to access campus portals or conduct targeted spear-phishing using academic schedule context",
      "confidence": 0.94,
      "epistemic_level": "corroborated_deduction"
    }
  ],
  "recommendations": [
    {
      "recommendation_id": "rec_01",
      "finding_ref": "fnd_stu_barcode_01",
      "priority": "CRITICAL",
      "title": "Redact Machine-Readable Barcode",
      "action": "Cover the barcode completely with a solid black censorship bar before uploading",
      "action_type": "solid_censor",
      "estimated_risk_reduction": 42,
      "automatable": true
    },
    {
      "recommendation_id": "rec_02",
      "finding_ref": "fnd_stu_name_02",
      "priority": "HIGH",
      "title": "Blur Identifiable Student Name",
      "action": "Apply a 20-pixel blur filter over the name text",
      "action_type": "gaussian_blur",
      "estimated_risk_reduction": 28,
      "automatable": true
    }
  ]
}
```

#### Endpoint 2: Verification Rescan
- **Route:** `POST /v1/rescan`
- **Request Form Fields:**
  - `image` (File, Required): Redacted image file.
  - `original_analysis_id` (String, Required): Previous `analysis_id`.
- **Response (`200 OK`):**
```json
{
  "rescan_id": "res_01J9X8N9B2C4D6E8F0H2K4L6N8",
  "original_analysis_id": "aud_01J9X8K2M4P6Q8V0W2Y4Z6A8B0",
  "original_score": 78,
  "new_score": 14,
  "score_delta": -64,
  "previous_severity": "CRITICAL",
  "new_severity": "LOW",
  "verification_status": "MITIGATION_VERIFIED",
  "residual_findings_count": 0,
  "message": "All critical and high risk targets successfully obscured. Image is safe for publication."
}
```

#### Endpoint 3: System Health & Adapter Diagnostics
- **Route:** `GET /v1/health`
- **Response (`200 OK`):**
```json
{
  "status": "healthy",
  "uptime_seconds": 84210,
  "active_workers": 4,
  "adapters": {
    "gemini_vision_api": "connected",
    "local_ocr_engine": "operational",
    "barcode_decoder": "operational",
    "exif_inspector": "operational"
  }
}
```

### 15.3 API Error Handling Contract
All non-200 responses return standard RFC 7807 Problem Details:

```json
{
  "type": "https://zenith.security/errors/UNPROCESSABLE_IMAGE_PAYLOAD",
  "title": "Unprocessable Image Payload",
  "status": 422,
  "detail": "Uploaded file magic bytes indicate 'audio/mpeg' which is not an allowable image MIME type.",
  "instance": "/v1/analyze",
  "request_id": "req_01J9X90A3B5C7D9E"
}
```

---

## 16. Security and Privacy by Design Architecture

### 16.1 Zero-Retention Data Lifecycle
Because Zenith processes sensitive and potentially compromising photographs, data minimization is enforced at the hardware/OS level:

```mermaid
flowchart LR
    Upload["Client POST Request"] --> RAM["Volatile RAM Buffer (/dev/shm)"]
    RAM --> Pipeline["In-Memory Execution (OCR + Gemini)"]
    Pipeline --> Response["JSON Response Emitted"]
    Response --> SecureWipe["Explicit Buffer Overwrite & Garbage Collection"]
    SecureWipe --> ZeroDisk["Zero Bytes Written to Persistent Disk"]
```

1. **In-Memory Buffering:** Uploaded streams are accepted directly into byte arrays in RAM. Images are never written to swap or persistent SSD storage during standard production analysis.
2. **Explicit Memory Sanitization:** Upon completion of response generation, image buffers are cleared from memory.
3. **No Model Training:** Zenith connects to Google Gemini via paid Enterprise / Vertex API tiers with strict zero-data-retention and zero-training guarantees. User visual payloads are never used to train foundation models.

### 16.2 Ingestion Sanitization & Defense-in-Depth
- **Magic Byte Verification:** Inspects the first 16 bytes of the stream (`image/jpeg`, `image/png`, `image/webp`, `image/heic`). File extensions (`.jpg`, `.png`) are untrusted.
- **Pixel Flood / Decompression Bomb Protection:** Hard limit of $100\text{ Megapixels}$ ($10,000 \times 10,000\text{ px}$). Images exceeding this decompression threshold are rejected prior to memory decoding.
- **Sanitized Logging:** Application logs record only `analysis_id`, `latency_ms`, `score`, and `finding_types`. Bounding box text, detected names, passwords, and base64 payloads are scrubbed from log streams.

---

## 17. Zenith System UX & Design System

### 17.1 Design Philosophy: Cyber Intelligence Workbench
Zenith's own interface is an **expert cybersecurity research and evaluation platform** (inspired by the tactile density, speed, and precision of Linear, Raycast, Wireshark, and Datadog). It rejects playful consumer tropes in favor of an authoritative, high-contrast, information-dense operational console.

### 17.2 Color Design Tokens
```
+----------------------------------------------------------------------------------------------------+
|                                    ZENITH COLOR DESIGN TOKENS                                      |
+---------------------+-------------------+----------------------------------------------------------+
| Token Name          | Hex Code          | Semantic Role & Surface Mapping                          |
+---------------------+-------------------+----------------------------------------------------------+
| `color-bg-base`     | `#0A0E17`         | Deep Canvas Background: Obsidian Space                   |
| `color-surface-sub` | `#111827`         | Secondary Surfaces: Sidebars, Drawer Backdrops           |
| `color-card-base`   | `#182234`         | Elevated Card Surfaces: Containers, Inspector Panes      |
| `color-card-hover`  | `#1F2D44`         | Interactive Card Hover State                             |
| `color-border-sub`  | `#26354D`         | Structural Dividers: 1px Subdued Borders                 |
| `color-border-glow` | `#38BDF8`         | Active Selection Border: Neon Cyan Focus Ring            |
| `color-accent-cyan` | `#00E5FF`         | Primary Accent: Scanner Sweeps, Key Highlights           |
| `color-accent-blue` | `#3B82F6`         | Secondary Accent: Location Indicators, Informational     |
| `color-accent-indig`| `#6366F1`         | Interactive Controls: Buttons, Primary Toggles           |
| `color-risk-low`    | `#10B981`         | Low Severity (0-25): Emerald Safe Shield                 |
| `color-risk-mod`    | `#F59E0B`         | Moderate Severity (26-50): Amber Caution                 |
| `color-risk-high`   | `#F97316`         | High Severity (51-75): Vivid Coral Threat Warning        |
| `color-risk-crit`   | `#EF4444`         | Critical Severity (76-100): Electric Crimson Breach     |
| `color-text-main`   | `#F8FAFC`         | Primary Typography: High Contrast Off-White              |
| `color-text-muted`  | `#94A3B8`         | Secondary Typography: Slate Grey Body & Labels           |
+---------------------+-------------------+----------------------------------------------------------+
```

### 17.3 Typography Standards
- **Display & Monospace:** JetBrains Mono (`JetBrains Mono`, monospace) for all numerical scores, coordinates, API IDs, tokens, and telemetry tickers.
- **Interface & Proportional Body:** Inter (`Inter`, sans-serif) for system navigation, analytical summaries, threat narratives, and action checklists.
- **Hierarchy Scale:**
  - Metric Hero: `3.5rem` (`56px`), Weight 800, Monospace, Tracking `-0.02em`.
  - Section Header: `1.25rem` (`20px`), Weight 700, Inter, Tracking `-0.01em`.
  - Data Table Label: `0.75rem` (`12px`), Weight 600, Monospace, Uppercase, Tracking `+0.05em`.
  - Body Text: `0.875rem` (`14px`), Weight 400, Line Height `1.5`, Inter.

---

## 18. Screen-by-Screen Specifications

### 18.1 Screen Registry Overview
The Zenith System Console comprises 12 dedicated, interconnected workstations:

```mermaid
graph TD
    Nav[Primary Global Navigation] --> S1["1. System Overview Dashboard"]
    Nav --> S2["2. Submit Image for Analysis"]
    Nav --> S3["3. Analysis Results"]
    Nav --> S4["4. Findings Explorer"]
    Nav --> S5["5. Evidence & Inference Inspector"]
    Nav --> S6["6. Risk Breakdown Matrix"]
    Nav --> S7["7. Test Case Library"]
    Nav --> S8["8. Test Case Detail & Execution"]
    Nav --> S9["9. Evaluation & Benchmark Dashboard"]
    Nav --> S10["10. API Integration & Inspector"]
    Nav --> S11["11. System Configuration"]
    Nav --> S12["12. Error & Diagnostics State"]

    S2 -->|Dispatches Scan| S3
    S3 -->|Deep Dive Finding| S4
    S3 -->|Inspect Threat Graph| S5
    S7 -->|Select Case| S8
    S8 -->|Batch Benchmark| S9
```

### 18.2 Detailed Screen Specifications

#### Screen 1: System Overview Dashboard
- **Purpose:** Central operational status board monitoring system throughput, API health, risk severity distributions, and threat statistics.
- **Main Layout:** 3-tier grid. Top: Key metrics strip (Total Scans, Mean Processing Latency, Critical Interceptions, Model Uptime). Middle: Live Threat Severity Gauge & Real-time Scan Feed. Bottom: Category Vulnerability Breakdown Bar Charts.
- **Key Components:** Radial OPSEC Gauge, SVG sparklines, tabular live feed with status pills (`CRITICAL`, `SAFE`).
- **Interactions:** Clicking any recent scan navigates to Screen 3 (Analysis Results).

#### Screen 2: Submit Image for Analysis
- **Purpose:** Manual ingestion workbench for security researchers and QA engineers to upload test images.
- **Main Layout:** Split-view. Left: Drag-and-drop file target with support for high-resolution images, format badges, and sensitivity slider (`Conservative`, `Balanced`, `Maximum OPSEC`). Right: EXIF preview table and pipeline module selectors (Toggle OCR, Toggle Barcodes, Toggle Gemini).
- **Interactions:** Drop image $\implies$ client parses EXIF locally $\implies$ click "Execute Privacy Audit" $\implies$ transitions to real-time scanning HUD.

#### Screen 3: Analysis Results
- **Purpose:** Primary diagnostic report screen presenting the comprehensive assessment of an image.
- **Main Layout:** Dual-column. Left: Interactive Image Canvas with zoom/pan and toggleable color-coded bounding boxes. Right: Radial Risk Meter (0-100), Executive Summary card, 5-Category Progress Bars, and Primary Remediation Banner.
- **Interactions:** Hovering over a bounding box highlights the corresponding finding in the list. Tapping "Open Privacy Shield" opens the Auto-Redact preview modal.

#### Screen 4: Findings Explorer
- **Purpose:** Detailed tabular and card-based catalog of every atomic finding detected in the visual asset.
- **Main Layout:** Multi-column searchable data table with sorting by Severity, Category, and Confidence.
- **Information Displayed:** Finding ID, Category Badge, Detection Source (e.g., `barcode_decoder`), Evidence Text, Confidence %, Normalized BBox.
- **Interactions:** Filter chips for 5 categories; click row to expand forensic crop preview.

#### Screen 5: Evidence and Inference Inspector
- **Purpose:** Visualizes the adversarial threat deduction graph (how direct evidence leads to contextual inferences).
- **Main Layout:** Node-link Directed Acyclic Graph (DAG) canvas. Left nodes: Direct Evidence (T1/T2). Center nodes: Contextual Deductions (T3). Right nodes: Adversarial Weaponization Vectors (T4).
- **Interactions:** Click node to inspect supporting visual tokens and confidence calibrations.

#### Screen 6: Risk Breakdown Matrix
- **Purpose:** Mathematical transparency console displaying the exact calculus and variable weights used to derive the score.
- **Main Layout:** 5 Category Deep-Dive Cards showing raw formula terms: $S$, $E$, $V$, $C$, Category Probabilistic Sum, Dominance Contribution, and Synergy Amplifier ($\Gamma$).
- **Interactions:** Sliders to simulate weight calibrations and observe score impacts in real time.

#### Screen 7: Test Case Library
- **Purpose:** Test management hub indexing all 17 automated test suites and synthetic scenario fixtures.
- **Main Layout:** Filterable card grid categorized by test class (Clean, Credentials, Identity, Location, etc.) with thumbnail previews and expected severity badges.
- **Interactions:** Search by tag; "Run All Tests" batch button; click card to open Screen 8.

#### Screen 8: Test Case Detail & Execution
- **Purpose:** Deep-dive inspection of a specific test scenario with side-by-side Ground Truth vs. Actual Execution outputs.
- **Main Layout:** Split comparison view. Left: Ground-truth annotations and expected score range. Right: Live execution output, IoU overlap score, score delta ($\Delta\Omega$), and pass/fail assertion pill.
- **Interactions:** "Execute Assertion" button; edit test annotations modal.

#### Screen 9: Evaluation and Benchmark Dashboard
- **Purpose:** Aggregate regression analytics and ML performance tracking.
- **Main Layout:** Analytics dashboard displaying Precision-Recall curves, Confusion Matrix, Expected Calibration Error (ECE) histogram, and latency $P_{50}/P_{95}/P_{99}$ trends across Git commits.
- **Interactions:** Filter by engine version or date range; export benchmark CSV report.

#### Screen 10: API Integration and Request Inspector
- **Purpose:** Developer portal for Team Member 1 (Camera Client) to test endpoints, generate mock payloads, and inspect live network traffic.
- **Main Layout:** Interactive API sandbox with cURL generator, Swagger/OpenAPI documentation, and a real-time WebSocket traffic inspector logging inbound client requests and outbound JSON responses.
- **Interactions:** "Send Sample Payload", copy cURL, toggle mock response mode.

#### Screen 11: System Configuration
- **Purpose:** Administrative console for managing foundation model API keys, fallback thresholds, and timeouts.
- **Main Layout:** Settings panel with encrypted Secret Key input, Active Model selector (`gemini-2.5-flash`, `gemini-1.5-flash`), Pipeline Timeout sliders, and Default Sensitivity mode.
- **Interactions:** "Test Key Connectivity" ping test; "Save Preferences".

#### Screen 12: Error and Processing States
- **Purpose:** Standardized UI states for asynchronous scanning, network timeouts, unprocessable files, and fallback states.
- **Visuals:** 4-stage laser scanner HUD animation during processing; clear warning banners for `degraded_analysis: true` when foundation model falls back to local CV.

---

## 19. Technical Stack and Project Structure

### 19.1 Selected Technical Architecture
To achieve decoupling, high-performance computer vision, and seamless integration with Google GenAI SDKs, Zenith's backend core is specified as a **high-throughput Python/FastAPI service**, while the system management console is delivered via **Flutter Web / Material 3 Dark** (reusing Zenith's existing visual design system).

```
+----------------------------------------------------------------------------------------------------+
|                                    TECHNOLOGY STACK JUSTIFICATION                                  |
+-------------------+----------------------------+---------------------------------------------------+
| Layer             | Selected Technology        | Engineering Rationale                            |
+-------------------+----------------------------+---------------------------------------------------+
| API Service       | Python 3.11 + FastAPI      | Native async IO, Pydantic v2 schemas, fastest integration|
|                   | + Uvicorn ASGI             | with Pyzbar, OpenCV, and official google-genai SDK|
+-------------------+----------------------------+---------------------------------------------------+
| Computer Vision   | Pillow, OpenCV, Pyzbar,    | Production-grade deterministic EXIF parsing,      |
|                   | Tesseract / EasyOCR        | 1D/2D barcode recovery, and optical binarization |
+-------------------+----------------------------+---------------------------------------------------+
| Multimodal AI     | Google GenAI Python SDK    | Native support for `gemini-2.5-flash`, structured  |
|                   | (`google-genai`)           | JSON response schema enforcement, low latency     |
+-------------------+----------------------------+---------------------------------------------------+
| System Console UI | Flutter 3.16+ (Dart 3)     | Reuses existing codebase assets, cyber theme,     |
|                   | Riverpod 3 + Flutter Web   | glassmorphic cards, and radial risk gauges        |
+-------------------+----------------------------+---------------------------------------------------+
| Quality Assurance | Pytest + Flutter Test      | Comprehensive unit, integration, and CI regression|
+-------------------+----------------------------+---------------------------------------------------+
```

### 19.2 Target Project Directory Structure
```
zenith/
├── README.md                           # Master Project Overview
├── ZENITH_SYSTEM_SPECIFICATION.md      # Authoritative Architecture Blueprint (This Document)
├── pubspec.yaml                        # System Web Console (Flutter UI) Manifest
├── analysis_options.yaml               # Flutter Lints
│
├── core_engine/                        # Zenith Headless Intelligence Engine (FastAPI)
│   ├── pyproject.toml                  # Python Dependencies (FastAPI, google-genai, pyzbar)
│   ├── Dockerfile                      # Containerized Deployment Manifest
│   ├── main.py                         # FastAPI Application Entrypoint & Middleware
│   ├── api/
│   │   ├── v1/
│   │   │   ├── router.py               # API Route Aggregator
│   │   │   ├── endpoints/
│   │   │   │   ├── analyze.py          # POST /v1/analyze Handler
│   │   │   │   ├── rescan.py           # POST /v1/rescan Handler
│   │   │   │   └── health.py           # GET /v1/health Diagnostics
│   ├── pipeline/
│   │   ├── preprocessor.py             # Magic byte validation & EXIF inspection
│   │   ├── deterministic_cv.py         # Pyzbar barcode decoding & Tesseract OCR
│   │   ├── gemini_adapter.py           # Google GenAI SDK interface with JSON schema
│   │   ├── normalizer.py               # Spatial IoU deduplication & clustering
│   │   ├── inference_engine.py         # Attacker evidence DAG deduction
│   │   ├── risk_calculator.py          # Deterministic mathematical scoring engine
│   │   └── mitigation_planner.py       # Remediation checklist generator
│   ├── schemas/
│   │   ├── requests.py                 # Pydantic Inbound Request Schemas
│   │   └── responses.py                # Pydantic Outbound Audit Report Schemas
│   └── tests/
│       ├── test_risk_calculator.py     # Deterministic math unit tests
│       ├── test_pipeline_integration.py# End-to-end synthetic image tests
│       └── benchmark_runner.py         # CI Evaluation harness & ECE metrics
│
├── lib/                                # Zenith Research Console (Flutter UI)
│   ├── main.dart                       # Web Console Entrypoint
│   ├── core/                           # Cyber Theme, Constants, Tokens
│   ├── models/                         # Client Data Models (Matching API Schemas)
│   ├── providers/                      # Riverpod State Management
│   ├── screens/                        # 12 Research & Evaluation Screens
│   └── services/                       # HTTP API Client communicating with core_engine
│
└── assets/
    └── samples/                        # Ground-truth synthetic evaluation fixtures
```

---

## 20. Data Models and State Management

### 20.1 Core Domain Entity Relations

```mermaid
classDiagram
    class PrivacyAuditReport {
        +String analysisId
        +DateTime timestamp
        +int overallScore
        +RiskLevel riskLevel
        +Map categoryScores
        +List~DetectedFinding~ findings
        +List~InferredInsight~ inferences
        +List~Recommendation~ recommendations
        +bool degradedAnalysis
        +int latencyMs
    }

    class DetectedFinding {
        +String findingId
        +ExposureCategory category
        +String infoType
        +String description
        +DetectionSource source
        +String evidenceText
        +BoundingBox boundingBox
        +double confidence
        +int baseSeverity
        +double visibility
    }

    class InferredInsight {
        +String inferenceId
        +ExposureCategory category
        +List~String~ evidenceIds
        +String directObservation
        +String inferredDeduction
        +String threatVector
        +double confidence
        +EpistemicLevel level
    }

    class Recommendation {
        +String recommendationId
        +String findingRef
        +RiskLevel priority
        +String title
        +String action
        +ActionType actionType
        +int riskReduction
        +bool automatable
    }

    class BoundingBox {
        +double top
        +double left
        +double width
        +double height
        +toRect()
    }

    PrivacyAuditReport "1" *-- "many" DetectedFinding
    PrivacyAuditReport "1" *-- "many" InferredInsight
    PrivacyAuditReport "1" *-- "many" Recommendation
    DetectedFinding "1" o-- "0..1" BoundingBox
```

---

## 21. Error Handling, Fallbacks, and Reliability

### 21.1 Tiered Fallback Architecture
Zenith handles external model failures with a robust, multi-tier fallback architecture:

```mermaid
flowchart TD
    Req["Incoming Image Analysis Request"] --> Pre["Local Preprocessing & EXIF Parser"]
    Pre --> LocalCV["Deterministic Tools (Barcodes & OCR)"]
    
    LocalCV --> CheckAPI{"Call Gemini Vision API"}
    CheckAPI -- Success (200 OK) --> Fusion["Full Multimodal Synthesis"]
    
    CheckAPI -- Timeout (>5s) or HTTP 5xx --> Fallback["Graceful Fallback Mode"]
    CheckAPI -- Malformed JSON --> CleanJSON{"Regex JSON Clean"}
    CleanJSON -- Recovered --> Fusion
    CleanJSON -- Failed --> Fallback
    
    Fallback --> DeterministicScoring["Score Exclusively on Local Findings<br/>(EXIF + Barcodes + OCR Tokens)"]
    DeterministicScoring --> DegradedReport["Emit Audit Report with<br/>degraded_analysis: true"]
    Fusion --> FullReport["Emit Complete Audit Report"]
```

### 21.2 Circuit Breaker & Rate Limiting
- **Gemini Circuit Breaker:** If Gemini Vision returns three consecutive HTTP 503 or 429 errors, the adapter enters the `OPEN` state for 30 seconds, instantly routing incoming requests to the deterministic fallback engine without waiting for network timeouts.
- **Client Rate Limiting:** Enforces 60 requests per minute per client IP using a Redis/In-Memory sliding token bucket.

---

## 22. Testing Strategy & Quality Assurance

### 22.1 Testing Pyramid
1. **Unit Tests (Coverage Target: 95%):**
   - Mathematical risk-scoring formulation (verifying monotonicity, bounds $[0, 100]$, and dominance).
   - Coordinate normalization and clamping functions.
   - Regex token matchers (validating against synthetic PNRs, API keys, and email addresses).
2. **Integration Tests (Coverage Target: 90%):**
   - End-to-end API pipeline with mocked Gemini Vision responses.
   - Error handling workflows (verifying graceful fallback when Gemini fails).
   - Rescan delta calculation assertions.
3. **Automated Benchmark Evaluations:**
   - Nightly CI execution across the 17 benchmark test classes.
   - Enforcing calibration thresholds ($\text{ECE} \le 0.12$, $\text{FNR}_{\text{credentials}} = 0\%$).

---

## 23. Team Responsibilities & Organizational Boundaries

To guarantee independent, parallel development across the project team, boundaries are formally partitioned as follows:

```
+----------------------------------------------------------------------------------------------------+
|                                    TEAM RESPONSIBILITY MATRIX                                      |
+--------------------+-----------------------------+-------------------------------------------------+
| Team Member        | Primary Functional Domain   | Clear Boundaries & Expected Deliverables        |
+--------------------+-----------------------------+-------------------------------------------------+
| **ME**             | Zenith Core Architecture    | - Headless Intelligence API & Risk Engine       |
| (Architect & Lead) | AI Pipeline & Scoring       | - Mathematical risk calculus formulation        |
|                    | Research Console UI         | - Test-case evaluation harness & schemas        |
|                    |                             | - Zenith Web Console (Screens 1 - 12)           |
+--------------------+-----------------------------+-------------------------------------------------+
| **TEAM MEMBER 1**  | External Camera Client      | - Independent mobile camera app (iOS/Android)   |
| (Client Engineer)  | Capture UX & Image Delivery | - Shutter, viewfinder, gallery picker UI        |
|                    | Local Mitigation Rendering  | - Consumes Zenith API (`POST /v1/analyze`)      |
|                    |                             | - Renders returned bounding boxes & score dials |
+--------------------+-----------------------------+-------------------------------------------------+
| **TEAM MEMBER 2**  | Visual Brand Identity       | - Zenith logo assets (SVG, vector, icon sets)   |
| (Brand Designer)   | Design Tokens & Typography  | - Brand guidelines (color palette, typography)  |
|                    | Presentation Graphics       | - App launcher icons and visual design system   |
+--------------------+-----------------------------+-------------------------------------------------+
| **TEAM MEMBER 3**  | Product Storytelling        | - Slide deck & demonstration narrative          |
| (Presenter & PM)   | Threat Scenarios & Pitch    | - Real-world OPSEC attack case studies          |
|                    | Evaluation Metrics Display  | - Live demonstration script & user journey walkthrough|
+--------------------+-----------------------------+-------------------------------------------------+
```

### 23.1 Interface Contract with Team Member 1 (Camera Client)
- **Zero Business Logic on Mobile:** The camera app must **never** calculate risk scores, parse EXIF data, or run Gemini API calls directly. It simply captures an image, sends it via `multipart/form-data` to `POST /v1/analyze`, and renders the returned JSON findings and bounding boxes.
- **Mock Service Provision:** The backend provides a mock response mode (`X-Zenith-Mock: true`) allowing Team Member 1 to build and test all UI screens without consuming live Gemini tokens.

---

## 24. Phased Implementation Roadmap

```mermaid
gantt
    title Zenith Engineering Implementation Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1: Core Analysis
    Deterministic CV & Preprocessing     :p1a, 2026-10-15, 7d
    Gemini Vision Structured Adapter     :p1b, after p1a, 5d
    section Phase 2: Risk Engine
    Deterministic Math Scoring Calculus  :p2a, after p1b, 6d
    IoU Deduplication & Inference DAG    :p2b, after p2a, 5d
    section Phase 3: Client API
    FastAPI Service & Endpoints          :p3a, after p2b, 5d
    Contract Testing with Camera Client  :p3b, after p3a, 4d
    section Phase 4: Test Framework
    Ground-Truth Synthetic Fixtures      :p4a, after p3b, 5d
    Automated Benchmark CI Pipeline      :p4b, after p4a, 4d
    section Phase 5: System UX
    Web Console Dashboard & Inspector    :p5a, after p4b, 8d
    Auto-Redact Studio Integration       :p5b, after p5a, 5d
    section Phase 6: Calibration
    ECE Calibration & Stress Testing     :p6a, after p5b, 7d
    Production Deployment & Freeze       :p6b, after p6a, 4d
```

### Milestone Deliverables

#### Phase 1: Core Image Analysis Pipeline (Weeks 1 - 2)
- Deliverable: Headless preprocessing pipeline parsing EXIF metadata, decoding barcodes via Pyzbar, and integrating the `google-genai` SDK with strict JSON schemas.
- Validation: 100% parse success on synthetic sample fixtures.

#### Phase 2: Deterministic Risk Scoring Engine (Weeks 2 - 3)
- Deliverable: Mathematical formulation implemented in pure Python with spatial IoU deduplication and Attacker Inference graph synthesis.
- Validation: Zero score flakiness; 100% reproducible numerical outputs on identical image inputs.

#### Phase 3: Client Integration API (Weeks 3 - 4)
- Deliverable: Production FastAPI service exposing `/v1/analyze`, `/v1/rescan`, and `/v1/health` with OpenAPI documentation and mock modes for Team Member 1.
- Validation: Camera app successfully uploads an image and renders returned bounding boxes.

#### Phase 4: Benchmark & Evaluation Framework (Weeks 4 - 5)
- Deliverable: Automated test runner executing across the 17 benchmark classes with precision-recall and ECE reporting.
- Validation: Zero false negatives on synthetic credentials; test suite running in CI.

#### Phase 5: Zenith System Management Console (Weeks 5 - 6)
- Deliverable: Flutter Web Research Console implementing Screens 1 through 12.
- Validation: Researchers can inspect live scans, view threat graphs, and execute test cases.

#### Phase 6: Calibration & Hardening (Weeks 6 - 7)
- Deliverable: Final weight tuning, circuit breaker verification, and latency optimization.
- Validation: $P_{95}$ latency $\le 3,500\text{ ms}$; security freeze.

---

## 25. System Acceptance Criteria

The system is certified production-ready when it meets all of the following criteria:

1. **Decoupled Architecture:** The backend operates as a standalone service with zero runtime reliance on the camera app.
2. **Deterministic Mathematical Scoring:** Final risk scores (0-100) are computed exclusively by Zenith's mathematical scoring engine, with zero score flakiness.
3. **Hybrid CV Execution:** All 1D/2D barcodes are deterministically decoded via ZBar, and EXIF tags are parsed before foundation model query.
4. **Attacker Inference Grounding:** Inferences are derived strictly from verified evidence anchors with an explicit causal path.
5. **Zero Secret Leakage:** The client application contains zero Gemini API keys. All credentials reside securely on the backend server.
6. **Graceful Degradation:** When Gemini Vision times out or fails, the system successfully falls back to local CV and returns an audit report marked `degraded_analysis: true`.
7. **Performance Gate:** End-to-end processing latency for a 1080p image satisfies $P_{95} \le 3,500\text{ ms}$.
8. **Automated Benchmark Gate:** All 17 automated test suite classes pass with zero false negatives on critical credentials.

---

## 26. Known Limitations and Open Research Questions

### 26.1 Technical Limitations
- **Severely Degraded Visual Data:** If a barcode or character string is obscured by motion blur or heavy compression artifacts ($\le 3\text{ px}$ stroke width), optical recovery fails. The system flags such areas as "Occluded Potential Risk" rather than asserting verified text.
- **Steganographic Content:** Zenith inspects visible pixel structures and standard EXIF metadata; it does not perform deep statistical steganography analysis to detect hidden payloads in least-significant bits.
- **Multilingual OCR Coverage:** Local OCR accuracy drops on non-Latin scripts (e.g., Cyrillic, Kanji) unless localized language dictionaries are loaded.

### 26.2 Open Research Questions
- **Dynamic Weight Calibration via Active Learning:** Can the dominance coefficient ($\alpha$) and sensitivity weights ($S_k$) be dynamically optimized using Bayesian optimization over empirical user feedback without introducing non-deterministic drift?
- **Client-Side WASM Pre-Filtering:** Can a lightweight WebAssembly/TFLite model run on the camera client to detect faces and credit cards locally in real time before network transmission?

---

## 27. Future Expansion & Evolution Vectors

While outside the MVP scope, Zenith's modular architecture is designed to accommodate the following future expansions:

1. **Video Stream & Temporal Frame Analysis:** Expanding the ingestion pipeline to sample video keyframes at $1\text{ fps}$, tracking moving threat vectors (e.g., an ID badge swinging around a neck) across a temporal timeline.
2. **Browser Extension Pre-Publish Hook:** A Chromium extension that intercepts file upload dialogs on social media sites (Twitter/X, LinkedIn, Reddit), sending images to Zenith for an instant pre-publish privacy audit.
3. **Automated Cryptographic Redaction SDK:** A mobile rendering SDK that applies cryptographic, irreversible client-side pixel deletion over Zenith bounding boxes before the photo leaves the phone.
4. **Autonomous Reverse-Search Vulnerability Scorer:** Simulating how easily a cropped background could be geolocated by AI search engines without actually performing real-world searches.

---

## 28. Glossary of Terms

- **Aztec Code:** A 2D matrix barcode standard widely used in aviation boarding passes (IATA BCBP).
- **Bounding Box (BBox):** Normalized coordinates (`top`, `left`, `width`, `height` in $[0.0, 1.0]$) delineating a visual element's boundaries.
- **Deterministic Scoring:** A mathematical calculation that produces identical, reproducible numerical outputs given the same inputs.
- **EXIF (Exchangeable Image File Format):** Metadata embedded in JPEG/TIFF files recording camera settings, timestamps, and GPS coordinates.
- **Expected Calibration Error (ECE):** A metric measuring the difference between predicted confidence and actual empirical accuracy.
- **Intersection over Union (IoU):** The ratio of the area of overlap to the area of union between two bounding boxes.
- **OPSEC (Operational Security):** The process of identifying and protecting critical personal or operational information from adversary deduction.
- **OSINT (Open-Source Intelligence):** Intelligence gathered from publicly accessible sources such as photos, maps, and public records.
- **PNR (Passenger Name Record):** A 6-character alphanumeric booking code used by airlines to manage travel itineraries.
- **Probabilistic Sum:** A bounded aggregation function $1 - \prod(1 - r_i)$ that models combined independent risk while preventing scores from exceeding 100.
