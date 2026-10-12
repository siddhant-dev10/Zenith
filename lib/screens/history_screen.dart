import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/privacy_audit_report.dart';
import '../models/risk_level.dart';
import '../providers/audit_provider.dart';
import 'results_screen.dart';
import 'widgets/cyber_glass_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  RiskLevel? _selectedFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = auditState.history.where((report) {
      if (_selectedFilter != null && report.riskLevel != _selectedFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = report.title.toLowerCase().contains(query);
        final matchSummary = report.summary.toLowerCase().contains(query);
        if (!matchTitle && !matchSummary) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Privacy Audit History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
        actions: [
          if (auditState.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear All History',
              onPressed: () => _confirmClearHistory(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search past audits...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryCyan),
                  ),
                ),
              ),
            ),

            // Filter Chips
            SliverFilterBar(
              selectedFilter: _selectedFilter,
              onFilterChanged: (level) =>
                  setState(() => _selectedFilter = level),
            ),

            // Audits List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            auditState.history.isEmpty
                                ? 'No Audits Recorded'
                                : 'No Matching Audits Found',
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
                            auditState.history.isEmpty
                                ? 'Scan a photo to start tracking privacy risks.'
                                : 'Try adjusting your search query or filter chips.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final report = filtered[index];
                        return _buildHistoryCard(context, report);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, PrivacyAuditReport report) {
    final riskColor = report.riskLevel.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(report.timestamp);

    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.riskCritical.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(auditProvider.notifier).deleteReport(report.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit removed from history')),
        );
      },
      child: CyberGlassCard(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        borderColor: riskColor.withOpacity(0.35),
        onTap: () {
          ref.read(auditProvider.notifier).setCurrentReport(report);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultsScreen(report: report)),
          );
        },
        child: Row(
          children: [
            // Score Pill
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.4)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${report.overallScore}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                      ),
                    ),
                    Text(
                      'SCORE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.riskLevel.label.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: riskColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                    '${report.detectedElements.length} threats • ${report.model ?? (report.isLiveAi ? "gemini" : "heuristic")}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Clear Audit History?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'This will permanently delete all saved privacy audit assessments from this device.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(auditProvider.notifier).clearHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskCritical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class SliverFilterBar extends StatelessWidget {
  final RiskLevel? selectedFilter;
  final ValueChanged<RiskLevel?> onFilterChanged;

  const SliverFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _buildChip(
            'All',
            selectedFilter == null,
            () => onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Critical',
            selectedFilter == RiskLevel.critical,
            () => onFilterChanged(RiskLevel.critical),
            color: AppColors.riskCritical,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'High',
            selectedFilter == RiskLevel.high,
            () => onFilterChanged(RiskLevel.high),
            color: AppColors.riskHigh,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Moderate',
            selectedFilter == RiskLevel.moderate,
            () => onFilterChanged(RiskLevel.moderate),
            color: AppColors.riskModerate,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Low',
            selectedFilter == RiskLevel.low,
            () => onFilterChanged(RiskLevel.low),
            color: AppColors.riskLow,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primaryCyan;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: activeColor.withOpacity(0.2),
      checkmarkColor: activeColor,
      backgroundColor: Colors.white.withOpacity(0.04),
      side: BorderSide(color: isSelected ? activeColor : AppColors.darkBorder),
      labelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppColors.textMuted,
      ),
    );
  }
}
