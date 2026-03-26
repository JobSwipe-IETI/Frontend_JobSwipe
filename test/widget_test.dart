import 'package:flutter_test/flutter_test.dart';

import 'package:jobswipe/main.dart';

void main() {
  testWidgets('Shows Google login button', (WidgetTester tester) async {
    await tester.pumpWidget(const JobSwipeApp());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión con Google'), findsOneWidget);
  });
}
