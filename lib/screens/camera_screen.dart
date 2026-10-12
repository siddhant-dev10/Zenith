import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../providers/audit_provider.dart';
import '../services/sample_data_service.dart';
import 'analysis_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _permissionDenied = false;
  bool _isCapturing = false;
  bool _flashOn = false;
  bool _gridOn = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _permissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          if (e.toString().contains('permission') ||
              e.toString().contains('denied') ||
              e.toString().contains('CameraAccessDenied')) {
            _permissionDenied = true;
          }
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_isCapturing) return;

    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isTakingPicture) {
      try {
        setState(() => _isCapturing = true);
        final xFile = await _cameraController!.takePicture();
        final bytes = await xFile.readAsBytes();
        ref
            .read(auditProvider.notifier)
            .setImageBytes(bytes: bytes, path: xFile.path);
      } catch (e) {
        // Fallback to ImagePicker camera pick
        await ref.read(auditProvider.notifier).pickFromCamera();
      } finally {
        if (mounted) setState(() => _isCapturing = false);
      }
    } else {
      // Fallback for desktop / simulator / non-controller environments
      await ref.read(auditProvider.notifier).pickFromCamera();
    }
  }

  Future<void> _pickGallery() async {
    await ref.read(auditProvider.notifier).pickFromGallery();
  }

  void _retake() {
    ref.read(auditProvider.notifier).clearSelection();
  }

  void _proceedToAnalysis() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
    );
  }

  Widget _buildPreview(AuditState state) {
    // 1. Captured / Selected image preview
    if (state.selectedImageBytes != null) {
      return Image.memory(
        state.selectedImageBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (state.selectedSampleAsset != null) {
      return Image.asset(
        state.selectedSampleAsset!,
        fit: BoxFit.contain,
        width: double.infinity,
      );
    } else if (state.selectedImagePath != null && !kIsWeb) {
      return Image.file(
        File(state.selectedImagePath!),
        fit: BoxFit.contain,
        width: double.infinity,
      );
    }

    // 2. Live Hardware Camera Preview
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      );
    }

    // 3. Permission Denied Fallback
    if (_permissionDenied) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              size: 52,
              color: AppColors.riskCritical,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Access Denied',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera permission is required to capture photos directly. You can enable it in system settings, or upload an existing photo from your gallery.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickGallery,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: AppColors.darkBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text('Upload from Gallery'),
            ),
          ],
        ),
      );
    }

    // 4. Standby Viewfinder for Desktop / Simulator / Standby
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: AppColors.primaryCyan,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Align Subject in Viewfinder',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture IDs, badges, screens, or documents',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);
    final hasImage = auditState.hasImageSelected;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Flash Toggle (if camera active)
                      IconButton(
                        icon: Icon(
                          _flashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: _flashOn
                              ? AppColors.primaryCyan
                              : Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _flashOn = !_flashOn);
                          if (_cameraController != null &&
                              _cameraController!.value.isInitialized) {
                            _cameraController!.setFlashMode(
                              _flashOn ? FlashMode.torch : FlashMode.off,
                            );
                          }
                        },
                      ),
                      // Grid Toggle
                      IconButton(
                        icon: Icon(
                          _gridOn
                              ? Icons.grid_on_rounded
                              : Icons.grid_off_rounded,
                          color: _gridOn
                              ? AppColors.primaryCyan
                              : Colors.white70,
                        ),
                        onPressed: () => setState(() => _gridOn = !_gridOn),
                      ),
                      // Preset Scenario Quick Picker
                      PopupMenuButton<SampleScenario>(
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white70,
                        ),
                        tooltip: 'Load Sample Scenario',
                        color: AppColors.darkSurface,
                        onSelected: (sc) {
                          ref.read(auditProvider.notifier).selectSample(sc);
                        },
                        itemBuilder: (context) {
                          return SampleDataService.getScenarios().map((sc) {
                            return PopupMenuItem<SampleScenario>(
                              value: sc,
                              child: Text(
                                sc.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),

                // Main Viewfinder Frame
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F141C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasImage
                                ? AppColors.riskLow.withOpacity(0.8)
                                : AppColors.primaryCyan.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildPreview(auditState),

                            // Grid Lines Overlay
                            if (_gridOn)
                              CustomPaint(painter: _ViewfinderGridPainter()),

                            // Cyber Brackets in Corners
                            const Positioned(
                              top: 12,
                              left: 12,
                              child: _ViewfinderCorner(rotation: 0),
                            ),
                            const Positioned(
                              top: 12,
                              right: 12,
                              child: _ViewfinderCorner(rotation: 1),
                            ),
                            const Positioned(
                              bottom: 12,
                              left: 12,
                              child: _ViewfinderCorner(rotation: 3),
                            ),
                            const Positioned(
                              bottom: 12,
                              right: 12,
                              child: _ViewfinderCorner(rotation: 2),
                            ),

                            // OPSEC Target Status Pill
                            Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: hasImage
                                          ? AppColors.riskLow
                                          : AppColors.primaryCyan,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: hasImage
                                              ? AppColors.riskLow
                                              : AppColors.primaryCyan,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hasImage
                                            ? 'PHOTOGRAPH PREVIEW READY'
                                            : (_isCameraInitialized
                                                  ? 'LIVE CAMERA ACTIVE'
                                                  : 'VIEWFINDER STANDBY'),
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Controls Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: hasImage
                      ? _buildConfirmControls()
                      : _buildCaptureControls(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Gallery Button
        IconButton(
          icon: const Icon(
            Icons.photo_library_rounded,
            size: 28,
            color: Colors.white,
          ),
          tooltip: 'Upload from Gallery',
          onPressed: _pickGallery,
        ),
        // Primary Capture Shutter
        GestureDetector(
          onTap: _isCapturing ? null : _capture,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isCapturing ? AppColors.primaryCyan : Colors.white,
                width: 4,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isCapturing
                      ? [AppColors.riskModerate, AppColors.riskCritical]
                      : [AppColors.primaryCyan, AppColors.accentIndigo],
                ),
              ),
              child: Icon(
                _isCapturing
                    ? Icons.hourglass_top_rounded
                    : Icons.camera_alt_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        // Quick Scenario Sample
        IconButton(
          icon: const Icon(
            Icons.filter_hdr_rounded,
            size: 28,
            color: Colors.white,
          ),
          tooltip: 'Test Student ID Scenario',
          onPressed: () {
            ref
                .read(auditProvider.notifier)
                .selectSample(SampleDataService.getScenarios().first);
          },
        ),
      ],
    );
  }

  Widget _buildConfirmControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Retake Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Retake',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Replace via Gallery
            IconButton(
              icon: const Icon(
                Icons.photo_library_rounded,
                color: Colors.white70,
              ),
              tooltip: 'Replace from Gallery',
              onPressed: _pickGallery,
            ),
            const SizedBox(width: 8),
            // Confirm & Analyze Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _proceedToAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: AppColors.darkBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.security_rounded, size: 20),
                label: Text(
                  'CONFIRM & ANALYZE',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.8;

    final x1 = size.width / 3;
    final x2 = (size.width / 3) * 2;
    final y1 = size.height / 3;
    final y2 = (size.height / 3) * 2;

    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ViewfinderCorner extends StatelessWidget {
  final int rotation;

  const _ViewfinderCorner({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * (3.14159 / 2),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryCyan
      ..strokeWidth = 2.5
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
