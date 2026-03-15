import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_router.dart';
import 'package:prep_up/navigation/app_routes.dart';

void main() {
  runApp(const AiInterviewTrainerApp());
}

class AiInterviewTrainerApp extends StatelessWidget {
  const AiInterviewTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B5FEF);
    return MaterialApp(
      title: 'AI Interview Trainer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
