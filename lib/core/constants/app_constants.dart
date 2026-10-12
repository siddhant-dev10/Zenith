class AppConstants {
  static const String appName = 'Zenith';
  static const String appVersion = '1.0.0';
  static const String tagline =
      'AI-Powered Privacy & Security Risk Assessment System';
  static const String defaultGeminiModel = 'gemini-3.5-flash';
  static const String fallbackGeminiModel = 'gemini-1.5-flash';

  // SharedPreferences keys
  static const String keyApiKey = 'zenith_gemini_api_key';
  static const String keyModel = 'zenith_gemini_model';
  static const String keySensitivity = 'zenith_sensitivity_level';
  static const String keyAuditHistory = 'zenith_audit_history';
  static const String keyThemeMode = 'zenith_theme_mode';
  static const String keyUseMockFallback = 'zenith_use_mock_fallback';
  static const String keyBackendUrl = 'zenith_backend_url';
  static const String keyUseRemoteBackend = 'zenith_use_remote_backend';

  // Sensitivity modes
  static const String sensitivityConservative = 'Conservative';
  static const String sensitivityBalanced = 'Balanced';
  static const String sensitivityParanoid = 'Maximum OPSEC';
}
