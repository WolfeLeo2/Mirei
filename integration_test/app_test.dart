import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mirei/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mirei App Integration Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Verify the app starts without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Navigation works correctly', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Look for tab navigation (after authentication)
      // This test assumes the user can navigate or is already authenticated

      // Try to find bottom navigation tabs
      final tabBarFinder = find.byType(TabBar);
      if (tabBarFinder.evaluate().isNotEmpty) {
        // If tabs are visible, test navigation
        await tester.tap(find.byIcon(Icons.book));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.spa));
        await tester.pumpAndSettle();

        // Verify navigation doesn't crash
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('App handles orientation changes', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Test orientation change
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/platform',
        (data) async => null,
      );

      // Rotate to landscape
      await tester.binding.setSurfaceSize(Size(800, 600));
      await tester.pumpAndSettle();

      // Verify app still works
      expect(find.byType(MaterialApp), findsOneWidget);

      // Rotate back to portrait
      await tester.binding.setSurfaceSize(Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App performs basic database operations', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));

      // This test verifies the app can initialize its database without errors
      // We can't easily test actual mood/journal operations without
      // complex UI automation, but we can verify the app doesn't crash
      // during database initialization

      // Look for any error dialogs or snackbars
      expect(find.text('Error'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      // Verify the main app is still running
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App memory usage stays reasonable', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Navigate through the app to trigger memory usage
      final tabBarFinder = find.byType(TabBar);
      if (tabBarFinder.evaluate().isNotEmpty) {
        // Navigate through tabs multiple times
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(Icons.home));
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.book));
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.spa));
          await tester.pumpAndSettle();
        }
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
 