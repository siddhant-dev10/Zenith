import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized environment-specific API configuration and connectivity diagnostics.
class ApiConfig {
  /// Standard loopback address for desktop, macOS, Linux, and Windows development.
  static const String defaultLocalhostUrl = 'http://localhost:8080';

  /// Standard Android emulator loopback alias to host machine's 127.0.0.1.
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8080';

  /// Standard development Mac Wi-Fi LAN address for physical Android devices.
  static const String defaultLanUrl = 'http://192.168.0.16:8080';

  /// Default production / staging HTTPS backend template (if configured).
  static const String defaultProductionUrl = 'https://api.zenith.privacy';

  /// Compile-time environment override via `--dart-define=BACKEND_URL=https://...`
  static const String _compileTimeBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  /// Whether a compile-time backend URL override was provided.
  static bool get hasCompileTimeOverride => _compileTimeBackendUrl.trim().isNotEmpty;

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
    // On physical Android devices, 10.0.2.2 causes SocketException Connection Refused (errno = 111)
    // because 10.0.2.2 is reserved strictly for the QEMU emulator. The development Mac's Wi-Fi
    // LAN IP (defaultLanUrl) is reachable from both physical Android phones over Wi-Fi and emulators!
    if (Platform.isAndroid) {
      return defaultLanUrl;
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
          '• If using a Physical Phone on Wi-Fi: Switch backend URL to "$defaultLanUrl".\n'
          '• If using a Physical Phone on USB: Run "adb reverse tcp:8080 tcp:8080" over USB.\n'
          '• If using an Android Emulator: Switch backend URL to "$defaultEmulatorUrl".\n'
          '• Configure this anytime in Settings > Backend Configuration.';
    }

    // Case 1b: 10.0.2.2 on Physical Android Device (Connection Refused errno 111)
    if (isAndroid && host == '10.0.2.2') {
      return 'Connection Refused: "10.0.2.2" is only reachable inside the Android Emulator.\n\n'
          'Your physical phone cannot reach 10.0.2.2.\n'
          '• Physical Phone on Wi-Fi: Switch backend URL to your Mac\'s LAN IP ("$defaultLanUrl").\n'
          '• Physical Phone on USB: Run "adb reverse tcp:8080 tcp:8080" and use "http://localhost:8080".\n'
          '• Tap "Switch to Wi-Fi LAN" or configure in Settings.';
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
