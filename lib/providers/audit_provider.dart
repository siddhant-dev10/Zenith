import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/privacy_engine/api/zenith_api_contract.dart';
import '../core/privacy_engine/pipeline/zenith_analysis_pipeline.dart';
import '../core/privacy_engine/providers/vision_analysis_provider.dart';
import '../core/privacy_engine/validation/image_validator.dart';
import '../models/detected_element.dart';
import '../models/exposure_category.dart';
import '../models/inferred_insight.dart';
import '../models/privacy_audit_report.dart';
import '../models/recommendation.dart';
import '../models/risk_level.dart';
import '../services/sample_data_service.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

enum ScanStatus {
  idle,
  validating,
  inspecting,
  analyzingSensitiveInfo,
  calculatingRisk,
  preparingRecommendations,
  completed,
  error;

  String get stepDescription {
    switch (this) {
      case ScanStatus.idle:
        return 'Ready to scan';
      case ScanStatus.validating:
        return 'Stage 1/5: Validating image format & magic bytes...';
      case ScanStatus.inspecting:
        return 'Stage 2/5: Inspecting optical payload & metadata...';
      case ScanStatus.analyzingSensitiveInfo:
        return 'Stage 3/5: Analyzing sensitive information & credentials...';
      case ScanStatus.calculatingRisk:
        return 'Stage 4/5: Deterministically calculating privacy risk score...';
      case ScanStatus.preparingRecommendations:
        return 'Stage 5/5: Preparing actionable mitigation checklist...';
      case ScanStatus.completed:
        return 'Security assessment finalized';
      case ScanStatus.error:
        return 'Analysis encountered an error';
    }
  }

  double get progressValue {
    switch (this) {
      case ScanStatus.idle:
        return 0.0;
      case ScanStatus.validating:
        return 0.20;
      case ScanStatus.inspecting:
        return 0.40;
      case ScanStatus.analyzingSensitiveInfo:
        return 0.65;
      case ScanStatus.calculatingRisk:
        return 0.85;
      case ScanStatus.preparingRecommendations:
        return 0.95;
      case ScanStatus.completed:
        return 1.0;
      case ScanStatus.error:
        return 0.0;
    }
  }
}

class AuditState {
  final ScanStatus status;
  final String? selectedImagePath;
  final Uint8List? selectedImageBytes;
  final String? selectedSampleAsset;
  final PrivacyAuditReport? currentReport;
  final List<PrivacyAuditReport> history;
  final String? errorMessage;
  final Map<String, dynamic> stats;

  const AuditState({
    this.status = ScanStatus.idle,
    this.selectedImagePath,
    this.selectedImageBytes,
    this.selectedSampleAsset,
    this.currentReport,
    this.history = const [],
    this.errorMessage,
    this.stats = const {},
  });

  bool get isScanning =>
      status == ScanStatus.validating ||
      status == ScanStatus.inspecting ||
      status == ScanStatus.analyzingSensitiveInfo ||
      status == ScanStatus.calculatingRisk ||
      status == ScanStatus.preparingRecommendations;

  bool get hasImageSelected =>
      selectedImageBytes != null ||
      selectedImagePath != null ||
      selectedSampleAsset != null;

  AuditState copyWith({
    ScanStatus? status,
    String? selectedImagePath,
    Uint8List? selectedImageBytes,
    String? selectedSampleAsset,
    PrivacyAuditReport? currentReport,
    List<PrivacyAuditReport>? history,
    String? errorMessage,
    Map<String, dynamic>? stats,
    bool clearImage = false,
  }) {
    return AuditState(
      status: status ?? this.status,
      selectedImagePath: clearImage
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      selectedImageBytes: clearImage
          ? null
          : (selectedImageBytes ?? this.selectedImageBytes),
      selectedSampleAsset: clearImage
          ? null
          : (selectedSampleAsset ?? this.selectedSampleAsset),
      currentReport: currentReport ?? this.currentReport,
      history: history ?? this.history,
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
    );
  }
}

final auditProvider = NotifierProvider<AuditNotifier, AuditState>(
  AuditNotifier.new,
);

class AuditNotifier extends Notifier<AuditState> {
  final ImagePicker _picker = ImagePicker();

  @override
  AuditState build() {
    Future.microtask(() => loadHistory());
    return const AuditState();
  }

  IZenithClient get apiClient {
    final settings = ref.read(settingsProvider);
    if (settings.useRemoteBackend) {
      return ZenithHttpClient(baseUrl: settings.backendUrl);
    }
    return ZenithLocalClient();
  }

  Future<void> loadHistory() async {
    final list = await StorageService.loadHistory();
    final stats = await StorageService.getAuditStats();
    state = state.copyWith(history: list, stats: stats);
  }

  void selectSample(SampleScenario scenario) async {
    try {
      final bytes = await rootBundle.load(scenario.assetPath);
      final uint8 = bytes.buffer.asUint8List();

      state = state.copyWith(
        selectedSampleAsset: scenario.assetPath,
        selectedImageBytes: uint8,
        selectedImagePath: null,
        status: ScanStatus.idle,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load sample image: $e');
    }
  }

  Future<void> pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final validation = ImageValidator.validate(bytes);
        if (!validation.isValid) {
          state = state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                'Captured image validation failed: ${validation.errorMessage ?? "Invalid image"}. Please retake.',
          );
          return;
        }

        state = state.copyWith(
          selectedImagePath: photo.path,
          selectedImageBytes: bytes,
          selectedSampleAsset: null,
          status: ScanStatus.idle,
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage:
            'Camera access error: $e. You can also pick an image from gallery.',
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final validation = ImageValidator.validate(bytes);
        if (!validation.isValid) {
          state = state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                'Invalid file format or corrupted image: ${validation.errorMessage ?? "Invalid image"}. Only JPEG, PNG, WebP, and HEIC up to 25MB are supported.',
          );
          return;
        }

        state = state.copyWith(
          selectedImagePath: photo.path,
          selectedImageBytes: bytes,
          selectedSampleAsset: null,
          status: ScanStatus.idle,
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Gallery picker error: $e.',
      );
    }
  }

  void setImageBytes({
    required Uint8List bytes,
    String? path,
    String? sampleAsset,
  }) {
    final validation = ImageValidator.validate(bytes);
    if (!validation.isValid) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage:
            'Image validation failed: ${validation.errorMessage ?? "Invalid image"}.',
      );
      return;
    }

    state = state.copyWith(
      selectedImageBytes: bytes,
      selectedImagePath: path,
      selectedSampleAsset: sampleAsset,
      status: ScanStatus.idle,
      errorMessage: null,
    );
  }

  void clearSelection() {
    state = state.copyWith(clearImage: true, status: ScanStatus.idle);
  }

  void setCurrentReport(PrivacyAuditReport report) {
    state = state.copyWith(currentReport: report, status: ScanStatus.completed);
  }

  Future<PrivacyAuditReport?> runAnalysis() async {
    final bytes = state.selectedImageBytes;
    if (bytes == null && state.selectedSampleAsset == null) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Please capture or select a photograph first.',
      );
      return null;
    }

    final effectiveBytes =
        bytes ??
        (await rootBundle.load(state.selectedSampleAsset!)).buffer
            .asUint8List();

    final settings = ref.read(settingsProvider);

    try {
      // Stage 1: Validating image
      state = state.copyWith(status: ScanStatus.validating, errorMessage: null);
      final validation = ImageValidator.validate(effectiveBytes);
      if (!validation.isValid) {
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              'Image validation failed: ${validation.errorMessage ?? "Invalid image"}. Please upload a valid photograph.',
        );
        return null;
      }
      await Future.delayed(const Duration(milliseconds: 250));

      // Stage 2: Inspecting optical payload & metadata
      state = state.copyWith(status: ScanStatus.inspecting);
      await Future.delayed(const Duration(milliseconds: 250));

      PrivacyAuditReport report;

      // Determine backend routing: Remote REST Backend vs Local Intelligence Pipeline
      if (settings.useRemoteBackend) {
        final client = ZenithHttpClient(baseUrl: settings.backendUrl);
        final response = await client
            .analyzeImage(
              AnalyzeImageRequest(
                imageBytes: effectiveBytes,
                sensitivityProfile: settings.sensitivity.toLowerCase(),
              ),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw TimeoutException(
                'Zenith backend at ${settings.backendUrl} timed out after 60 seconds.',
              ),
            );

        // Convert response into local PrivacyAuditReport model
        report = PrivacyAuditReport(
          id: response.analysisId,
          timestamp: response.timestamp,
          imagePath: state.selectedImagePath,
          imageBytes: effectiveBytes,
          sampleAsset: state.selectedSampleAsset,
          overallScore: response.overallScore,
          riskLevel: RiskLevel.fromScore(response.overallScore),
          title: response.headline.isNotEmpty
              ? response.headline
              : '${response.severityLevel} Privacy & Security Exposure',
          summary: response.executiveSummary.isNotEmpty
              ? response.executiveSummary
              : (response.findings.isEmpty
                    ? 'No sensitive visual markers were detected in this photograph.'
                    : 'Automated privacy assessment detected ${response.findings.length} sensitive exposure marker(s).'),
          detectedElements: response.findings
              .map((f) => DetectedElement.fromJson(f))
              .toList(),
          categoryScores: {
            for (final entry in response.categoryScores.entries)
              ExposureCategory.fromString(entry.key): entry.value,
          },
          recommendations: response.recommendations
              .map((r) => Recommendation.fromJson(r))
              .toList(),
          inferredInsights: response.inferences
              .map((inf) => InferredInsight.fromJson(inf))
              .toList(),
          processingStatus: response.processingStatus,
          analysisLimitations: response.analysisLimitations,
          processingErrors: response.processingErrors,
          isLiveAi: !response.degradedAnalysis,
          model: response.model,
          provider: response.provider,
          imageSummary: response.imageSummary,
        );
      } else {
        // Local Intelligence Pipeline
        final IVisionAnalysisProvider provider;
        if (settings.hasApiKey) {
          provider = GeminiVisionProvider(
            apiKey: settings.apiKey,
            model: settings.model,
          );
        } else if (settings.useMockFallback) {
          provider = MockVisionProvider();
        } else {
          throw const VisionProviderException(
            'GEMINI_API_KEY is required for live privacy analysis. Please configure your Gemini API key in Settings or connect to the Zenith server backend.',
            statusCode: 401,
          );
        }

        final pipeline = ZenithAnalysisPipeline(visionProvider: provider);

        // Stage 3: Analyzing sensitive information
        state = state.copyWith(status: ScanStatus.analyzingSensitiveInfo);
        await Future.delayed(const Duration(milliseconds: 300));

        // Stage 4: Calculating risk
        state = state.copyWith(status: ScanStatus.calculatingRisk);
        await Future.delayed(const Duration(milliseconds: 250));

        // Stage 5: Preparing recommendations
        state = state.copyWith(status: ScanStatus.preparingRecommendations);

        report = await pipeline.execute(
          imageBytes: effectiveBytes,
          imagePath: state.selectedImagePath,
          sampleAsset: state.selectedSampleAsset,
          sensitivity: settings.sensitivity,
          model: settings.model,
          allowDegradedFallback: settings.useMockFallback,
        );
      }

      // Persist completed report to storage
      await StorageService.saveReport(report);
      final updatedHistory = await StorageService.loadHistory();
      final updatedStats = await StorageService.getAuditStats();

      state = state.copyWith(
        status: ScanStatus.completed,
        currentReport: report,
        history: updatedHistory,
        stats: updatedStats,
      );

      return report;
    } on TimeoutException catch (te) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Backend timeout: ${te.message}. Please retry.',
      );
      return null;
    } on ImageValidationException catch (ive) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Image validation error: ${ive.message}.',
      );
      return null;
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: cleanMsg,
      );
      return null;
    }
  }

  Future<void> deleteReport(String id) async {
    await StorageService.deleteReport(id);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await StorageService.clearHistory();
    await loadHistory();
  }
}
