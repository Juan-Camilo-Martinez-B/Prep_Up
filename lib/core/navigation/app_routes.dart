class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';

  static const login = '/auth/login';
  static const loginCallback = '/login-callback';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyOtp = '/auth/verify-otp';
  static const resetPassword = '/auth/reset-password';

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

  static const all = <String>[
    splash,
    login,
    loginCallback,
    register,
    forgotPassword,
    verifyOtp,
    resetPassword,
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
  ];
}
