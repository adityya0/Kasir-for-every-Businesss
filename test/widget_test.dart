import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_bersama/main.dart';

void main() {
  testWidgets('App smoke test - RootApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const RootApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(RootApp), findsOneWidget);
  });
}
