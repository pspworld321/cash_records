import 'package:flutter_test/flutter_test.dart';
import 'package:cash_records/main.dart';
import 'package:cash_records/global.dart';

class FakeBox {
  get(key) => null;
  put(key, value) async {}
  values() => [];
}

void main() {
  setUp(() {
    Global.settingsBox = FakeBox();
    Global.brandInfoBox = FakeBox();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Check if it builds without exploding
    expect(find.byType(MyApp), findsOneWidget);
  });
}
