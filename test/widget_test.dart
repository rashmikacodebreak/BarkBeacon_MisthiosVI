import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bark_beacon/main.dart';

void main() {
  testWidgets('BarkBeacon opens successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const BarkBeaconApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}