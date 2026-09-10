import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';

void main() {
  testWidgets('GlassCard renders child with smooth zero blur', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Performance Test'),
          ),
        ),
      ),
    );
    expect(find.text('Performance Test'), findsOneWidget);
  });
}


