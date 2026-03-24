import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/core/navigation/app_router.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/theme/app_theme.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const AiInterviewTrainerApp());
}

class AiInterviewTrainerApp extends StatefulWidget {
  const AiInterviewTrainerApp({super.key});

  @override
  State<AiInterviewTrainerApp> createState() => _AiInterviewTrainerAppState();
}

class _AiInterviewTrainerAppState extends State<AiInterviewTrainerApp> {
  final AppThemeController _themeController = AppThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B5FEF);

    return AppThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          final themeMode = switch (_themeController.themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          };

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AI Interview Trainer',
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
            ),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
