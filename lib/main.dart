import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:prep_up/core/navigation/app_router.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/services/auth_preferences.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/controllers/media_device_controller.dart';
import 'package:prep_up/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  final remember = await AuthPreferences.getRememberSession();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: remember
        ? const FlutterAuthClientOptions()
        : const FlutterAuthClientOptions(
            localStorage: EmptyLocalStorage(),
          ),
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
    const seed = Color(0xFF4ADE80); // Brighter Mint Green works better for glow in dark
    const darkBackground = Color(0xFF0B0E14); // Deep charcoal
    const darkSurface = Color(0xFF12161B);
    const lightBackground = Color(0xFFF3F5F7);
    const lightSurface = Color(0xFFFFFFFF);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InterviewConfigController()),
        ChangeNotifierProvider(create: (_) => MediaDeviceController()),
      ],
      child: AppThemeScope(
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
                scaffoldBackgroundColor: lightBackground,
                cardColor: lightSurface,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: seed,
                  brightness: Brightness.light,
                  surface: lightSurface,
                ).copyWith(
                    surfaceContainerHighest: const Color(0xFFE2E8F0), // for outlines/borders
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                ),
                fontFamily: 'Inter', // Defaulting assuming it looks clean even if fallbacked
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: darkBackground,
                cardColor: darkSurface,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: seed,
                  brightness: Brightness.dark,
                  surface: darkSurface,
                ).copyWith(
                    surfaceContainerHighest: const Color(0xFF1E242C), // for outlines/borders
                    onSurfaceVariant: const Color(0xFFA0ABBA)
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                ),
                fontFamily: 'Inter',
              ),
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        ),
      ),
    );
  }
}
