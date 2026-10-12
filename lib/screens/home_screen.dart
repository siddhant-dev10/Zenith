import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/privacy_engine/testing/test_case_models.dart';
import '../core/theme/app_colors.dart';
import '../models/privacy_audit_report.dart';
import '../providers/audit_provider.dart';
import '../providers/settings_provider.dart';
import '../services/sample_data_service.dart';
import 'analysis_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'widgets/cyber_glass_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditProvider.notifier).loadHistory();
    });
  }

  void _navigateToAnalysis() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
  }

  void _testSample(SampleScenario scenario) {
    ref.read(auditProvider.notifier).selectSample(scenario);
    _navigateToAnalysis();
  }

  void _showBenchmarkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BenchmarkSuiteModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = auditState.stats;
    final totalAudits = (stats['totalAudits'] as num?)?.toInt() ?? 0;
    final criticalCount = (stats['criticalBreaches'] as num?)?.toInt() ?? 0;
    final highCount = (stats['highRisks'] as num?)?.toInt() ?? 0;
    final leaksIntercepted = criticalCount + highCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryCyan,
                            AppColors.accentIndigo,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.security_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppConstants.appName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.riskLow.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.riskLow.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  settings.hasApiKey
                                      ? 'LIVE AI'
                                      : 'OPSEC ENGINE',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.riskLow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Operational Security Assistant',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // History Icon
                    IconButton(
                      icon: const Icon(Icons.history_rounded),
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                      tooltip: 'View History',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    // Benchmark Suite Icon
                    IconButton(
                      icon: const Icon(Icons.rule_folder_rounded),
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                      tooltip: 'Evaluation Benchmark Suite',
                      onPressed: () => _showBenchmarkModal(context),
                    ),
                    // Settings Icon
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                      tooltip: 'Settings & API Key',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Hero Banner & Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: CyberGlassCard(
                  padding: const EdgeInsets.all(18),
                  borderColor: AppColors.primaryCyan.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryCyan.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'OPSEC THREAT RADAR ACTIVE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryCyan,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Audit photos before sharing.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Zenith identifies visible sensitive data and predicts what an attacker or OSINT researcher can infer.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Audits Run',
                              '$totalAudits',
                              AppColors.primaryCyan,
                            ),
                            _buildStatDivider(),
                            _buildStatItem(
                              'Leaks Prevented',
                              '$leaksIntercepted',
                              AppColors.riskCritical,
                            ),
                            _buildStatDivider(),
                            _buildStatItem(
                              'AI Engine',
                              settings.hasApiKey ? 'Gemini 2.5' : 'Heuristic',
                              AppColors.riskLow,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Capture Photo Button
                    Expanded(
                      child: _buildActionTile(
                        context: context,
                        title: 'Capture Photo',
                        subtitle: 'Live Camera HUD',
                        icon: Icons.camera_alt_rounded,
                        gradient: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CameraScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Upload Photo Button
                    Expanded(
                      child: _buildActionTile(
                        context: context,
                        title: 'Upload Photo',
                        subtitle: 'Gallery & Storage',
                        icon: Icons.photo_library_rounded,
                        gradient: const [Color(0xFF7928CA), Color(0xFFFF0080)],
                        onTap: () async {
                          await ref
                              .read(auditProvider.notifier)
                              .pickFromGallery();
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

            // Sample Threat Scenarios Carousel Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
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
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Instant Evaluation',
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
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                            'Capture a photo or try one of the threat scenarios above to generate your first OPSEC assessment.',
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
                    child: _buildRecentAuditTile(report),
                  );
                }, childCount: auditState.history.length.clamp(0, 4)),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 24, color: AppColors.darkBorder);
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
            // Preview Image Thumbnail with Risk Chip
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
            // Text info
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
                        'Test Scan',
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

  Widget _buildRecentAuditTile(PrivacyAuditReport report) {
    final riskColor = report.riskLevel.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d, h:mm a').format(report.timestamp);

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
                  '${report.riskLevel.label} • ${report.detectedElements.length} threats • $dateStr',
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

/// Cyber-styled modal displaying execution results of Zenith's 20-category benchmark evaluation suite.
class BenchmarkSuiteModal extends ConsumerStatefulWidget {
  const BenchmarkSuiteModal({super.key});

  @override
  ConsumerState<BenchmarkSuiteModal> createState() =>
      _BenchmarkSuiteModalState();
}

class _BenchmarkSuiteModalState extends ConsumerState<BenchmarkSuiteModal> {
  ZenithTestRunRecord? _runRecord;
  Map<String, ZenithTestCaseRecord> _testCases = {};
  bool _isRunning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runBenchmark();
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _errorMessage = null;
    });
    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final cases = await client.getTestCases();
      final run = await client.executeTestRun();
      if (mounted) {
        setState(() {
          _testCases = {for (final tc in cases) tc.id: tc};
          _runRecord = run;
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Modal drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
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
                            'BENCHMARK SUITE',
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
                            '20 Threat Categories • Calibration & Evaluation',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isRunning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      onPressed: _isRunning ? null : _runBenchmark,
                      tooltip: 'Re-run Benchmark Suite',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: _isRunning
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primaryCyan,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Evaluating 20 Threat Categories...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.riskCritical,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Benchmark Execution Failed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.riskCritical,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _runBenchmark,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _runRecord == null
                    ? const SizedBox.shrink()
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Telemetry Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.riskLow.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.riskLow.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMetric(
                                      'Pass Rate',
                                      '${_runRecord!.passRate.toStringAsFixed(0)}%',
                                      AppColors.riskLow,
                                    ),
                                    _buildMetric(
                                      'Scenarios',
                                      '${_runRecord!.passedCases}/${_runRecord!.totalCases}',
                                      AppColors.primaryCyan,
                                    ),
                                    _buildMetric(
                                      'F1 Score',
                                      _runRecord!.f1Score.toStringAsFixed(2),
                                      AppColors.accentIndigo,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMetric(
                                      'Precision',
                                      _runRecord!.precision.toStringAsFixed(2),
                                      isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                    _buildMetric(
                                      'Recall',
                                      _runRecord!.recall.toStringAsFixed(2),
                                      isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                    _buildMetric(
                                      'Severity Acc',
                                      '${_runRecord!.severityAccuracy.toStringAsFixed(0)}%',
                                      AppColors.primaryCyan,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'SCENARIO EVALUATIONS (${_runRecord!.results.length})',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.textMuted,
                            ),
                          ),

                          const SizedBox(height: 10),

                          ..._runRecord!.results.map((res) {
                            final tc = _testCases[res.testCaseId];
                            final passColor = res.passed
                                ? AppColors.riskLow
                                : AppColors.riskCritical;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBg.withOpacity(0.6)
                                    : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: passColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryCyan
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          res.testCaseId,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryCyan,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tc?.category ?? 'THREAT CLASS',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textWhite
                                                : AppColors.textDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: passColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          res.passed ? 'PASSED' : 'FAILED',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: passColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    res.testCaseName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textWhite
                                          : AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Score: ${res.actualScore}/100 (${res.actualSeverity.toUpperCase()}) • Expected: [${res.expectedMinScore} - ${res.expectedMaxScore}] (${res.expectedSeverity.toUpperCase()})',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Detections: ${res.actualDetectionsCount}/${res.expectedDetectionsCount} • Latency: ${res.durationMs}ms',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: AppColors.primaryCyan.withOpacity(
                                        0.9,
                                      ),
                                    ),
                                  ),
                                  if (res.differences.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Differences: ${res.differences.join(", ")}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.riskCritical,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  if (tc?.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tc!.description,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textMuted.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
