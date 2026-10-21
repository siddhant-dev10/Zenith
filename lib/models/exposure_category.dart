enum ExposureCategory {
  identity,
  location,
  digital,
  personalInfo,
  transportation;

  static ExposureCategory fromString(String val) {
    switch (val.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'identity':
      case 'identityexposure':
        return ExposureCategory.identity;
      case 'location':
      case 'locationexposure':
        return ExposureCategory.location;
      case 'digital':
      case 'digitalexposure':
      case 'digitalsecurity':
        return ExposureCategory.digital;
      case 'personalinfo':
      case 'personalinformation':
      case 'personalinformationexposure':
      case 'personaldata':
        return ExposureCategory.personalInfo;
      case 'transportation':
      case 'transportationexposure':
      case 'transit':
      case 'otherexposures':
      case 'other':
        return ExposureCategory.transportation;
      default:
        return ExposureCategory.identity;
    }
  }

  String get id {
    switch (this) {
      case ExposureCategory.identity:
        return 'identity';
      case ExposureCategory.location:
        return 'location';
      case ExposureCategory.digital:
        return 'digital';
      case ExposureCategory.personalInfo:
        return 'personal_info';
      case ExposureCategory.transportation:
        return 'transportation';
    }
  }

  String get displayName {
    switch (this) {
      case ExposureCategory.identity:
        return 'Identity Exposure';
      case ExposureCategory.location:
        return 'Location Exposure';
      case ExposureCategory.digital:
        return 'Digital Exposure';
      case ExposureCategory.personalInfo:
        return 'Personal Info Exposure';
      case ExposureCategory.transportation:
        return 'Transportation Exposure';
    }
  }

  String get shortName {
    switch (this) {
      case ExposureCategory.identity:
        return 'Identity';
      case ExposureCategory.location:
        return 'Location';
      case ExposureCategory.digital:
        return 'Digital';
      case ExposureCategory.personalInfo:
        return 'Personal Data';
      case ExposureCategory.transportation:
        return 'Transportation';
    }
  }

  String get description {
    switch (this) {
      case ExposureCategory.identity:
        return 'Faces, student badges, work IDs, government credentials, family photos';
      case ExposureCategory.location:
        return 'Street signs, building facades, house numbers, geo-landmarks, view outside window';
      case ExposureCategory.digital:
        return 'Monitors, terminal shells, open browser tabs, code, Slack/Discord messages';
      case ExposureCategory.personalInfo:
        return 'Phone numbers, emails, QR codes, medical files, payment cards, letters';
      case ExposureCategory.transportation:
        return 'License plates, airline boarding passes, parking decals, train tickets';
    }
  }
}
