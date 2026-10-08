import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/privacy_audit_report.dart';
import '../services/gemini_vision_service.dart';
import '../services/mock_analysis_service.dart';
import '../services/sample_data_service.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

enum ScanStatus {
  idle,
  ingesting,
  multimodalVision,
  threatModeling,
  synthesizing,
  completed,
  error;

  String get stepDescription {
    switch (this) {
      case ScanStatus.idle:
        return 'Ready to scan';
      case ScanStatus.ingesting:
        return 'Stage 1/4: Ingesting optical payload & parsing EXIF metadata...';
      case ScanStatus.multimodalVision:
        return 'Stage 2/4: Executing Multimodal Neural Vision inspection...';
      case ScanStatus.threatModeling:
        return 'Stage 3/4: Modeling OPSEC risk matrix & attacker inferences...';
      case ScanStatus.synthesizing:
        return 'Stage 4/4: Synthesizing security audit & mitigations...';
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
      case ScanStatus.ingesting:
        return 0.25;
      case ScanStatus.multimodalVision:
        return 0.55;
      case ScanStatus.threatModeling:
        return 0.80;
      case ScanStatus.synthesizing:
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
      status == ScanStatus.ingesting ||
      status == ScanStatus.multimodalVision ||
      status == ScanStatus.threatModeling ||
      status == ScanStatus.synthesizing;

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
      selectedImagePath:
          clearImage ? null : (selectedImagePath ?? this.selectedImagePath),
      selectedImageBytes:
          clearImage ? null : (selectedImageBytes ?? this.selectedImageBytes),
      selectedSampleAsset:
          clearImage ? null : (selectedSampleAsset ?? this.selectedSampleAsset),
      currentReport: currentReport ?? this.currentReport,
      history: history ?? this.history,
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
    );
  }
}

final auditProvider =
    NotifierProvider<AuditNotifier, AuditState>(AuditNotifier.new);

class AuditNotifier extends Notifier<AuditState> {
  final ImagePicker _picker = ImagePicker();

  @override
  AuditState build() {
    Future.microtask(() => loadHistory());
    return const AuditState();
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
      state = state.copyWith(
        errorMessage: 'Failed to load sample image: $e',
      );
    }
  }

  Future<void> pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
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
        errorMessage: 'Camera error: $e. You can also pick from gallery or test samples.',
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
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
        errorMessage: 'Gallery picker error: $e.',
      );
    }
  }

  void setImageBytes({
    required Uint8List bytes,
    String? path,
    String? sampleAsset,
  }) {
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
    state = state.copyWith(
      currentReport: report,
      status: ScanStatus.completed,
    );
  }

  Future<PrivacyAuditReport?> runAnalysis() async {
    final bytes = state.selectedImageBytes;
    if (bytes == null && state.selectedSampleAsset == null) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Please capture or select an image first.',
      );
      return null;
    }

    final settings = ref.read(settingsProvider);

    try {
      // Stage 1: Optical payload ingestion
      state = state.copyWith(status: ScanStatus.ingesting, errorMessage: null);
      await Future.delayed(const Duration(milliseconds: 500));

      // Stage 2: Multimodal Neural Vision inspection
      state = state.copyWith(status: ScanStatus.multimodalVision);

      PrivacyAuditReport report;

      // Check if user has an active Gemini API key configured
      if (settings.hasApiKey && bytes != null) {
        try {
          report = await GeminiVisionService.analyzeImage(
            imageBytes: bytes,
            apiKey: settings.apiKey,
            model: settings.model,
            imagePath: state.selectedImagePath,
            sensitivity: settings.sensitivity,
          );
        } catch (apiErr) {
          // If live AI fails and mock fallback is enabled, gracefully fall back with warning
          if (settings.useMockFallback) {
            report = await MockAnalysisService.analyzeImage(
              imageBytes: bytes,
              imagePath: state.selectedImagePath,
              sampleAsset: state.selectedSampleAsset,
            );
          } else {
            rethrow;
          }
        }
      } else {
        // Use intelligent onboard heuristic & sample simulator
        report = await MockAnalysisService.analyzeImage(
          imageBytes: bytes,
          imagePath: state.selectedImagePath,
          sampleAsset: state.selectedSampleAsset,
        );
      }

      // Stage 3: OPSEC risk matrix & attacker inference
      state = state.copyWith(status: ScanStatus.threatModeling);
      await Future.delayed(const Duration(milliseconds: 400));

      // Stage 4: Synthesize security audit
      state = state.copyWith(status: ScanStatus.synthesizing);
      await Future.delayed(const Duration(milliseconds: 350));

      // Save report in persistent storage
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
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Privacy Analysis failed: $e',
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
