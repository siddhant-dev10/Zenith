import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_config.dart';
import '../core/theme/app_colors.dart';
import '../providers/audit_provider.dart';
import '../providers/settings_provider.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'widgets/cyber_glass_card.dart';
import 'widgets/glowing_scanner_hud.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isRetrying = false;
  bool _isCheckingHealth = false;
  String? _healthDiagnostic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    final auditState = ref.read(auditProvider);
    if (auditState.isScanning || _isRetrying) return;

    setState(() {
      _isRetrying = true;
      _healthDiagnostic = null;
    });

    try {
      final notifier = ref.read(auditProvider.notifier);
      final report = await notifier.runAnalysis();
      if (mounted && report != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) =>
                ResultsScreen(report: report),
            transitionsBuilder: (context, anim, secAnim, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _runHealthCheck() async {
    if (_isCheckingHealth) return;
    setState(() {
      _isCheckingHealth = true;
      _healthDiagnostic = null;
    });

    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final health = await client.checkHealth();
      if (mounted) {
        final service = health['service'] ?? 'zenith';
        final isGemini = health['geminiConfigured'] == true;
        final provider = health['provider'] ?? 'gemini';
        setState(() {
          _isCheckingHealth = false;
          _healthDiagnostic =
              'Backend is online ($service).\n'
              '• Vision Provider: $provider\n'
              '• Gemini Status: ${isGemini ? "Active (Ready)" : "Unconfigured (Missing API key on server)"}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingHealth = false;
          final clean = e.toString().replaceFirst('Exception: ', '');
          _healthDiagnostic = clean;
        });
      }
    }
  }

  Widget _buildPreview(AuditState state) {
    if (state.selectedImageBytes != null) {
      return Image.memory(
        state.selectedImageBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (state.selectedSampleAsset != null) {
      return Image.asset(
        state.selectedSampleAsset!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (state.selectedImagePath != null && !kIsWeb) {
      return Image.file(
        File(state.selectedImagePath!),
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: Icon(Icons.security, size: 60, color: Colors.white24),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);
    final settings = ref.watch(settingsProvider);
    final status = auditState.status;
    final isError = status == ScanStatus.error;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Security Status Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 20,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OPSEC NEURAL AUDIT',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryCyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        settings.hasApiKey
                            ? 'Model: ${settings.model} (Live Multimodal)'
                            : 'Engine: Onboard Heuristic Risk Model',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image Scanning Viewport
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F141C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isError
                            ? AppColors.riskCritical
                            : AppColors.primaryCyan.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isError
                              ? AppColors.riskCritical.withOpacity(0.2)
                              : AppColors.primaryCyan.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPreview(auditState),

                        // Laser Scanner HUD (active during scan)
                        if (!isError)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GlowingScannerHud(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                scanColor: AppColors.primaryCyan,
                              );
                            },
                          ),

                        // Error Overlay
                        if (isError)
                          Builder(
                            builder: (context) {
                              final errText = auditState.errorMessage ?? '';
                              final isMissingConfig =
                                  errText.contains('Live analysis is not configured') ||
                                  (kIsWeb && settings.backendUrl.trim().isEmpty);
                              final isOffline =
                                  errText.toLowerCase().contains('connection') ||
                                  errText.toLowerCase().contains('unable to reach') ||
                                  errText.toLowerCase().contains('timed out') ||
                                  errText.toLowerCase().contains('socket') ||
                                  errText.toLowerCase().contains('failed to fetch');
                              final isCreds =
                                  errText.toLowerCase().contains('credentials required') ||
                                  errText.toLowerCase().contains('gemini_api_key');
                              final isRateLimit =
                                  errText.toLowerCase().contains('rate limit') ||
                                  errText.toLowerCase().contains('quota');

                              final failureTitle = isMissingConfig
                                  ? 'Live Analysis Not Configured'
                                  : (isOffline
                                        ? 'Backend Server Unreachable'
                                        : (isCreds
                                              ? 'Gemini Credentials Required'
                                              : (isRateLimit
                                                    ? 'Rate Limit Exceeded'
                                                    : 'Analysis Failed')));

                              return Container(
                                color: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isMissingConfig
                                            ? Icons.cloud_off_rounded
                                            : Icons.error_outline_rounded,
                                        size: 42,
                                        color: AppColors.riskCritical,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        failureTitle,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.08),
                                          ),
                                        ),
                                        child: Text(
                                          errText.isNotEmpty
                                              ? errText
                                              : 'An unexpected error occurred during scan.',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      if (_healthDiagnostic != null) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryCyan.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.primaryCyan.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            _healthDiagnostic!,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10.5,
                                              color: AppColors.primaryCyan,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      if (!kIsWeb && Platform.isAndroid && isOffline) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await ref
                                                  .read(settingsProvider.notifier)
                                                  .updateBackendUrl(ApiConfig.defaultLanUrl);
                                              _startAnalysis();
                                            },
                                            icon: const Icon(Icons.wifi_rounded, size: 16),
                                            label: Text(
                                              'Connect to Mac (${ApiConfig.defaultLanUrl})',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryCyan,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: const BorderSide(
                                                color: AppColors.darkBorder,
                                              ),
                                            ),
                                            child: const Text('Back'),
                                          ),
                                          if (settings.backendUrl.trim().isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: _isCheckingHealth
                                                  ? null
                                                  : _runHealthCheck,
                                              icon: _isCheckingHealth
                                                  ? const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: AppColors.primaryCyan,
                                                      ),
                                                    )
                                                  : const Icon(Icons.favorite_outline, size: 15),
                                              label: const Text('Check Health'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primaryCyan,
                                                side: const BorderSide(
                                                  color: AppColors.primaryCyan,
                                                ),
                                              ),
                                            ),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const SettingsScreen(),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.settings_outlined, size: 16),
                                            label: const Text('Settings'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isMissingConfig
                                                  ? AppColors.primaryCyan
                                                  : Colors.white,
                                              side: BorderSide(
                                                color: isMissingConfig
                                                    ? AppColors.primaryCyan
                                                    : AppColors.darkBorder,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: (_isRetrying || auditState.isScanning)
                                                ? null
                                                : _startAnalysis,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryCyan,
                                              foregroundColor: AppColors.darkBg,
                                            ),
                                            child: _isRetrying
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                        AppColors.darkBg,
                                                      ),
                                                    ),
                                                  )
                                                : const Text('Retry Scan'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress Ticker & Stage Details
              if (!isError) ...[
                CyberGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status.stepDescription,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(status.progressValue * 100).toInt()}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: status.progressValue,
                          backgroundColor: AppColors.darkBorder.withOpacity(
                            0.5,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryCyan,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Multi-stage indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStagePill(
                            'Ingestion',
                            status.progressValue >= 0.25,
                          ),
                          _buildStageDivider(status.progressValue >= 0.55),
                          _buildStagePill(
                            'Neural Vision',
                            status.progressValue >= 0.55,
                          ),
                          _buildStageDivider(status.progressValue >= 0.80),
                          _buildStagePill(
                            'Inference',
                            status.progressValue >= 0.80,
                          ),
                          _buildStageDivider(status.progressValue >= 0.95),
                          _buildStagePill(
                            'Synthesis',
                            status.progressValue >= 0.95,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'CALCULATING ATTACKER VECTORS & METADATA LEAKS...',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ).animate().fadeIn(duration: 800.ms),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStagePill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primaryCyan.withOpacity(0.18)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active
              ? AppColors.primaryCyan.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.primaryCyan : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStageDivider(bool active) {
    return Container(
      width: 12,
      height: 1,
      color: active
          ? AppColors.primaryCyan.withOpacity(0.6)
          : AppColors.darkBorder,
    );
  }
}
