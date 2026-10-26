import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkme_mobile/main.dart';

void main() {
  testWidgets('ParkMe App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkMeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
