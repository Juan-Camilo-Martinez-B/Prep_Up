import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'anon',
    );
  });

  testWidgets('Arranca en Splash', (WidgetTester tester) async {
    await tester.pumpWidget(const AiInterviewTrainerApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('AI Interview Trainer'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
