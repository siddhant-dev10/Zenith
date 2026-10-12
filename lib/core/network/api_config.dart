import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized environment-specific API configuration and connectivity diagnostics.
class ApiConfig {
  /// Standard loopback address for desktop, macOS, Linux, and Windows development.
  static const String defaultLocalhostUrl = 'http://localhost:8080';

  /// Standard Android emulator loopback alias to host machine's 127.0.0.1.
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8080';

  /// Default production / staging HTTPS backend template (if configured).
  static const String defaultProductionUrl = 'https://api.zenith.privacy';

  /// Compile-time environment override via `--dart-define=BACKEND_URL=https://...`
  static const String _compileTimeBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  /// Resolves the recommended default backend URL based on platform & environment.
  static String getDefaultBackendUrl() {
    // 1. Compile-time flag takes highest priority
    if (_compileTimeBackendUrl.trim().isNotEmpty) {
      return _compileTimeBackendUrl.trim();
    }

    // 2. Web platform
    if (kIsWeb) {
      return defaultLocalhostUrl;
    }

    // 3. Android platform (physical device or emulator)
    // On Android, localhost (127.0.0.1) points to the phone/emulator itself,
    // which causes SocketException: Connection refused (errno = 111).
    // The emulator requires 10.0.2.2 to reach the host development computer.
    if (Platform.isAndroid) {
      return defaultEmulatorUrl;
    }

    // 4. iOS Simulator, macOS, Windows, Linux
    return defaultLocalhostUrl;
  }

  /// Normalizes a user-entered backend URL by trimming and ensuring scheme.
  static String sanitizeUrl(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return getDefaultBackendUrl();

    // Strip trailing slashes
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    // Ensure http:// or https:// prefix
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }

    return trimmed;
  }

  /// Analyzes an optical network exception and produces an actionable,
  /// human-readable diagnostic message explaining what went wrong and how to fix it.
  static String diagnoseConnectionError(Object error, String targetUrl) {
    final errStr = error.toString();
    final uri = Uri.tryParse(targetUrl);
    final host = uri?.host.toLowerCase() ?? '';
    final isAndroid = !kIsWeb && Platform.isAndroid;

    // Case 1: Localhost on Android (Connection Refused errno 111)
    if (isAndroid && (host == 'localhost' || host == '127.0.0.1')) {
      return 'Connection Refused: On Android, "localhost" refers to the device itself, '
          'not your development computer.\n\n'
          '• If using an Android Emulator: Switch backend URL to "$defaultEmulatorUrl".\n'
          '• If using a Physical Phone: Enter your computer\'s Wi-Fi LAN IP (e.g. http://192.168.x.x:8080) '
          'or run "adb reverse tcp:8080 tcp:8080" over USB.\n'
          '• Configure this anytime in Settings > Backend Configuration.';
    }

    // Case 2: Cleartext HTTP blocked by Android OS
    if (errStr.contains('Cleartext') || errStr.contains('CLEARTEXT_COMMUNICATION_NOT_PERMITTED')) {
      return 'Android Network Security Policy blocked cleartext HTTP traffic to $targetUrl.\n'
          'Ensure android:usesCleartextTraffic="true" is configured for local development, '
          'or use an HTTPS server.';
    }

    // Case 3: Connection refused on 10.0.2.2 or LAN IP
    if (errStr.contains('Connection refused') || errStr.contains('errno = 111') || errStr.contains('errno = 61')) {
      return 'Unable to connect to Zenith backend at $targetUrl (Connection Refused).\n\n'
          '1. Verify the Zenith server is running: "dart run bin/zenith_server.dart --port 8080"\n'
          '2. Ensure the server binds to all interfaces (0.0.0.0), not just 127.0.0.1.\n'
          '3. Check your firewall allows inbound connections on port 8080.';
    }

    // Case 4: Timeout
    if (errStr.contains('Timeout') || errStr.contains('timed out')) {
      return 'Request to $targetUrl timed out.\n'
          'Check that your computer and Android device are on the same Wi-Fi network, '
          'and that your router allows device-to-device communication.';
    }

    // Default error representation
    return 'Backend Connection Error ($targetUrl): $errStr';
  }
}
