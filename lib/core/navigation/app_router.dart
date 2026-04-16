import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/presentation/screens/analysis/detailed_analysis_screen.dart';
import 'package:prep_up/presentation/screens/analysis/general_results_screen.dart';
import 'package:prep_up/presentation/screens/analysis/interview_processing_screen.dart';
import 'package:prep_up/presentation/screens/analysis/recommendations_screen.dart';
import 'package:prep_up/presentation/screens/auth/forgot_password_screen.dart';
import 'package:prep_up/presentation/screens/auth/login_screen.dart';
import 'package:prep_up/presentation/screens/auth/register_screen.dart';
import 'package:prep_up/presentation/screens/auth/splash_screen.dart';
import 'package:prep_up/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:prep_up/presentation/screens/interview/device_check_screen.dart';
import 'package:prep_up/presentation/screens/interview/interview_configuration_screen.dart';
import 'package:prep_up/presentation/screens/interview/select_interview_type_screen.dart';
import 'package:prep_up/presentation/screens/interview/select_job_role_screen.dart';
import 'package:prep_up/presentation/screens/interview/simulated_call_screen.dart';
import 'package:prep_up/presentation/screens/profile/user_profile_screen.dart';
import 'package:prep_up/presentation/screens/settings/settings_screen.dart';
import 'package:prep_up/presentation/screens/tracking/interview_history_screen.dart';
import 'package:prep_up/presentation/screens/tracking/repeat_interview_screen.dart';
import 'package:prep_up/presentation/screens/tracking/statistics_screen.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';

    // Manejar el callback de Supabase (Deep Linking)
    if (name.contains('login-callback')) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.login),
        builder: (context) => const LoginScreen(isVerified: true),
      );
    }

    final page = _pageFor(settings);

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => page,
    );
  }

  static Widget _pageFor(RouteSettings settings) {
    final routeName = settings.name ?? '';
    final arguments = settings.arguments;

    return switch (routeName) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.dashboard => const DashboardScreen(),
      AppRoutes.profile => const UserProfileScreen(),
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.selectInterviewType => const SelectInterviewTypeScreen(),
      AppRoutes.selectJobRole => const SelectJobRoleScreen(),
      AppRoutes.interviewConfiguration => const InterviewConfigurationScreen(),
      AppRoutes.deviceCheck => const DeviceCheckScreen(),
      AppRoutes.simulatedCall => const SimulatedCallScreen(),
      AppRoutes.interviewProcessing => InterviewProcessingScreen(
          config: arguments is InterviewConfig ? arguments : null,
        ),
      AppRoutes.generalResults => const GeneralResultsScreen(),
      AppRoutes.detailedAnalysis => const DetailedAnalysisScreen(),
      AppRoutes.recommendations => const RecommendationsScreen(),
      AppRoutes.interviewHistory => const InterviewHistoryScreen(),
      AppRoutes.statistics => const StatisticsScreen(),
      AppRoutes.repeatInterview => const RepeatInterviewScreen(),
      _ => const SplashScreen(),
    };
  }
}

