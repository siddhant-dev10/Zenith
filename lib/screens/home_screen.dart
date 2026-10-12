import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/audit_provider.dart';
import '../providers/settings_provider.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'tabs/evaluation_dashboard_tab.dart';
import 'tabs/image_analyzer_tab.dart';
import 'tabs/system_config_tab.dart';
import 'tabs/test_lab_tab.dart';
import 'tabs/test_runs_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditProvider.notifier).loadHistory();
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      TestLabTab(
        onSuiteExecuted: () {
          // Switch to evaluation dashboard after full suite run
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const EvaluationDashboardTab(),
      const ImageAnalyzerTab(),
      const TestRunsTab(),
      const SystemConfigTab(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                // App Logo Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryCyan, AppColors.accentIndigo],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.security_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Mode Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppConstants.appName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
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
                                  : 'OPSEC EVAL ENGINE',
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
                        'Privacy Testing & Evaluation Framework',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // History Button
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 22),
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                  tooltip: 'Audit History',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                // Settings Button
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                  tooltip: 'Settings & Model Config',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primaryCyan.withOpacity(0.2),
            height: 64,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(
                  Icons.science_rounded,
                  color: AppColors.primaryCyan,
                ),
                label: 'Test Lab',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(
                  Icons.analytics_rounded,
                  color: AppColors.accentIndigo,
                ),
                label: 'Evaluation',
              ),
              NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primaryCyan,
                ),
                label: 'Analyzer',
              ),
              NavigationDestination(
                icon: Icon(Icons.rule_folder_outlined),
                selectedIcon: Icon(
                  Icons.rule_folder_rounded,
                  color: AppColors.riskLow,
                ),
                label: 'Test Runs',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryCyan,
                ),
                label: 'Config',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
