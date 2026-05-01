import 'package:flutter_test/flutter_test.dart';
import 'package:moninte/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MoninteApp());
    expect(find.text('Spendalt'), findsOneWidget);
  });
}
