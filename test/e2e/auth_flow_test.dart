import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/features/auth/infrastructure/auth_preferences.dart';
import 'package:prep_up/main.dart';
import 'package:prep_up/shared/presentation/widgets/app_primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/memory_database.dart';
import '../support/scripted_auth_gateway.dart';

/// Recorrido de las pantallas reales de arranque. No abre Supabase ni Groq.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAuthGateway auth;

  setUp(() {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    auth = ScriptedAuthGateway(
      signInError: const AuthException('Invalid login credentials'),
    );
  });

  testWidgets(
    'de la portada al login, el registro y un error de credenciales',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final database = MemoryDatabase();
      await tester.pumpWidget(
        AiInterviewTrainerApp(
          databaseService: database,
          authService: auth,
          sessionPreferences: AuthPreferences(),
          settingsStore: database,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('El Futuro de las'), findsOneWidget);

      await tester.tap(find.text('Crear una Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Únete a la plataforma'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(AppPrimaryButton, 'Iniciar Sesión').last,
      );
      await tester.pump();
      expect(find.text('Por favor completa todos los campos'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'ana@correo.com');
      await tester.enterText(fields.at(1), 'secreto');
      await tester.tap(
        find.widgetWithText(AppPrimaryButton, 'Iniciar Sesión').last,
      );
      await tester.pump();
      await tester.pump();
      expect(auth.signInCalls, 1);
      expect(auth.lastEmail, 'ana@correo.com');
      await tester.pump();

      await tester.tap(find.text('Regístrate aquí'));
      await tester.pumpAndSettle();
      expect(find.text('Únete a la plataforma'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(find.text('Reinicia tu acceso'), findsOneWidget);
    },
  );
}
