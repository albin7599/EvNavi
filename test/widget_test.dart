import 'package:flutter_test/flutter_test.dart';
import 'package:ev_navi/main.dart';

void main() {
  testWidgets('EvNavi smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EvNaviApp());
    expect(find.byType(EvNaviApp), findsOneWidget);
  });
}
