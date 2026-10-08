import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/recommendation.dart';
import 'cyber_glass_card.dart';

class RecommendationCard extends StatefulWidget {
  final Recommendation recommendation;
  final ValueChanged<bool>? onToggleComplete;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onToggleComplete,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.recommendation.isCompleted;
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'blur':
        return Icons.blur_on_rounded;
      case 'crop':
        return Icons.crop_rounded;
      case 'scrub_exif':
        return Icons.cleaning_services_rounded;
      case 'do_not_share':
        return Icons.block_rounded;
      case 'rotate':
        return Icons.refresh_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final priorityColor = rec.priority.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CyberGlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: _completed
          ? AppColors.riskLow.withOpacity(0.5)
          : priorityColor.withOpacity(0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox / Toggle
          GestureDetector(
            onTap: () {
              setState(() => _completed = !_completed);
              widget.onToggleComplete?.call(_completed);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _completed
                    ? AppColors.riskLow
                    : priorityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _completed ? AppColors.riskLow : priorityColor,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _completed ? Icons.check_rounded : _getTypeIcon(rec.type),
                size: 16,
                color: _completed ? Colors.white : priorityColor,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rec.priority.label.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rec.type.toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rec.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration:
                        _completed ? TextDecoration.lineThrough : null,
                    color: _completed
                        ? AppColors.textMuted
                        : (isDark ? AppColors.textWhite : AppColors.textDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.action,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.textLight : AppColors.textDarkMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
