import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/privacy_audit_report.dart';
import '../models/risk_level.dart';
import '../models/user_settings.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Settings ---
  static Future<UserSettings> loadSettings() async {
    final prefs = await _instance;
    final apiKey = prefs.getString(AppConstants.keyApiKey) ?? '';
    final model =
        prefs.getString(AppConstants.keyModel) ?? AppConstants.defaultGeminiModel;
    final sensitivity = prefs.getString(AppConstants.keySensitivity) ??
        AppConstants.sensitivityBalanced;
    final useMock = prefs.getBool(AppConstants.keyUseMockFallback) ?? true;
    final theme = prefs.getString(AppConstants.keyThemeMode) ?? 'dark';

    return UserSettings(
      apiKey: apiKey,
      model: model,
      sensitivity: sensitivity,
      useMockFallback: useMock,
      themeMode: theme,
    );
  }

  static Future<void> saveSettings(UserSettings settings) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.keyApiKey, settings.apiKey);
    await prefs.setString(AppConstants.keyModel, settings.model);
    await prefs.setString(AppConstants.keySensitivity, settings.sensitivity);
    await prefs.setBool(AppConstants.keyUseMockFallback, settings.useMockFallback);
    await prefs.setString(AppConstants.keyThemeMode, settings.themeMode);
  }

  // --- Audit History ---
  static Future<List<PrivacyAuditReport>> loadHistory() async {
    final prefs = await _instance;
    final jsonList = prefs.getStringList(AppConstants.keyAuditHistory) ?? [];
    final reports = <PrivacyAuditReport>[];
    for (final raw in jsonList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        reports.add(PrivacyAuditReport.fromJson(map));
      } catch (_) {
        // Skip malformed entries
      }
    }
    // Sort newest first
    reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reports;
  }

  static Future<void> saveReport(PrivacyAuditReport report) async {
    final prefs = await _instance;
    final current = await loadHistory();
    // Prepend new report (avoid duplicate id)
    current.removeWhere((r) => r.id == report.id);
    current.insert(0, report);

    // Keep max 50 recent reports to preserve space
    final trimmed = current.take(50).toList();
    final jsonList = trimmed.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(AppConstants.keyAuditHistory, jsonList);
  }

  static Future<void> deleteReport(String id) async {
    final prefs = await _instance;
    final current = await loadHistory();
    current.removeWhere((r) => r.id == id);
    final jsonList = current.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(AppConstants.keyAuditHistory, jsonList);
  }

  static Future<void> clearHistory() async {
    final prefs = await _instance;
    await prefs.remove(AppConstants.keyAuditHistory);
  }

  // --- Quick Stats ---
  static Future<Map<String, dynamic>> getAuditStats() async {
    final history = await loadHistory();
    if (history.isEmpty) {
      return {
        'totalAudits': 0,
        'criticalBreaches': 0,
        'highRisks': 0,
        'averageScore': 0,
      };
    }

    final total = history.length;
    final critical =
        history.where((r) => r.riskLevel == RiskLevel.critical).length;
    final high = history.where((r) => r.riskLevel == RiskLevel.high).length;
    final avgScore =
        (history.map((r) => r.overallScore).reduce((a, b) => a + b) / total).round();

    return {
      'totalAudits': total,
      'criticalBreaches': critical,
      'highRisks': high,
      'averageScore': avgScore,
    };
  }
}
