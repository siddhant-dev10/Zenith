import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_config.dart';

class UserSettings {
  final String apiKey;
  final String model;
  final String sensitivity;
  final bool useMockFallback;
  final String themeMode;
  final String? _rawBackendUrl;
  final bool useRemoteBackend;

  const UserSettings({
    this.apiKey = '',
    this.model = AppConstants.defaultGeminiModel,
    this.sensitivity = AppConstants.sensitivityBalanced,
    this.useMockFallback = true,
    this.themeMode = 'dark',
    String? backendUrl,
    this.useRemoteBackend = true,
  }) : _rawBackendUrl = backendUrl;

  /// Resolves the effective, environment-aware backend URL.
  String get backendUrl {
    final raw = _rawBackendUrl?.trim() ?? '';
    if (raw.isEmpty) {
      return ApiConfig.getDefaultBackendUrl();
    }
    // Auto-migrate legacy defaults when compiled with explicit BACKEND_URL
    if (ApiConfig.hasCompileTimeOverride &&
        (raw == ApiConfig.defaultEmulatorUrl ||
         raw == ApiConfig.defaultLocalhostUrl ||
         raw == 'http://127.0.0.1:8080')) {
      return ApiConfig.getDefaultBackendUrl();
    }
    // On physical Android devices where 10.0.2.2 or localhost fails,
    // auto-migrate legacy stored values to reachable LAN URL
    if (!kIsWeb &&
        Platform.isAndroid &&
        ApiConfig.getDefaultBackendUrl() == ApiConfig.defaultLanUrl &&
        (raw == ApiConfig.defaultEmulatorUrl ||
         raw == ApiConfig.defaultLocalhostUrl ||
         raw == 'http://127.0.0.1:8080')) {
      return ApiConfig.defaultLanUrl;
    }
    return ApiConfig.sanitizeUrl(raw);
  }

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  UserSettings copyWith({
    String? apiKey,
    String? model,
    String? sensitivity,
    bool? useMockFallback,
    String? themeMode,
    String? backendUrl,
    bool? useRemoteBackend,
  }) {
    return UserSettings(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      sensitivity: sensitivity ?? this.sensitivity,
      useMockFallback: useMockFallback ?? this.useMockFallback,
      themeMode: themeMode ?? this.themeMode,
      backendUrl: backendUrl ?? _rawBackendUrl,
      useRemoteBackend: useRemoteBackend ?? this.useRemoteBackend,
    );
  }

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'model': model,
    'sensitivity': sensitivity,
    'useMockFallback': useMockFallback,
    'themeMode': themeMode,
    'backendUrl': backendUrl,
    'useRemoteBackend': useRemoteBackend,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? AppConstants.defaultGeminiModel,
      sensitivity:
          json['sensitivity'] as String? ?? AppConstants.sensitivityBalanced,
      useMockFallback: json['useMockFallback'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'dark',
      backendUrl: json['backendUrl'] as String?,
      useRemoteBackend: json['useRemoteBackend'] as bool? ?? true,
    );
  }
}
