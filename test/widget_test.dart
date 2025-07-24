// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mirei/main.dart';

void main() {
  testWidgets('HomeScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MireiApp());

    // Verify that the main card's title is present.
    expect(find.text('Morning\nAwakening'), findsOneWidget);

    // Verify that the "Good Morning" chip is present.
    expect(find.text('GOOD MORNING'), findsOneWidget);

    // Verify that the relax mode section is present
    expect(find.text('Relax Mode'), findsWidgets);
  });
}
