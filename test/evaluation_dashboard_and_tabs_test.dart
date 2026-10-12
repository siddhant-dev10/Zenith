import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/app_theme.dart';
import 'package:zenith/screens/home_screen.dart';
import 'package:zenith/screens/tabs/evaluation_dashboard_tab.dart';
import 'package:zenith/screens/tabs/system_config_tab.dart';

void main() {
  group('Zenith Evaluation Framework and Tab Restructuring Tests', () {
    testWidgets(
      'HomeScreen mounts 5 primary tabs with Test Lab as initial view',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        // 1. Verify App Header branding
        expect(find.text('Zenith'), findsOneWidget);
        expect(
          find.text('Privacy Testing & Evaluation Framework'),
          findsOneWidget,
        );

        // 2. Verify all 5 Navigation Destinations
        expect(find.text('Test Lab'), findsOneWidget);
        expect(find.text('Evaluation'), findsOneWidget);
        expect(find.text('Analyzer'), findsOneWidget);
        expect(find.text('Test Runs'), findsOneWidget);
        expect(find.text('Config'), findsOneWidget);

        // 3. Verify Test Lab content (default primary view)
        expect(find.text('ZENITH TEST LAB & BENCHMARK'), findsOneWidget);
        expect(find.text('Capture Photo'), findsWidgets);
        expect(find.text('Upload Photo'), findsWidgets);
        expect(find.text('TEST THREAT SCENARIOS'), findsWidgets);
        expect(find.textContaining('Execute Full Suite'), findsOneWidget);

        // 4. Test Navigation Bar switching to Evaluation Dashboard
        await tester.tap(find.text('Evaluation'));
        await tester.pump(const Duration(milliseconds: 500));

        // 5. Test Navigation Bar switching to Analyzer
        await tester.tap(find.text('Analyzer'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('IMAGE PRIVACY ANALYZER'), findsOneWidget);

        // 6. Test Navigation Bar switching to Test Runs
        await tester.tap(find.text('Test Runs'));
        await tester.pump(const Duration(milliseconds: 500));

        // 7. Test Navigation Bar switching to Config
        await tester.tap(find.text('Config'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('SYSTEM & ENGINE CONFIGURATION'), findsOneWidget);
        expect(
          find.text('CALIBRATED RISK MATRIX SPECIFICATION'),
          findsOneWidget,
        );
      },
    );

    testWidgets('EvaluationDashboardTab mounts cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: EvaluationDashboardTab()),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(EvaluationDashboardTab), findsOneWidget);
    });

    testWidgets('SystemConfigTab displays calibrated matrix formula', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: SystemConfigTab()),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('CALIBRATED RISK MATRIX SPECIFICATION'), findsOneWidget);
      expect(find.text('Ordinary Human Face'), findsOneWidget);
      expect(find.text('Score ≤ 15 (LOW)'), findsOneWidget);
      expect(find.text('Plaintext API Key / Secret'), findsOneWidget);
      expect(find.text('Score 76–100 (CRITICAL)'), findsOneWidget);
    });
  });
}
