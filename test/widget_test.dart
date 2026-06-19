import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civicpulse_app/features/auth/screens/login_screen.dart';
import 'package:civicpulse_app/main.dart';

void main() {
  testWidgets('shows women ID login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CivicPulseApp());

    expect(find.text('GBV Safe Hub'), findsOneWidget);
    expect(find.text('SA ID Number'), findsOneWidget);
    expect(find.text('Find My Profile'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('blocks non-female SA ID sequence', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CivicPulseApp());

    await tester.enterText(find.byType(TextFormField).at(0), '8001015009087');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Access Restricted'), findsOneWidget);
  });

  testWidgets('fills dummy profile for feature testing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CivicPulseApp());

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use test profile'));
    await tester.pump();

    expect(find.text(LoginScreen.testFullName), findsOneWidget);
    expect(find.text(LoginScreen.testSouthAfricanFemaleId), findsOneWidget);
    expect(find.text(LoginScreen.testPhoneNumber), findsOneWidget);
  });

  test('validates SA ID gender sequence', () {
    expect(LoginScreen.isSouthAfricanFemaleId('8001015009087'), isFalse);
    expect(
      LoginScreen.isSouthAfricanFemaleId(LoginScreen.testSouthAfricanFemaleId),
      isTrue,
    );
  });
}
