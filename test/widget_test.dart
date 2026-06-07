import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('GitAnalyzer'))));
    expect(find.text('GitAnalyzer'), findsOneWidget);
  });
}
