import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/privacy_engine/testing/test_case_models.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/audit_provider.dart';
import '../widgets/cyber_glass_card.dart';

class EvaluationDashboardTab extends ConsumerStatefulWidget {
  const EvaluationDashboardTab({super.key});

  @override
  ConsumerState<EvaluationDashboardTab> createState() =>
      _EvaluationDashboardTabState();
}

class _EvaluationDashboardTabState
    extends ConsumerState<EvaluationDashboardTab> {
  ZenithTestRunRecord? _latestRun;
  bool _isLoading = true;
  bool _isRerunning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatestRun();
  }

  Future<void> _loadLatestRun() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final runs = await client.getTestRuns();
      if (mounted) {
        setState(() {
          _latestRun = runs.isNotEmpty ? runs.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rerunSuite() async {
    setState(() {
      _isRerunning = true;
    });

    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final run = await client.executeTestRun();
      if (mounted) {
        setState(() {
          _latestRun = run;
          _isRerunning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Benchmark Suite Evaluated: ${run.passedCases}/${run.totalCases} Passed (${run.passRate.toStringAsFixed(0)}%)',
            ),
            backgroundColor: run.failedCases == 0
                ? AppColors.riskLow
                : AppColors.riskModerate,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRerunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Benchmark evaluation failed: $e'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryCyan),
            SizedBox(height: 16),
            Text(
              'Loading Evaluation Metrics...',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: AppColors.riskCritical,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to Load Evaluation Data',
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
                onPressed: _loadLatestRun,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final run = _latestRun;
    if (run == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.query_stats_rounded,
                color: AppColors.primaryCyan,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No Evaluation Runs Available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Run the 20-category benchmark suite to compute Precision, Recall, F1, FPR, FNR, Category Accuracy, and Score MAE.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isRerunning ? null : _rerunSuite,
                icon: _isRerunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Execute Benchmark Suite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final inconclusiveCount = run.results.where((r) => r.inconclusive).length;

    return RefreshIndicator(
      onRefresh: _loadLatestRun,
      color: AppColors.primaryCyan,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: CyberGlassCard(
                padding: const EdgeInsets.all(18),
                borderColor: AppColors.accentIndigo.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentIndigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: AppColors.accentIndigo,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRIVACY EVALUATION TELEMETRY',
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
                                'Empirical Model Metrics • Score MAE & Classification Quality',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isRerunning ? null : _rerunSuite,
                          icon: _isRerunning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          tooltip: 'Rerun Benchmark Suite',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // High-level Pass Rate Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (run.passRate >= 90
                                    ? AppColors.riskLow
                                    : (run.passRate >= 70
                                          ? AppColors.riskModerate
                                          : AppColors.riskCritical))
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (run.passRate >= 90
                                      ? AppColors.riskLow
                                      : (run.passRate >= 70
                                            ? AppColors.riskModerate
                                            : AppColors.riskCritical))
                                  .withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BENCHMARK PASS RATE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${run.passRate.toStringAsFixed(1)}%',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: run.passRate >= 90
                                      ? AppColors.riskLow
                                      : AppColors.riskModerate,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${run.passedCases} / ${run.totalCases} Passed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Run ID: ${run.runId}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Core Metrics Grid (Precision, Recall, F1, FPR, FNR, Category Acc, MAE, Latency)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALIBRATION & CLASSIFICATION METRICS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Precision',
                          value: run.precision.toStringAsFixed(2),
                          subtitle: 'TP / (TP + FP)',
                          color: AppColors.primaryCyan,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Recall',
                          value: run.recall.toStringAsFixed(2),
                          subtitle: 'TP / (TP + FN)',
                          color: AppColors.accentIndigo,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'F1 Score',
                          value: run.f1Score.toStringAsFixed(2),
                          subtitle: 'Harmonic Precision-Recall',
                          color: AppColors.riskLow,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Score MAE',
                          value: '${run.maeScoreError.toStringAsFixed(1)} pts',
                          subtitle: 'Mean Absolute Score Error',
                          color: AppColors.riskModerate,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'False Positive Rate',
                          value: run.fpr.toStringAsFixed(2),
                          subtitle: 'FPR: FP / (FP + TN)',
                          color: run.fpr == 0.0
                              ? AppColors.riskLow
                              : AppColors.riskCritical,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'False Negative Rate',
                          value: run.fnr.toStringAsFixed(2),
                          subtitle: 'FNR: FN / (FN + TP)',
                          color: run.fnr == 0.0
                              ? AppColors.riskLow
                              : AppColors.riskCritical,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Category Accuracy',
                          value: '${run.categoryAccuracy.toStringAsFixed(0)}%',
                          subtitle: 'Domain classification rate',
                          color: AppColors.primaryCyan,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Mean Latency',
                          value: '${run.meanDurationMs} ms',
                          subtitle: 'Average per-image runtime',
                          color: AppColors.accentIndigo,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Inconclusive Guard Card
          if (inconclusiveCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.riskModerate.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.riskModerate.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.riskModerate,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INCONCLUSIVE FIXTURE GUARD ($inconclusiveCount CASES)',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.riskModerate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cases with missing on-disk fixtures are marked inconclusive and isolated from the metric denominator to avoid fabricating precision/recall.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Category Breakdown Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'PER-CATEGORY BREAKDOWN (${run.results.length} SCENARIOS)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // Category Results
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final res = run.results[index];
              final passColor = res.passed
                  ? AppColors.riskLow
                  : AppColors.riskCritical;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: CyberGlassCard(
                  padding: const EdgeInsets.all(12),
                  borderColor: passColor.withOpacity(0.3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: passColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          res.passed ? 'PASS' : 'FAIL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: passColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              res.testCaseName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textWhite
                                    : AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${res.category} • Actual: ${res.actualScore}/100 • Expected: [${res.expectedMinScore} - ${res.expectedMaxScore}]',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${res.durationMs}ms',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: run.results.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return CyberGlassCard(
      padding: const EdgeInsets.all(12),
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
