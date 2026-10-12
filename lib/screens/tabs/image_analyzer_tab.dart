import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/privacy_audit_report.dart';
import '../../providers/audit_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/sample_data_service.dart';
import '../analysis_screen.dart';
import '../camera_screen.dart';
import '../history_screen.dart';
import '../results_screen.dart';
import '../settings_screen.dart';
import '../widgets/cyber_glass_card.dart';

class ImageAnalyzerTab extends ConsumerStatefulWidget {
  const ImageAnalyzerTab({super.key});

  @override
  ConsumerState<ImageAnalyzerTab> createState() => _ImageAnalyzerTabState();
}

class _ImageAnalyzerTabState extends ConsumerState<ImageAnalyzerTab> {
  void _navigateToAnalysis() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
  }

  void _testSample(SampleScenario scenario) {
    ref.read(auditProvider.notifier).selectSample(scenario);
    _navigateToAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.camera_enhance_rounded,
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
                              'IMAGE PRIVACY ANALYZER',
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
                              'Interactive Camera HUD & Privacy Intelligence',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Audit device photographs before uploading or sharing online to detect sensitive credentials, metadata, and identity exposures.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Live Backend Endpoint Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: settings.backendUrl == ApiConfig.defaultLanUrl
                            ? AppColors.primaryCyan.withOpacity(0.4)
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lan_rounded,
                          size: 14,
                          color: settings.backendUrl == ApiConfig.defaultLanUrl
                              ? AppColors.primaryCyan
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Endpoint: ${settings.backendUrl}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              color: isDark ? AppColors.textWhite : AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (settings.backendUrl != ApiConfig.defaultLanUrl) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateBackendUrl(ApiConfig.defaultLanUrl);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Switched backend to Wi-Fi LAN (${ApiConfig.defaultLanUrl})'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Use LAN',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryCyan,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: const Icon(Icons.settings_outlined, size: 14),
                          color: AppColors.textMuted,
                          tooltip: 'Configure Backend',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Primary Actions: Capture & Upload
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'Capture Photo',
                    subtitle: 'Live Camera HUD',
                    icon: Icons.camera_alt_rounded,
                    gradient: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CameraScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    context: context,
                    title: 'Upload Photo',
                    subtitle: 'Gallery & Storage',
                    icon: Icons.photo_library_rounded,
                    gradient: const [Color(0xFF7928CA), Color(0xFFFF0080)],
                    onTap: () async {
                      await ref.read(auditProvider.notifier).pickFromGallery();
                      final state = ref.read(auditProvider);
                      if (state.hasImageSelected) {
                        _navigateToAnalysis();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick Threat Scenarios Carousel
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: 8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: AppColors.primaryCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'TEST THREAT SCENARIOS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  'Pre-calibrated',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: SampleDataService.getScenarios().length,
              itemBuilder: (context, index) {
                final scenario = SampleDataService.getScenarios()[index];
                return _buildScenarioCard(scenario);
              },
            ),
          ),
        ),

        // Recent Audits Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: 8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_edu_rounded,
                  size: 18,
                  color: AppColors.accentIndigo,
                ),
                const SizedBox(width: 8),
                Text(
                  'RECENT PRIVACY AUDITS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                if (auditState.history.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All (${auditState.history.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Recent Audits List
        if (auditState.history.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: CyberGlassCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Privacy Audits Yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture a photo or try one of the threat scenarios above to generate your first calibrated OPSEC report.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final report = auditState.history[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: _buildRecentAuditTile(report, isDark),
              );
            }, childCount: auditState.history.length.clamp(0, 5)),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(SampleScenario scenario) {
    final riskColor = scenario.riskLevel.color;

    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: CyberGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 14,
        borderColor: riskColor.withOpacity(0.35),
        onTap: () => _testSample(scenario),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(scenario.assetPath, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.darkBg.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scenario.tag.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Text(
                      '${scenario.expectedRiskScore}/100',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: riskColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scenario.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Audit Scenario',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.primaryCyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAuditTile(PrivacyAuditReport report, bool isDark) {
    final riskColor = report.riskLevel.color;

    return CyberGlassCard(
      padding: const EdgeInsets.all(12),
      borderColor: riskColor.withOpacity(0.3),
      onTap: () {
        ref.read(auditProvider.notifier).setCurrentReport(report);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResultsScreen(report: report)),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: riskColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '${report.overallScore}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: riskColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.riskLevel.label} • ${report.detectedElements.length} findings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
