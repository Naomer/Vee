// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vee/main.dart';
import 'package:provider/provider.dart';
import 'package:vee/core/theme/theme_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the app starts with the home screen
    expect(find.text('Vee'), findsOneWidget);

    // Verify that the navigation bar is present
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify that all navigation items are present
    expect(find.byIcon(PhosphorIcons.house(PhosphorIconsStyle.regular)),
        findsOneWidget);
    expect(find.byIcon(PhosphorIcons.compass(PhosphorIconsStyle.regular)),
        findsOneWidget);
    expect(find.byIcon(PhosphorIcons.brain(PhosphorIconsStyle.regular)),
        findsOneWidget);
    expect(find.byIcon(PhosphorIcons.planet(PhosphorIconsStyle.regular)),
        findsOneWidget);
    expect(find.byIcon(PhosphorIcons.gear(PhosphorIconsStyle.regular)),
        findsOneWidget);
  });
}
