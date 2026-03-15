import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/screens/analysis/detailed_analysis_screen.dart';
import 'package:prep_up/screens/analysis/general_results_screen.dart';
import 'package:prep_up/screens/analysis/interview_processing_screen.dart';
import 'package:prep_up/screens/analysis/recommendations_screen.dart';
import 'package:prep_up/screens/auth/forgot_password_screen.dart';
import 'package:prep_up/screens/auth/login_screen.dart';
import 'package:prep_up/screens/auth/register_screen.dart';
import 'package:prep_up/screens/auth/splash_screen.dart';
import 'package:prep_up/screens/dashboard/dashboard_screen.dart';
import 'package:prep_up/screens/interview/device_check_screen.dart';
import 'package:prep_up/screens/interview/interview_configuration_screen.dart';
import 'package:prep_up/screens/interview/select_interview_type_screen.dart';
import 'package:prep_up/screens/interview/select_job_role_screen.dart';
import 'package:prep_up/screens/interview/simulated_call_screen.dart';
import 'package:prep_up/screens/profile/user_profile_screen.dart';
import 'package:prep_up/screens/settings/settings_screen.dart';
import 'package:prep_up/screens/tracking/interview_history_screen.dart';
import 'package:prep_up/screens/tracking/repeat_interview_screen.dart';
import 'package:prep_up/screens/tracking/statistics_screen.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final page = _pageFor(name);

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => page,
    );
  }

  static Widget _pageFor(String routeName) {
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
      AppRoutes.interviewProcessing => const InterviewProcessingScreen(),
      AppRoutes.generalResults => const GeneralResultsScreen(),
      AppRoutes.detailedAnalysis => const DetailedAnalysisScreen(),
      AppRoutes.recommendations => const RecommendationsScreen(),
      AppRoutes.interviewHistory => const InterviewHistoryScreen(),
      AppRoutes.statistics => const StatisticsScreen(),
      AppRoutes.repeatInterview => const RepeatInterviewScreen(),
      _ => _UnknownRouteScreen(routeName: routeName),
    };
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Ruta no encontrada',
      body: Center(child: Text(routeName.isEmpty ? 'Sin nombre' : routeName)),
    );
  }
}
