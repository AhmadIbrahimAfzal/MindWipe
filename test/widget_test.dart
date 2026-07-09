import 'package:flutter_test/flutter_test.dart';
import 'package:mindwipe/app.dart';

void main() {
  testWidgets('MindWipe app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MindWipeApp());
    // Verify the inbox header renders
    expect(find.text('Inbox'), findsOneWidget);
  });
}
