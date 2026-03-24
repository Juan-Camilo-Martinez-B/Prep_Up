class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';

  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const settings = '/settings';

  static const selectInterviewType = '/interview/select-type';
  static const selectJobRole = '/interview/select-job-role';
  static const interviewConfiguration = '/interview/configuration';
  static const deviceCheck = '/interview/device-check';
  static const simulatedCall = '/interview/simulated-call';

  static const interviewProcessing = '/analysis/processing';
  static const generalResults = '/analysis/general-results';
  static const detailedAnalysis = '/analysis/detailed-analysis';
  static const recommendations = '/analysis/recommendations';

  static const interviewHistory = '/tracking/interview-history';
  static const statistics = '/tracking/statistics';
  static const repeatInterview = '/tracking/repeat-interview';

  static const all = <String>[
    splash,
    login,
    register,
    forgotPassword,
    dashboard,
    profile,
    settings,
    selectInterviewType,
    selectJobRole,
    interviewConfiguration,
    deviceCheck,
    simulatedCall,
    interviewProcessing,
    generalResults,
    detailedAnalysis,
    recommendations,
    interviewHistory,
    statistics,
    repeatInterview,
  ];
}
