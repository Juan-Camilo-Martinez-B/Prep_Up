import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/main.dart';

void main() {
  testWidgets('Arranca en Splash', (WidgetTester tester) async {
    await tester.pumpWidget(const AiInterviewTrainerApp());

    expect(find.text('AI Interview Trainer'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
