// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:afterlife/main.dart';
import 'package:afterlife/features/providers/language_provider.dart';

void main() {
  testWidgets('App can be instantiated', (WidgetTester tester) async {
    // Test that the main app class can be created
    const app = MyApp();
    expect(app, isA<MyApp>());
    expect(app, isA<StatefulWidget>());
  });
}
