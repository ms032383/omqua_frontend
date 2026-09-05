import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_ai_frontend/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroAIDashboardApp());

    // Verify that the title / theme loaded (for example, finding the text "SYNTHESIS ENGINE" or "NEURO AI")
    expect(find.text('NEURO AI'), findsOneWidget);
  });
}
