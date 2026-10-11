import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_settings.dart';
import '../services/storage_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    _loadSettings();
    return const UserSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.loadSettings();
    state = settings;
  }

  Future<void> updateApiKey(String apiKey) async {
    final updated = state.copyWith(apiKey: apiKey);
    state = updated;
    await StorageService.saveSettings(updated);
  }

  Future<void> updateModel(String model) async {
    final updated = state.copyWith(model: model);
    state = updated;
    await StorageService.saveSettings(updated);
  }

  Future<void> updateSensitivity(String sensitivity) async {
    final updated = state.copyWith(sensitivity: sensitivity);
    state = updated;
    await StorageService.saveSettings(updated);
  }

  Future<void> toggleMockFallback(bool useMock) async {
    final updated = state.copyWith(useMockFallback: useMock);
    state = updated;
    await StorageService.saveSettings(updated);
  }

  Future<void> updateThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    state = updated;
    await StorageService.saveSettings(updated);
  }
}
