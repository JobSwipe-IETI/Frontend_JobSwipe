import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:jobswipe/screens/login_screen.dart';

void main() {
  testWidgets('Shows Google login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          isLoading: false,
          errorMessage: null,
          onGoogleLogin: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
