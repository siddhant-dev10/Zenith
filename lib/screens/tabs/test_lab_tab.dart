import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/privacy_engine/testing/test_case_models.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/audit_provider.dart';
import '../../services/sample_data_service.dart';
import '../analysis_screen.dart';
import '../camera_screen.dart';
import '../widgets/cyber_glass_card.dart';

class TestLabTab extends ConsumerStatefulWidget {
  final VoidCallback onSuiteExecuted;

  const TestLabTab({super.key, required this.onSuiteExecuted});

  @override
  ConsumerState<TestLabTab> createState() => _TestLabTabState();
}

class _TestLabTabState extends ConsumerState<TestLabTab> {
  List<ZenithTestCaseRecord> _testCases = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  // Per-test running state and results
  final Set<String> _runningCaseIds = {};
  final Map<String, TestCaseRunResultRecord> _caseResults = {};
  bool _isSuiteRunning = false;

  @override
  void initState() {
    super.initState();
    _loadTestCases();
  }

  void _navigateToAnalysis() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
  }

  void _testSample(SampleScenario scenario) {
    ref.read(auditProvider.notifier).selectSample(scenario);
    _navigateToAnalysis();
  }

  Future<void> _loadTestCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final cases = await client.getTestCases();
      if (mounted) {
        setState(() {
          _testCases = cases;
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

  Future<void> _runSingleCase(ZenithTestCaseRecord tc) async {
    setState(() {
      _runningCaseIds.add(tc.id);
    });

    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final run = await client.executeTestRun(caseIds: [tc.id]);
      if (run.results.isNotEmpty && mounted) {
        setState(() {
          _caseResults[tc.id] = run.results.first;
          _runningCaseIds.remove(tc.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _runningCaseIds.remove(tc.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to run ${tc.id}: $e'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  Future<void> _runFullSuite() async {
    setState(() {
      _isSuiteRunning = true;
    });

    try {
      final client = ref.read(auditProvider.notifier).apiClient;
      final run = await client.executeTestRun();
      if (mounted) {
        setState(() {
          for (final res in run.results) {
            _caseResults[res.testCaseId] = res;
          }
          _isSuiteRunning = false;
        });

        widget.onSuiteExecuted();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Benchmark Suite Complete: ${run.passedCases}/${run.totalCases} passed (${run.passRate.toStringAsFixed(0)}%)',
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
          _isSuiteRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suite execution failed: $e'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  List<ZenithTestCaseRecord> get _filteredCases {
    return _testCases.where((tc) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          tc.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tc.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCat =
          _selectedCategory == 'ALL' ||
          tc.category.toUpperCase() == _selectedCategory.toUpperCase();

      return matchesSearch && matchesCat;
    }).toList();
  }

  List<String> get _categories {
    final cats = {'ALL'};
    for (final tc in _testCases) {
      cats.add(tc.category.toUpperCase());
    }
    return cats.toList();
  }

  Color _severityColor(String sev) {
    switch (sev.toLowerCase()) {
      case 'low':
        return AppColors.riskLow;
      case 'moderate':
        return AppColors.riskModerate;
      case 'high':
        return AppColors.riskHigh;
      case 'critical':
        return AppColors.riskCritical;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _filteredCases;

    return RefreshIndicator(
      onRefresh: _loadTestCases,
      color: AppColors.primaryCyan,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Banner & Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: CyberGlassCard(
                padding: const EdgeInsets.all(18),
                borderColor: AppColors.primaryCyan.withOpacity(0.4),
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
                            Icons.science_rounded,
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
                                'ZENITH TEST LAB & BENCHMARK',
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
                                '${_testCases.length} Standardized Scenarios • Precision Calibration',
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
                    const SizedBox(height: 14),
                    Text(
                      'Validate AI vision detection thresholds against standardized adversarial and ordinary photo test scenarios.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSuiteRunning ? null : _runFullSuite,
                            icon: _isSuiteRunning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _isSuiteRunning
                                  ? 'Evaluating ${_testCases.isNotEmpty ? _testCases.length : 120} Scenarios...'
                                  : 'Execute Full Suite (${_testCases.isNotEmpty ? _testCases.length : 120} Cases)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Primary Actions: Capture Photo & Upload Photo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                          MaterialPageRoute(
                            builder: (_) => const CameraScreen(),
                          ),
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

          // Test Threat Scenarios Carousel Section
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
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
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

          // Search & Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search test scenarios (e.g. "face", "badge", "token")...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkCard.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.replaceAll('_', ' '),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.black
                                  : (isDark
                                        ? AppColors.textWhite
                                        : AppColors.textDark),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryCyan,
                          backgroundColor: isDark
                              ? AppColors.darkCard
                              : Colors.grey.shade200,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'TEST SCENARIOS (${filtered.length})',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Test Cases List
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.riskCritical,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load test cases: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadTestCases,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tc = filtered[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: _buildTestCaseCard(tc, isDark),
                );
              }, childCount: filtered.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
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

  Widget _buildTestCaseCard(ZenithTestCaseRecord tc, bool isDark) {
    final sevColor = _severityColor(tc.expectedSeverity);
    final isRunning = _runningCaseIds.contains(tc.id);
    final result = _caseResults[tc.id];

    return CyberGlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: result != null
          ? (result.passed ? AppColors.riskLow : AppColors.riskCritical)
                .withOpacity(0.4)
          : sevColor.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tc.id,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tc.category.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sevColor.withOpacity(0.4)),
                ),
                child: Text(
                  'EXPECTED: ${tc.expectedSeverity.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: sevColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tc.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textWhite : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tc.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.radar_rounded,
                size: 14,
                color: AppColors.textMuted.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'Expected Score: [${tc.minExpectedScore} - ${tc.maxExpectedScore}]',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.verified_outlined,
                size: 14,
                color: AppColors.textMuted.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'Detections: ${tc.expectedDetections.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Fixture: ${tc.inputFixtureReference}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textMuted.withOpacity(0.6),
            ),
          ),

          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (result.passed ? AppColors.riskLow : AppColors.riskCritical)
                        .withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      (result.passed
                              ? AppColors.riskLow
                              : AppColors.riskCritical)
                          .withOpacity(0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        result.passed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: result.passed
                            ? AppColors.riskLow
                            : AppColors.riskCritical,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.passed ? 'VERIFIED PASSED' : 'ASSERTION FAILED',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: result.passed
                              ? AppColors.riskLow
                              : AppColors.riskCritical,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Actual Score: ${result.actualScore}/100',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evaluated Severity: ${result.actualSeverity} • Latency: ${result.durationMs}ms',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (result.differences.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Differences: ${result.differences.join("; ")}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.riskCritical,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isRunning ? null : () => _runSingleCase(tc),
                icon: isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryCyan,
                        ),
                      )
                    : const Icon(Icons.play_arrow_outlined, size: 16),
                label: Text(
                  isRunning ? 'Running...' : 'Run Case',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryCyan,
                  side: BorderSide(
                    color: AppColors.primaryCyan.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
