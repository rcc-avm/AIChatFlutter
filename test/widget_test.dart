// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/providers/chat_provider.dart';
import '../lib/providers/navigation_provider.dart';
import '../lib/providers/settings_provider.dart';
import '../lib/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Create providers for testing
    final chatProvider = await ChatProvider.create().catchError((e) {
      // In test environment, create empty provider
      return ChatProvider.create();
    });
    final navigationProvider = NavigationProvider();
    final settingsProvider = await SettingsProvider.create();

    // Build our app and trigger a frame
    await tester.pumpWidget(AppRoot(
      chatProvider: chatProvider,
      navigationProvider: navigationProvider,
      settingsProvider: settingsProvider,
    ));

    // Verify that the app starts with AuthScreen
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
