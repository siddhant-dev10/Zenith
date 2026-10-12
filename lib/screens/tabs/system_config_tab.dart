import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../settings_screen.dart';
import '../widgets/cyber_glass_card.dart';

class SystemConfigTab extends ConsumerStatefulWidget {
  const SystemConfigTab({super.key});

  @override
  ConsumerState<SystemConfigTab> createState() => _SystemConfigTabState();
}

class _SystemConfigTabState extends ConsumerState<SystemConfigTab> {
  Map<String, dynamic>? _healthStatus;
  bool _isCheckingHealth = false;
  String? _healthError;

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _healthError = null;
    });

    final settings = ref.read(settingsProvider);
    final url = '${settings.backendUrl}/health';

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _healthStatus = jsonDecode(res.body) as Map<String, dynamic>;
            _isCheckingHealth = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _healthError = 'HTTP ${res.statusCode}: ${res.body}';
            _isCheckingHealth = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _healthError = ApiConfig.diagnoseConnectionError(e, url);
          _isCheckingHealth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: CyberGlassCard(
              padding: const EdgeInsets.all(18),
              borderColor: AppColors.primaryCyan.withOpacity(0.35),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM & ENGINE CONFIGURATION',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Gemini Vision • Deterministic Risk Calibration',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Full Settings',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Live AI Engine Status
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: CyberGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.riskLow.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.riskLow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI VISION ENGINE STATUS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.riskLow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildConfigRow('Active Model', settings.model, isDark),
                  _buildConfigRow(
                    'API Key Status',
                    settings.hasApiKey ? 'Configured & Active' : 'Not Loaded',
                    isDark,
                    valueColor: settings.hasApiKey
                        ? AppColors.riskLow
                        : AppColors.riskCritical,
                  ),
                  _buildConfigRow(
                    'Sensitivity',
                    settings.sensitivity.toUpperCase(),
                    isDark,
                  ),
                  _buildConfigRow(
                    'Remote Backend',
                    settings.useRemoteBackend
                        ? 'Enabled'
                        : 'Disabled (Local Pipeline)',
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scoring Calibration Engine Matrix
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: CyberGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.accentIndigo.withOpacity(0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALIBRATED RISK MATRIX SPECIFICATION',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.accentIndigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deterministic Risk Engine separates vision localization from OPSEC risk calculus via formula: R = S × E × V.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMatrixRow(
                    'Ordinary Human Face',
                    'S=15, E=0.20, V=0.80',
                    'Score ≤ 15 (LOW)',
                    AppColors.riskLow,
                  ),
                  _buildMatrixRow(
                    'Clean Landscape / Object',
                    'S=15, E=0.25, V=0.75',
                    'Score 0 (LOW)',
                    AppColors.riskLow,
                  ),
                  _buildMatrixRow(
                    'Corporate / Student Badge',
                    'S=80, E=0.85, V=0.90',
                    'Score 51–75 (HIGH)',
                    AppColors.riskHigh,
                  ),
                  _buildMatrixRow(
                    'Plaintext API Key / Secret',
                    'S=100, E=1.00, V=1.00',
                    'Score 76–100 (CRITICAL)',
                    AppColors.riskCritical,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Backend Server Health Check
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: CyberGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.primaryCyan.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'BACKEND SERVER HEALTH',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isCheckingHealth
                            ? null
                            : _checkServerHealth,
                        icon: _isCheckingHealth
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Check Health',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildConfigRow('Backend URL', settings.backendUrl, isDark),
                  if (_healthStatus != null) ...[
                    _buildConfigRow(
                      'Service Status',
                      _healthStatus!['status']?.toString().toUpperCase() ??
                          'UNKNOWN',
                      isDark,
                      valueColor: AppColors.riskLow,
                    ),
                    _buildConfigRow(
                      'Gemini Configured',
                      '${_healthStatus!['geminiConfigured']}',
                      isDark,
                      valueColor: _healthStatus!['geminiConfigured'] == true
                          ? AppColors.riskLow
                          : AppColors.riskCritical,
                    ),
                    _buildConfigRow(
                      'Service Version',
                      _healthStatus!['version']?.toString() ?? '1.0.0',
                      isDark,
                    ),
                  ] else if (_healthError != null) ...[
                    Text(
                      'Health check error: $_healthError',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.riskCritical,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildConfigRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ??
                  (isDark ? AppColors.textWhite : AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(
    String target,
    String formula,
    String band,
    Color bandColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              target,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formula,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bandColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              band,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: bandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
