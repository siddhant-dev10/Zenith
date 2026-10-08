import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenith/core/theme/app_theme.dart';
import 'package:zenith/screens/home_screen.dart';
import 'package:zenith/screens/results_screen.dart';
import 'package:zenith/services/sample_data_service.dart';

void main() {
  testWidgets('HomeScreen renders OPSEC radar and primary actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Verify Title and Actions
    expect(find.text('Zenith'), findsOneWidget);
    expect(find.text('Capture Photo'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('TEST THREAT SCENARIOS'), findsOneWidget);
  });

  testWidgets('ResultsScreen displays risk meter and inferred insights',
      (WidgetTester tester) async {
    final report = SampleDataService.getScenarios().first.report;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ResultsScreen(report: report),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Verify Risk Score & Headers
    expect(find.text('88'), findsOneWidget);
    expect(find.text('EXPOSURE BREAKDOWN'), findsOneWidget);
    expect(find.text('SECURITY INTELLIGENCE & INFERENCES'), findsOneWidget);
    expect(find.text('DETECTED ELEMENTS & SENSITIVE DATA'), findsOneWidget);
    expect(find.text('MITIGATION & RECOMMENDATIONS'), findsOneWidget);
  });
}
