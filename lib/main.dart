import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_router.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/navigation/app_theme.dart';
import 'package:prep_up/models/app_settings_model.dart';

void main() {
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
