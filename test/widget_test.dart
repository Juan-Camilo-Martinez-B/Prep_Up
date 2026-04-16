import 'dart:ui';

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
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const AiInterviewTrainerApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('El Futuro de las\nEntrevistas IA'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Crear una Cuenta'), findsOneWidget);
  });
}
