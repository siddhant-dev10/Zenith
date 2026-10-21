import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/risk_level.dart';

class RiskMeterGauge extends StatelessWidget {
  final int score;
  final RiskLevel riskLevel;
  final double size;

  const RiskMeterGauge({
    super.key,
    required this.score,
    required this.riskLevel,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final color = riskLevel.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow circle
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isDark ? 0.25 : 0.15),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            // Custom arc painter
            CustomPaint(
              size: Size(size, size),
              painter: _RiskArcPainter(
                score: score,
                riskColor: color,
                trackColor: isDark
                    ? AppColors.darkBorder.withOpacity(0.4)
                    : AppColors.lightBorder,
              ),
            ),
            // Inner score & title
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OPSEC RISK',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Text(
                      '/100',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(riskLevel.icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        riskLevel.label.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskArcPainter extends CustomPainter {
  final int score;
  final Color riskColor;
  final Color trackColor;

  _RiskArcPainter({
    required this.score,
    required this.riskColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Start angle: 135 deg (bottom left), sweep 270 deg (ending bottom right)
    const startAngle = 135 * (math.pi / 180);
    const totalSweep = 270 * (math.pi / 180);
    final progressSweep = totalSweep * (score.clamp(0, 100) / 100.0);

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    if (score > 0) {
      // Progress Gradient Arc Paint
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweep,
          colors: [
            AppColors.riskLow,
            score > 25 ? AppColors.riskModerate : AppColors.riskLow,
            score > 50 ? AppColors.riskHigh : AppColors.riskModerate,
            riskColor,
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );

      // Indicator tip dot
      final angle = startAngle + progressSweep;
      final tipX = center.dx + radius * math.cos(angle);
      final tipY = center.dy + radius * math.sin(angle);

      final glowPaint = Paint()
        ..color = riskColor.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(tipX, tipY), 9, glowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(tipX, tipY), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiskArcPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.riskColor != riskColor;
  }
}
