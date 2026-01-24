import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cash_records/forms/in.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '.';
  }
}

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    // Initialize Hive with a valid path
    final path = Directory.current.path;
    Hive.init(path);
  });

  testWidgets('InForm has accessible IconButton for date picker', (WidgetTester tester) async {
    // Build the widget.
    // We wrap InForm in a MaterialApp to provide Theme and Directionality.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return InForm(context, null);
        }),
      ),
    ));

    // Wait for FutureBuilder.
    await tester.pumpAndSettle();

    // Verify presence of IconButton with correct tooltip.
    final iconButtonFinder = find.byWidgetPredicate((widget) =>
      widget is IconButton && widget.tooltip == 'Show Calender'
    );
    expect(iconButtonFinder, findsOneWidget);
  });
}
