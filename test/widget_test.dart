import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:do_hoang_danh/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(logged: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
