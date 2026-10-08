import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/detected_element.dart';
import 'cyber_glass_card.dart';

class DetectedElementTile extends StatefulWidget {
  final DetectedElement element;
  final VoidCallback? onHighlight;

  const DetectedElementTile({
    super.key,
    required this.element,
    this.onHighlight,
  });

  @override
  State<DetectedElementTile> createState() => _DetectedElementTileState();
}

class _DetectedElementTileState extends State<DetectedElementTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final elem = widget.element;
    final riskColor = elem.riskLevel.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CyberGlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: riskColor.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: riskColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(elem.riskLevel.icon, size: 16, color: riskColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elem.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: elem.category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: elem.category.color.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            elem.category.shortName,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: elem.category.color,
                            ),
                          ),
                        ),
                        // Risk Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: riskColor.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            elem.riskLevel.label.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: riskColor,
                            ),
                          ),
                        ),
                        // Confidence Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(elem.confidence * 100).toInt()}% conf',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            elem.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.textLight : AppColors.textDark,
              height: 1.4,
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.riskHighBg.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.riskHigh.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.security_update_warning_rounded,
                    color: AppColors.riskHigh,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OPSEC EXPOSURE IMPACT',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.riskHigh,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          elem.opsecImpact,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
