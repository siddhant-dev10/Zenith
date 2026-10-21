import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/detected_element.dart';
import 'cyber_glass_card.dart';

class ImageInspectionOverlay extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? imagePath;
  final String? sampleAsset;
  final List<DetectedElement> detectedElements;
  final ValueChanged<DetectedElement>? onElementSelected;
  final VoidCallback? onOpenRedactStudio;

  const ImageInspectionOverlay({
    super.key,
    this.imageBytes,
    this.imagePath,
    this.sampleAsset,
    required this.detectedElements,
    this.onElementSelected,
    this.onOpenRedactStudio,
  });

  @override
  State<ImageInspectionOverlay> createState() => _ImageInspectionOverlayState();
}

class _ImageInspectionOverlayState extends State<ImageInspectionOverlay> {
  bool _showMarkers = true;
  DetectedElement? _selectedElement;

  Widget _buildImage() {
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (widget.sampleAsset != null) {
      return Image.asset(
        widget.sampleAsset!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (widget.imagePath != null && !kIsWeb) {
      return Image.file(
        File(widget.imagePath!),
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else {
      return Container(
        height: 240,
        color: Colors.black26,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: Colors.white24,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elementsWithBoxes = widget.detectedElements
        .where((e) => e.boundingBox != null)
        .toList();

    return CyberGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      borderColor: AppColors.primaryCyan.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              border: const Border(
                bottom: BorderSide(color: AppColors.darkBorder),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.center_focus_strong_rounded,
                  size: 16,
                  color: AppColors.primaryCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'OPTICAL FORENSICS VIEW',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryCyan,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                // Toggle markers
                InkWell(
                  onTap: () => setState(() => _showMarkers = !_showMarkers),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _showMarkers
                          ? AppColors.primaryCyan.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _showMarkers
                            ? AppColors.primaryCyan
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showMarkers
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 13,
                          color: _showMarkers
                              ? AppColors.primaryCyan
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showMarkers ? 'HUD ON' : 'HUD OFF',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _showMarkers
                                ? AppColors.primaryCyan
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image & Bounding Box Stack
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = w * 0.65; // Aspect ratio approximation

                return SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),

                      // Bounding Boxes Layer
                      if (_showMarkers)
                        ...elementsWithBoxes.map((elem) {
                          final box = elem.boundingBox!;
                          final isSelected = _selectedElement?.id == elem.id;
                          final color = elem.riskLevel.color;

                          return Positioned(
                            left: box.left * w,
                            top: box.top * h,
                            width: box.width * w,
                            height: box.height * h,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedElement = elem);
                                widget.onElementSelected?.call(elem);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withOpacity(
                                    isSelected ? 0.28 : 0.12,
                                  ),
                                  border: Border.all(
                                    color: color,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      elem.name.toUpperCase(),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                      // Subtle scanning corner reticles
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _ReticleCorner(rotation: 0),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _ReticleCorner(rotation: 1),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: _ReticleCorner(rotation: 3),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: _ReticleCorner(rotation: 2),
                      ),

                      // Selected Element Info Callout Pill (at bottom of viewer)
                      if (_selectedElement != null)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkBg.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedElement!.riskLevel.color,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedElement!.riskLevel.icon,
                                  size: 16,
                                  color: _selectedElement!.riskLevel.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedElement!.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _selectedElement!.opsecImpact,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: AppColors.textLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () =>
                                      setState(() => _selectedElement = null),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Quick Action Bar
          if (widget.onOpenRedactStudio != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: widget.onOpenRedactStudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan.withOpacity(0.15),
                  foregroundColor: AppColors.primaryCyan,
                  elevation: 0,
                  side: const BorderSide(
                    color: AppColors.primaryCyan,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: Text(
                  'Launch Privacy Shield (Auto-Redact)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReticleCorner extends StatelessWidget {
  final int
  rotation; // 0: top-left, 1: top-right, 2: bottom-right, 3: bottom-left

  const _ReticleCorner({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * (3.14159 / 2),
      child: SizedBox(
        width: 14,
        height: 14,
        child: CustomPaint(painter: _ReticlePainter()),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
