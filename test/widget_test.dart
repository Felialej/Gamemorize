import 'package:flutter_test/flutter_test.dart';
import 'package:gamemorize/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const GamemorizeApp());
    expect(find.text('Gamemorize'), findsOneWidget);
  });
}
