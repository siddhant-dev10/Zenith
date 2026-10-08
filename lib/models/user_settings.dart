import '../core/constants/app_constants.dart';

class UserSettings {
  final String apiKey;
  final String model;
  final String sensitivity;
  final bool useMockFallback;
  final String themeMode;

  const UserSettings({
    this.apiKey = '',
    this.model = AppConstants.defaultGeminiModel,
    this.sensitivity = AppConstants.sensitivityBalanced,
    this.useMockFallback = true,
    this.themeMode = 'dark',
  });

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  UserSettings copyWith({
    String? apiKey,
    String? model,
    String? sensitivity,
    bool? useMockFallback,
    String? themeMode,
  }) {
    return UserSettings(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      sensitivity: sensitivity ?? this.sensitivity,
      useMockFallback: useMockFallback ?? this.useMockFallback,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'model': model,
        'sensitivity': sensitivity,
        'useMockFallback': useMockFallback,
        'themeMode': themeMode,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? AppConstants.defaultGeminiModel,
      sensitivity: json['sensitivity'] as String? ?? AppConstants.sensitivityBalanced,
      useMockFallback: json['useMockFallback'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'dark',
    );
  }
}
