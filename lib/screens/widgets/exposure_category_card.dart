import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/exposure_category.dart';
import '../../models/risk_level.dart';
import 'cyber_glass_card.dart';

class ExposureCategoryCard extends StatelessWidget {
  final ExposureCategory category;
  final int score;
  final int detectedCount;
  final VoidCallback? onTap;

  const ExposureCategoryCard({
    super.key,
    required this.category,
    required this.score,
    this.detectedCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = RiskLevel.fromScore(score);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CyberGlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      borderColor: detectedCount > 0
          ? riskLevel.color.withOpacity(0.35)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: category.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(category.icon, size: 20, color: category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detectedCount == 1
                          ? '1 item identified'
                          : '$detectedCount items identified',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: detectedCount > 0
                            ? riskLevel.color
                            : AppColors.textMuted,
                        fontWeight: detectedCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: riskLevel.color,
                    ),
                  ),
                  Text(
                    riskLevel.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: isDark
                      ? AppColors.darkBorder.withOpacity(0.5)
                      : AppColors.lightBorder,
                ),
                FractionallySizedBox(
                  widthFactor: (score / 100.0).clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          category.color,
                          riskLevel.color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: riskLevel.color.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
