import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GlowingScannerHud extends StatefulWidget {
  final double width;
  final double height;
  final Color scanColor;

  const GlowingScannerHud({
    super.key,
    required this.width,
    required this.height,
    this.scanColor = AppColors.primaryCyan,
  });

  @override
  State<GlowingScannerHud> createState() => _GlowingScannerHudState();
}

class _GlowingScannerHudState extends State<GlowingScannerHud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ScannerHudPainter(
            progress: _controller.value,
            scanColor: widget.scanColor,
          ),
        );
      },
    );
  }
}

class _ScannerHudPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color scanColor;

  _ScannerHudPainter({required this.progress, required this.scanColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scanY = progress * size.height;

    // Grid lines (subtle cyber grid)
    final gridPaint = Paint()
      ..color = scanColor.withOpacity(0.06)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Laser scanning beam gradient
    final beamGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scanColor.withOpacity(0.0),
        scanColor.withOpacity(0.25),
        scanColor.withOpacity(0.9),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final beamRect = Rect.fromLTRB(
      0,
      math.max(0, scanY - 50),
      size.width,
      scanY,
    );
    final beamPaint = Paint()..shader = beamGradient.createShader(beamRect);
    canvas.drawRect(beamRect, beamPaint);

    // Sharp glowing horizontal laser line
    final lineGlowPaint = Paint()
      ..color = scanColor.withOpacity(0.7)
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), lineGlowPaint);

    final lineCorePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), lineCorePaint);

    // Corner HUD brackets
    const bracketSize = 24.0;
    const bracketStroke = 2.5;
    final bracketPaint = Paint()
      ..color = scanColor
      ..strokeWidth = bracketStroke
      ..style = PaintingStyle.stroke;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, bracketSize)
        ..lineTo(0, 0)
        ..lineTo(bracketSize, 0),
      bracketPaint,
    );
    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketSize, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, bracketSize),
      bracketPaint,
    );
    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - bracketSize)
        ..lineTo(0, size.height)
        ..lineTo(bracketSize, size.height),
      bracketPaint,
    );
    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketSize, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - bracketSize),
      bracketPaint,
    );

    // Center target reticle
    final center = Offset(size.width / 2, size.height / 2);
    final reticlePaint = Paint()
      ..color = scanColor.withOpacity(0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 30, reticlePaint);
    canvas.drawLine(
      Offset(center.dx - 40, center.dy),
      Offset(center.dx + 40, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 40),
      Offset(center.dx, center.dy + 40),
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerHudPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
