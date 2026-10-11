import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/exposure_category.dart';
import '../models/privacy_audit_report.dart';
import 'camera_screen.dart';
import 'widgets/auto_redact_preview_modal.dart';
import 'widgets/cyber_glass_card.dart';
import 'widgets/detected_element_tile.dart';
import 'widgets/exposure_category_card.dart';
import 'widgets/image_inspection_overlay.dart';
import 'widgets/inference_card.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/risk_meter_gauge.dart';

class ResultsScreen extends StatelessWidget {
  final PrivacyAuditReport report;

  const ResultsScreen({super.key, required this.report});

  void _openRedactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AutoRedactPreviewModal(
        imageBytes: report.imageBytes,
        imagePath: report.imagePath,
        sampleAsset: report.sampleAsset,
        detectedElements: report.detectedElements,
      ),
    );
  }

  void _shareReport(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('🛡️ ZENITH OPSEC PRIVACY AUDIT REPORT');
    buffer.writeln('=====================================');
    buffer.writeln('Assessment: ${report.title}');
    buffer.writeln(
      'Overall Risk Score: ${report.overallScore}/100 (${report.riskLevel.label})',
    );
    buffer.writeln(
      'Scanned: ${DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp)}',
    );
    buffer.writeln('Summary: ${report.summary}\n');

    buffer.writeln('📊 EXPOSURE BREAKDOWN:');
    for (final entry in report.categoryScores.entries) {
      buffer.writeln('• ${entry.key.displayName}: ${entry.value}%');
    }

    buffer.writeln(
      '\n⚠️ IDENTIFIED RISKS (${report.detectedElements.length}):',
    );
    for (final elem in report.detectedElements) {
      buffer.writeln(
        '• [${elem.riskLevel.label.toUpperCase()}] ${elem.name}: ${elem.opsecImpact}',
      );
    }

    buffer.writeln(
      '\n🧠 ATTACKER INFERENCES (${report.inferredInsights.length}):',
    );
    for (final inf in report.inferredInsights) {
      buffer.writeln(
        '• Visible: "${inf.directObservation}" ➔ Inferred: "${inf.inferredInsight}" (${inf.attackerThreatProfile})',
      );
    }

    buffer.writeln('\n🔒 RECOMMENDATIONS:');
    for (final rec in report.recommendations) {
      buffer.writeln('• [${rec.priority.label}] ${rec.title}: ${rec.action}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit Report copied to clipboard! Ready to share.'),
        backgroundColor: AppColors.riskLow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = report.riskLevel.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Privacy Assessment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy & Share Audit Report',
            onPressed: () => _shareReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New Scan',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Executive Risk Meter Gauge
              CyberGlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: riskColor.withOpacity(0.4),
                child: Column(
                  children: [
                    RiskMeterGauge(
                      score: report.overallScore,
                      riskLevel: report.riskLevel,
                      size: 200,
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      report.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.summary,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick Meta info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          report.isLiveAi
                              ? Icons.bolt_rounded
                              : Icons.tune_rounded,
                          size: 14,
                          color: AppColors.primaryCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.isLiveAi
                              ? 'Verified via Gemini Vision'
                              : 'Zenith Onboard Threat Model',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${report.scanDurationMs}ms latency',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Optical Forensics Viewer with Bounding Boxes
              ImageInspectionOverlay(
                imageBytes: report.imageBytes,
                imagePath: report.imagePath,
                sampleAsset: report.sampleAsset,
                detectedElements: report.detectedElements,
                onOpenRedactStudio: () => _openRedactionModal(context),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // 3. Exposure Categories Breakdown
              _buildSectionHeader(
                icon: Icons.bar_chart_rounded,
                title: 'EXPOSURE BREAKDOWN',
                subtitle: 'Category-specific vulnerability metrics',
              ),
              const SizedBox(height: 10),
              ...ExposureCategory.values.map((cat) {
                final score = report.categoryScores[cat] ?? 0;
                final count = report.detectedElements
                    .where((e) => e.category == cat)
                    .length;
                return ExposureCategoryCard(
                  category: cat,
                  score: score,
                  detectedCount: count,
                );
              }),
              const SizedBox(height: 24),

              // 4. Security Intelligence Layer (Attacker Inferences)
              _buildSectionHeader(
                icon: Icons.psychology_rounded,
                title: 'SECURITY INTELLIGENCE & INFERENCES',
                subtitle:
                    'What can someone deduce or weaponize from this photo?',
              ),
              const SizedBox(height: 10),
              if (report.inferredInsights.isEmpty)
                CyberGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No secondary attacker deductions or OSINT correlation vectors found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                ...report.inferredInsights.map((inf) {
                  return InferenceCard(insight: inf);
                }),
              const SizedBox(height: 24),

              // 5. Detected Sensitive Elements Inventory
              _buildSectionHeader(
                icon: Icons.find_in_page_rounded,
                title: 'DETECTED ELEMENTS & SENSITIVE DATA',
                subtitle:
                    '${report.detectedElements.length} direct exposure points identified',
              ),
              const SizedBox(height: 10),
              if (report.detectedElements.isEmpty)
                CyberGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No direct sensitive PII, badges, credentials, or barcodes identified.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                ...report.detectedElements.map((elem) {
                  return DetectedElementTile(element: elem);
                }),
              const SizedBox(height: 24),

              // 6. Actionable Mitigation Checklist
              _buildSectionHeader(
                icon: Icons.checklist_rtl_rounded,
                title: 'MITIGATION & RECOMMENDATIONS',
                subtitle: 'Mandatory actions to reduce exposure before sharing',
              ),
              const SizedBox(height: 10),
              ...report.recommendations.map((rec) {
                return RecommendationCard(recommendation: rec);
              }),
              const SizedBox(height: 24),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openRedactionModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryCyan,
                        side: const BorderSide(
                          color: AppColors.primaryCyan,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: Text(
                        'Auto-Redact',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareReport(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        foregroundColor: AppColors.darkBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        'Copy Report',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryCyan),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
