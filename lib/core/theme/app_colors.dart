import 'package:flutter/material.dart';

export 'model_ui_extensions.dart';

class AppColors {
  // Deep Cyber Theme Palette (Dark)
  static const Color darkBg = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF182234);
  static const Color darkCardHover = Color(0xFF1F2D44);
  static const Color darkBorder = Color(0xFF26354D);
  static const Color darkBorderGlow = Color(0xFF38BDF8);

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Accents & Brand
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryCyanDark = Color(0xFF00B4D8);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentViolet = Color(0xFF8B5CF6);

  // OPSEC Risk Colors
  static const Color riskLow = Color(0xFF10B981); // Neon Emerald (0-25)
  static const Color riskModerate = Color(0xFFF59E0B); // Amber Warning (26-50)
  static const Color riskHigh = Color(0xFFF97316); // Vivid Coral (51-75)
  static const Color riskCritical = Color(0xFFEF4444); // Electric Red (76-100)

  // Background tints for risks
  static const Color riskLowBg = Color(0x1A10B981);
  static const Color riskModerateBg = Color(0x1AF59E0B);
  static const Color riskHighBg = Color(0x1AF97316);
  static const Color riskCriticalBg = Color(0x1AEF4444);

  // Text Colors
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDarkMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  // Category Colors
  static const Color catIdentity = Color(0xFFEC4899); // Pink
  static const Color catLocation = Color(0xFF3B82F6); // Blue
  static const Color catDigital = Color(0xFF8B5CF6); // Purple
  static const Color catPersonalInfo = Color(0xFFEAB308); // Yellow
  static const Color catTransportation = Color(0xFF14B8A6); // Teal

  static Color getRiskColor(int score) {
    if (score <= 25) return riskLow;
    if (score <= 50) return riskModerate;
    if (score <= 75) return riskHigh;
    return riskCritical;
  }

  static Color getRiskBgColor(int score) {
    if (score <= 25) return riskLowBg;
    if (score <= 50) return riskModerateBg;
    if (score <= 75) return riskHighBg;
    return riskCriticalBg;
  }
}
