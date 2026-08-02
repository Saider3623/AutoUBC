import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/main.dart';

void main() {
  testWidgets('renders the AutoUBC application shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
