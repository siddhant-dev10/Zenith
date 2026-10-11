import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum RiskLevel {
  low,
  moderate,
  high,
  critical;

  static RiskLevel fromScore(int score) {
    if (score <= 25) return RiskLevel.low;
    if (score <= 50) return RiskLevel.moderate;
    if (score <= 75) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static RiskLevel fromString(String val) {
    switch (val.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'moderate':
      case 'medium':
        return RiskLevel.moderate;
      case 'high':
        return RiskLevel.high;
      case 'critical':
      default:
        return RiskLevel.critical;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String get scoreRange {
    switch (this) {
      case RiskLevel.low:
        return '0-25';
      case RiskLevel.moderate:
        return '26-50';
      case RiskLevel.high:
        return '51-75';
      case RiskLevel.critical:
        return '76-100';
    }
  }

  String get description {
    switch (this) {
      case RiskLevel.low:
        return 'Minimal exposure. Image has negligible OPSEC risks for public sharing.';
      case RiskLevel.moderate:
        return 'Moderate exposure detected. Review background details before sharing online.';
      case RiskLevel.high:
        return 'Significant privacy leaks found. High potential for identity or location tracing.';
      case RiskLevel.critical:
        return 'Severe OPSEC breach detected. Sensitive PII, credentials, or tracking vectors exposed!';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.moderate:
        return AppColors.riskModerate;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.critical:
        return AppColors.riskCritical;
    }
  }

  Color get bgColor {
    switch (this) {
      case RiskLevel.low:
        return AppColors.riskLowBg;
      case RiskLevel.moderate:
        return AppColors.riskModerateBg;
      case RiskLevel.high:
        return AppColors.riskHighBg;
      case RiskLevel.critical:
        return AppColors.riskCriticalBg;
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.low:
        return Icons.verified_user_rounded;
      case RiskLevel.moderate:
        return Icons.info_outline_rounded;
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.critical:
        return Icons.gpp_bad_rounded;
    }
  }
}
