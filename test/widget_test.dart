import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astarai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AstarApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
