import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
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

    final InterviewConfig? configArg;
    final InterviewSession? sessionArg;
    final InterviewResultsModel? resultsArg;

    if (arguments is InterviewConfig) {
      configArg = arguments;
      sessionArg = null;
      resultsArg = null;
    } else if (arguments is InterviewResultsModel) {
      configArg = null;
      sessionArg = null;
      resultsArg = arguments;
    } else if (arguments is Map) {
      final map = arguments.cast<String, Object?>();
      final rawConfig = map['config'];
      final rawSession = map['session'];
      final rawResults = map['results'];
      configArg = rawConfig is InterviewConfig ? rawConfig : null;
      sessionArg = rawSession is InterviewSession ? rawSession : null;
      resultsArg = rawResults is InterviewResultsModel ? rawResults : null;
    } else {
      configArg = null;
      sessionArg = null;
      resultsArg = null;
    }

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
        config: configArg,
        session: sessionArg,
      ),
      AppRoutes.generalResults => GeneralResultsScreen(
        results: resultsArg,
        session: sessionArg,
      ),
      AppRoutes.detailedAnalysis => DetailedAnalysisScreen(
        results: resultsArg,
        session: sessionArg,
      ),
      AppRoutes.recommendations => RecommendationsScreen(results: resultsArg),
      AppRoutes.interviewHistory => const InterviewHistoryScreen(),
      _ => const SplashScreen(),
    };
  }
}
