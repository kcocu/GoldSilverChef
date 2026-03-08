import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/main.dart';

void main() {
  testWidgets('App starts with loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GoldSilverChefApp());
    expect(find.text('10,000가지 레시피 로딩중...'), findsOneWidget);
  });
}
