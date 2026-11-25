import 'package:flutter_test/flutter_test.dart';

import 'package:wassel/app/wassel_app.dart';

void main() {
  testWidgets('shows the Arabic app shell', (tester) async {
    await tester.pumpWidget(const WasselApp());

    expect(find.text('وصّل – وين طلبي؟'), findsOneWidget);
  });
}
