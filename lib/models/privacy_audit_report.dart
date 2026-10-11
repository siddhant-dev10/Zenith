import 'dart:typed_data';

import 'detected_element.dart';
import 'exposure_category.dart';
import 'inferred_insight.dart';
import 'recommendation.dart';
import 'risk_level.dart';

class PrivacyAuditReport {
  final String id;
  final DateTime timestamp;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? sampleAsset;
  final int overallScore; // 0 - 100
  final RiskLevel riskLevel;
  final String title;
  final String summary;
  final Map<ExposureCategory, int> categoryScores;
  final List<DetectedElement> detectedElements;
  final List<InferredInsight> inferredInsights;
  final List<Recommendation> recommendations;
  final Map<String, dynamic> exifMetadata;
  final bool isLiveAi;
  final int scanDurationMs;
  final String
  processingStatus; // 'completed', 'degraded', 'partial_failure', 'failed'
  final List<String> analysisLimitations;
  final List<String> processingErrors;

  const PrivacyAuditReport({
    required this.id,
    required this.timestamp,
    this.imagePath,
    this.imageBytes,
    this.sampleAsset,
    required this.overallScore,
    required this.riskLevel,
    required this.title,
    required this.summary,
    required this.categoryScores,
    required this.detectedElements,
    required this.inferredInsights,
    required this.recommendations,
    this.exifMetadata = const {},
    this.isLiveAi = false,
    this.scanDurationMs = 1200,
    this.processingStatus = 'completed',
    this.analysisLimitations = const [],
    this.processingErrors = const [],
  });

  PrivacyAuditReport copyWith({
    String? id,
    DateTime? timestamp,
    String? imagePath,
    Uint8List? imageBytes,
    String? sampleAsset,
    int? overallScore,
    RiskLevel? riskLevel,
    String? title,
    String? summary,
    Map<ExposureCategory, int>? categoryScores,
    List<DetectedElement>? detectedElements,
    List<InferredInsight>? inferredInsights,
    List<Recommendation>? recommendations,
    Map<String, dynamic>? exifMetadata,
    bool? isLiveAi,
    int? scanDurationMs,
    String? processingStatus,
    List<String>? analysisLimitations,
    List<String>? processingErrors,
  }) {
    return PrivacyAuditReport(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      sampleAsset: sampleAsset ?? this.sampleAsset,
      overallScore: overallScore ?? this.overallScore,
      riskLevel: riskLevel ?? this.riskLevel,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      categoryScores: categoryScores ?? this.categoryScores,
      detectedElements: detectedElements ?? this.detectedElements,
      inferredInsights: inferredInsights ?? this.inferredInsights,
      recommendations: recommendations ?? this.recommendations,
      exifMetadata: exifMetadata ?? this.exifMetadata,
      isLiveAi: isLiveAi ?? this.isLiveAi,
      scanDurationMs: scanDurationMs ?? this.scanDurationMs,
      processingStatus: processingStatus ?? this.processingStatus,
      analysisLimitations: analysisLimitations ?? this.analysisLimitations,
      processingErrors: processingErrors ?? this.processingErrors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'sampleAsset': sampleAsset,
      'overallScore': overallScore,
      'riskLevel': riskLevel.name,
      'title': title,
      'summary': summary,
      'categoryScores': categoryScores.map((k, v) => MapEntry(k.id, v)),
      'detectedElements': detectedElements.map((e) => e.toJson()).toList(),
      'inferredInsights': inferredInsights.map((e) => e.toJson()).toList(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'exifMetadata': exifMetadata,
      'isLiveAi': isLiveAi,
      'scanDurationMs': scanDurationMs,
      'processingStatus': processingStatus,
      'analysisLimitations': analysisLimitations,
      'processingErrors': processingErrors,
    };
  }

  factory PrivacyAuditReport.fromJson(Map<String, dynamic> json) {
    final catScoresRaw = json['categoryScores'] as Map<String, dynamic>? ?? {};
    final catScores = <ExposureCategory, int>{};
    for (final entry in catScoresRaw.entries) {
      catScores[ExposureCategory.fromString(entry.key)] = (entry.value as num)
          .toInt();
    }

    return PrivacyAuditReport(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      imagePath: json['imagePath'] as String?,
      sampleAsset: json['sampleAsset'] as String?,
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String? ?? 'low'),
      title: json['title'] as String? ?? 'Privacy Scan Assessment',
      summary: json['summary'] as String? ?? '',
      categoryScores: catScores,
      detectedElements: (json['detectedElements'] as List<dynamic>? ?? [])
          .map((e) => DetectedElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      inferredInsights: (json['inferredInsights'] as List<dynamic>? ?? [])
          .map((e) => InferredInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      exifMetadata: (json['exifMetadata'] as Map<String, dynamic>?) ?? {},
      isLiveAi: json['isLiveAi'] as bool? ?? false,
      scanDurationMs: (json['scanDurationMs'] as num?)?.toInt() ?? 1200,
      processingStatus: json['processingStatus'] as String? ?? 'completed',
      analysisLimitations: (json['analysisLimitations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      processingErrors: (json['processingErrors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
