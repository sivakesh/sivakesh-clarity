import 'package:flutter_test/flutter_test.dart';
import 'package:sivakesh_app/main.dart';

void main() {
  testWidgets('App renders main navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CounselingApp());

    expect(find.text('Clarity begins here'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
