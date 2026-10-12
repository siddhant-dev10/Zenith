import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/network/api_config.dart';
import 'package:zenith/models/user_settings.dart';

void main() {
  group('ApiConfig Environment & Diagnostic Tests', () {
    test('ApiConfig.sanitizeUrl normalizes trailing slashes and schemes', () {
      expect(ApiConfig.sanitizeUrl('http://10.0.2.2:8080/'), equals('http://10.0.2.2:8080'));
      expect(ApiConfig.sanitizeUrl('http://10.0.2.2:8080///'), equals('http://10.0.2.2:8080'));
      expect(ApiConfig.sanitizeUrl('192.168.1.100:8080'), equals('http://192.168.1.100:8080'));
      expect(ApiConfig.sanitizeUrl('https://api.zenith.privacy/'), equals('https://api.zenith.privacy'));
      expect(ApiConfig.sanitizeUrl('   '), equals(ApiConfig.getDefaultBackendUrl()));
    });

    test('ApiConfig.diagnoseConnectionError provides clear guidance for Android localhost 111', () {
      final error = const SocketException('Connection refused (OS Error: Connection refused, errno = 111)');
      final diag = ApiConfig.diagnoseConnectionError(error, 'http://localhost:8080');

      if (Platform.isAndroid) {
        expect(diag, contains('10.0.2.2:8080'));
        expect(diag, contains('Physical Phone'));
        expect(diag, contains('adb reverse'));
      } else {
        expect(diag, contains('Unable to connect to Zenith backend'));
        expect(diag, contains('bin/zenith_server.dart'));
      }
    });

    test('ApiConfig.diagnoseConnectionError detects cleartext HTTP restrictions', () {
      final error = Exception('CLEARTEXT_COMMUNICATION_NOT_PERMITTED');
      final diag = ApiConfig.diagnoseConnectionError(error, 'http://10.0.2.2:8080');

      expect(diag, contains('usesCleartextTraffic'));
      expect(diag, contains('Network Security Policy'));
    });

    test('ApiConfig.diagnoseConnectionError detects timeouts and provides LAN router guidance', () {
      final error = Exception('Request timed out after 10000ms');
      final diag = ApiConfig.diagnoseConnectionError(error, 'http://192.168.1.50:8080');

      expect(diag, contains('timed out'));
      expect(diag, contains('Wi-Fi'));
    });

    test('UserSettings resolves backendUrl through ApiConfig without hardcoding', () {
      const settingsDefault = UserSettings();
      expect(settingsDefault.backendUrl, equals(ApiConfig.getDefaultBackendUrl()));

      final settingsCustom = const UserSettings().copyWith(backendUrl: 'http://192.168.0.16:8080');
      expect(settingsCustom.backendUrl, equals('http://192.168.0.16:8080'));
    });

    test('UserSettings serialization preserves custom backendUrl', () {
      const original = UserSettings(backendUrl: 'https://custom.zenith.corp:8443');
      final json = original.toJson();
      final revived = UserSettings.fromJson(json);

      expect(revived.backendUrl, equals('https://custom.zenith.corp:8443'));
    });

    test('ApiConfig provides reachable defaultLanUrl for physical mobile devices', () {
      expect(ApiConfig.defaultLanUrl, equals('http://192.168.0.16:8080'));
    });

    test('ApiConfig.diagnoseConnectionError handles 10.0.2.2 connection refusal diagnostic', () {
      final error = const SocketException('Connection refused (OS Error: Connection refused, errno = 111)');
      final diag = ApiConfig.diagnoseConnectionError(error, 'http://10.0.2.2:8080');
      // On non-Android test runner, it provides server guide; on Android it provides 10.0.2.2 physical guide
      if (Platform.isAndroid) {
        expect(diag, contains('Android Emulator'));
        expect(diag, contains('Physical Phone'));
      } else {
        expect(diag, contains('Unable to connect to Zenith backend at http://10.0.2.2:8080'));
      }
    });
  });
}
