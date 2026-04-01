import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebro_patient_app/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CerebroApp()),
    );
    expect(find.text('Cerebro'), findsOneWidget);
  });
}
