import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/detected_element.dart';
import '../../models/exposure_category.dart';

class AutoRedactPreviewModal extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? imagePath;
  final String? sampleAsset;
  final List<DetectedElement> detectedElements;

  const AutoRedactPreviewModal({
    super.key,
    this.imageBytes,
    this.imagePath,
    this.sampleAsset,
    required this.detectedElements,
  });

  @override
  State<AutoRedactPreviewModal> createState() => _AutoRedactPreviewModalState();
}

class _AutoRedactPreviewModalState extends State<AutoRedactPreviewModal> {
  bool _redactIdentity = true;
  bool _redactLocation = true;
  bool _redactDigital = true;
  bool _redactPersonalInfo = true;
  bool _redactTransportation = true;
  bool _useBlurStyle = false; // false = solid black bar, true = blur filter
  bool _saved = false;

  bool _shouldRedact(DetectedElement elem) {
    switch (elem.category) {
      case ExposureCategory.identity:
        return _redactIdentity;
      case ExposureCategory.location:
        return _redactLocation;
      case ExposureCategory.digital:
        return _redactDigital;
      case ExposureCategory.personalInfo:
        return _redactPersonalInfo;
      case ExposureCategory.transportation:
        return _redactTransportation;
    }
  }

  Widget _buildBaseImage() {
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
        height: 200,
        color: Colors.black26,
        child: const Center(child: Icon(Icons.broken_image)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRedactions = widget.detectedElements
        .where((e) => e.boundingBox != null && _shouldRedact(e))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.primaryCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zenith Privacy Shield',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Auto-Redaction & OPSEC Sanitization',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Redacted Preview Frame
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = w * 0.65;

                  return SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBaseImage(),

                        // Redaction Overlays
                        ...activeRedactions.map((elem) {
                          final box = elem.boundingBox!;

                          return Positioned(
                            left: box.left * w,
                            top: box.top * h,
                            width: box.width * w,
                            height: box.height * h,
                            child: _useBlurStyle
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 18,
                                        sigmaY: 18,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: Colors.black87,
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'REDACTED',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white70,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                          );
                        }),

                        // Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.riskLow.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${activeRedactions.length} REGIONS SANITIZED',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Redaction Mode Selector
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _useBlurStyle = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_useBlurStyle
                          ? AppColors.primaryCyan.withOpacity(0.18)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_useBlurStyle
                            ? AppColors.primaryCyan
                            : AppColors.darkBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Solid Black Censorship',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: !_useBlurStyle
                              ? AppColors.primaryCyan
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _useBlurStyle = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _useBlurStyle
                          ? AppColors.primaryCyan.withOpacity(0.18)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _useBlurStyle
                            ? AppColors.primaryCyan
                            : AppColors.darkBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Gaussian Privacy Blur',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _useBlurStyle
                              ? AppColors.primaryCyan
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter toggles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Identity & PII', _redactIdentity, (v) {
                setState(() => _redactIdentity = v);
              }),
              _buildFilterChip('Location Cues', _redactLocation, (v) {
                setState(() => _redactLocation = v);
              }),
              _buildFilterChip('Digital Screens', _redactDigital, (v) {
                setState(() => _redactDigital = v);
              }),
              _buildFilterChip('Codes & Barcodes', _redactPersonalInfo, (v) {
                setState(() => _redactPersonalInfo = v);
              }),
              _buildFilterChip('Vehicles & Transit', _redactTransportation, (
                v,
              ) {
                setState(() => _redactTransportation = v);
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Action Button
          ElevatedButton.icon(
            onPressed: () {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _saved = true);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sanitized photo saved to Photos! Sensitive OPSEC elements redacted.',
                  ),
                  backgroundColor: AppColors.riskLow,
                ),
              );
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) navigator.pop();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: AppColors.darkBg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Icon(
              _saved
                  ? Icons.check_circle_rounded
                  : Icons.file_download_outlined,
              size: 20,
            ),
            label: Text(
              _saved ? 'SANITIZED & SAVED' : 'SAVE SANITIZED PHOTO',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.primaryCyan.withOpacity(0.2),
      checkmarkColor: AppColors.primaryCyan,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: value ? Colors.white : AppColors.textMuted,
      ),
      backgroundColor: Colors.white.withOpacity(0.05),
      side: BorderSide(
        color: value ? AppColors.primaryCyan : AppColors.darkBorder,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
