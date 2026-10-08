import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const HomeScreen(),
            transitionsBuilder: (context, anim, secAnim, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background ambient cyber radial glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.12),
                    AppColors.accentIndigo.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Shield with radar pulse
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.3, 1.3),
                          duration: 2.seconds,
                        )
                        .fadeOut(duration: 2.seconds),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryCyan,
                            AppColors.accentIndigo,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.4),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.security_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .shimmer(delay: 800.ms, duration: 1.seconds),
                  ],
                ),
                const SizedBox(height: 28),

                // App Brand
                Text(
                  AppConstants.appName.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    AppConstants.tagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 48),

                // Subtle OPSEC loading indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(duration: 800.ms),
                      const SizedBox(width: 8),
                      Text(
                        'INITIALIZING NEURAL SHIELD',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryCyan,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 500.ms),
              ],
            ),
          ),

          // Bottom version pill
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v${AppConstants.appVersion} • MULTIMODAL OPSEC INTELLIGENCE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textDarkMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
