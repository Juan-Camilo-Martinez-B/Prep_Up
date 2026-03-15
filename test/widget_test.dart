import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/main.dart';

void main() {
  testWidgets('Arranca en Splash', (WidgetTester tester) async {
    await tester.pumpWidget(const AiInterviewTrainerApp());

    expect(find.text('AI Interview Trainer'), findsOneWidget);
    expect(find.text('Splash Screen'), findsOneWidget);
    expect(find.text('Ir a Login'), findsOneWidget);
    expect(find.text('Ir a Registro'), findsOneWidget);
  });
}
