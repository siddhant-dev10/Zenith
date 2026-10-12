import 'package:flutter/material.dart';

import '../../models/exposure_category.dart';
import '../../models/risk_level.dart';
import 'app_colors.dart';

extension ExposureCategoryUI on ExposureCategory {
  Color get color {
    switch (this) {
      case ExposureCategory.identity:
        return AppColors.catIdentity;
      case ExposureCategory.location:
        return AppColors.catLocation;
      case ExposureCategory.digital:
        return AppColors.catDigital;
      case ExposureCategory.personalInfo:
        return AppColors.catPersonalInfo;
      case ExposureCategory.transportation:
        return AppColors.catTransportation;
    }
  }

  IconData get icon {
    switch (this) {
      case ExposureCategory.identity:
        return Icons.badge_outlined;
      case ExposureCategory.location:
        return Icons.location_on_outlined;
      case ExposureCategory.digital:
        return Icons.devices_outlined;
      case ExposureCategory.personalInfo:
        return Icons.contact_emergency_outlined;
      case ExposureCategory.transportation:
        return Icons.directions_car_outlined;
    }
  }
}

extension RiskLevelUI on RiskLevel {
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
