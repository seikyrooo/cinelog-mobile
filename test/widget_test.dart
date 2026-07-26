import 'package:flutter_test/flutter_test.dart';
import 'package:cinelog_mobile/main.dart';

void main() {
  testWidgets('Smoke test CinelogApp', (WidgetTester tester) async {
    await tester.pumpWidget(const CinelogApp());
    expect(find.byType(CinelogApp), findsOneWidget);
  });
}
