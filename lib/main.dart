import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_router.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/features/auth/domain/auth_gateway.dart';
import 'package:prep_up/features/auth/domain/session_preferences.dart';
import 'package:prep_up/features/auth/infrastructure/auth_preferences.dart';
import 'package:prep_up/features/auth/infrastructure/auth_service.dart';
import 'package:prep_up/features/interview/domain/interview_ai_port.dart';
import 'package:prep_up/features/interview/infrastructure/groq_service.dart';
import 'package:prep_up/features/interview/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/features/interview/presentation/controllers/media_device_controller.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:prep_up/shared/domain/entities/app_settings_model.dart';
import 'package:prep_up/shared/domain/ports/relational_database_service.dart';
import 'package:prep_up/shared/infrastructure/cached_database_service.dart';
import 'package:prep_up/shared/infrastructure/sqflite_database_service.dart';
import 'package:prep_up/shared/infrastructure/supabase_database_service.dart';
import 'package:prep_up/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  final sessionPreferences = AuthPreferences();
  final remember = await sessionPreferences.getRememberSession();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: remember
        ? const FlutterAuthClientOptions()
        : const FlutterAuthClientOptions(localStorage: EmptyLocalStorage()),
  );

  // Inicializar Servicios de Base de Datos
  final remoteDb = SupabaseDatabaseService();
  final localDb = SqfliteDatabaseService();
  final cachedDb = CachedDatabaseService(remote: remoteDb, local: localDb);
  await cachedDb.initialize();
  final authService = AuthService(database: remoteDb);

  runApp(
    AiInterviewTrainerApp(
      databaseService: cachedDb,
      authService: authService,
      sessionPreferences: sessionPreferences,
      settingsStore: remoteDb,
    ),
  );
}

class AiInterviewTrainerApp extends StatefulWidget {
  final RelationalDatabaseService databaseService;
  final AuthGateway authService;
  final SessionPreferences sessionPreferences;
  final RelationalDatabaseService settingsStore;

  const AiInterviewTrainerApp({
    super.key,
    required this.databaseService,
    required this.authService,
    required this.sessionPreferences,
    required this.settingsStore,
  });

  @override
  State<AiInterviewTrainerApp> createState() => _AiInterviewTrainerAppState();
}

class _AiInterviewTrainerAppState extends State<AiInterviewTrainerApp> {
  late final AppThemeController _themeController;
  final AppLocaleController _localeController = AppLocaleController();

  @override
  void initState() {
    super.initState();
    _themeController = AppThemeController(
      database: widget.settingsStore,
      auth: widget.authService,
    );
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    await Future.wait([_themeController.load(), _localeController.load()]);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(
      0xFF4ADE80,
    ); // Brighter Mint Green works better for glow in dark
    const darkBackground = Color(0xFF0B0E14); // Deep charcoal
    const darkSurface = Color(0xFF12161B);
    const lightBackground = Color(0xFFF3F5F7);
    const lightSurface = Color(0xFFFFFFFF);

    return MultiProvider(
      providers: [
        Provider<AuthGateway>.value(value: widget.authService),
        Provider<SessionPreferences>.value(value: widget.sessionPreferences),
        Provider<RelationalDatabaseService>.value(
          value: widget.databaseService,
        ),
        Provider<InterviewAiPort>(create: (_) => GroqService()),
        ChangeNotifierProvider(create: (_) => InterviewConfigController()),
        ChangeNotifierProvider(create: (_) => MediaDeviceController()),
      ],
      child: AppThemeScope(
        controller: _themeController,
        child: AppLocaleScope(
          controller: _localeController,
          child: AnimatedBuilder(
            animation: Listenable.merge([_themeController, _localeController]),
            builder: (context, _) {
              final themeMode = switch (_themeController.themeMode) {
                AppThemeMode.system => ThemeMode.system,
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
              };

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) => context.l10n.appTitle,
                locale: _localeController.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: supportedAppLocales,
                themeMode: themeMode,
                theme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: lightBackground,
                  cardColor: lightSurface,
                  colorScheme:
                      ColorScheme.fromSeed(
                        seedColor: seed,
                        brightness: Brightness.light,
                        surface: lightSurface,
                      ).copyWith(
                        surfaceContainerHighest: const Color(
                          0xFFE2E8F0,
                        ), // for outlines/borders
                      ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                  ),
                  fontFamily:
                      'Inter', // Defaulting assuming it looks clean even if fallbacked
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: darkBackground,
                  cardColor: darkSurface,
                  colorScheme:
                      ColorScheme.fromSeed(
                        seedColor: seed,
                        brightness: Brightness.dark,
                        surface: darkSurface,
                      ).copyWith(
                        surfaceContainerHighest: const Color(
                          0xFF1E242C,
                        ), // for outlines/borders
                        onSurfaceVariant: const Color(0xFFA0ABBA),
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
      ),
    );
  }
}
