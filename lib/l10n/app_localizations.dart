import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Interview Trainer'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageOptionSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español / Spanish'**
  String get languageOptionSpanish;

  /// No description provided for @languageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English / Inglés'**
  String get languageOptionEnglish;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @freeAccount.
  ///
  /// In en, this message translates to:
  /// **'Free Account'**
  String get freeAccount;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @visualTheme.
  ///
  /// In en, this message translates to:
  /// **'Visual Theme'**
  String get visualTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// No description provided for @hapticSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibration on interaction'**
  String get hapticSubtitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders and alerts'**
  String get pushNotificationsSubtitle;

  /// No description provided for @privacyAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Analytics'**
  String get privacyAndAnalytics;

  /// No description provided for @myRecordingsBeta.
  ///
  /// In en, this message translates to:
  /// **'My recordings (Beta)'**
  String get myRecordingsBeta;

  /// No description provided for @expertFacialAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Expert Facial Analysis'**
  String get expertFacialAnalysis;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @accountAndSession.
  ///
  /// In en, this message translates to:
  /// **'Account and Session'**
  String get accountAndSession;

  /// No description provided for @myProfileButton.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfileButton;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @splashHeadline.
  ///
  /// In en, this message translates to:
  /// **'The Future of\nAI Interviews'**
  String get splashHeadline;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart preparation that elevates your career to the next level.'**
  String get splashSubtitle;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get createAccountButton;

  /// No description provided for @secureBySupabase.
  ///
  /// In en, this message translates to:
  /// **'Secure operation by Supabase'**
  String get secureBySupabase;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @authFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get authFillAllFields;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authInvalidEmail;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Login error'**
  String get loginErrorGeneric;

  /// No description provided for @loginErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your account has not been confirmed yet. Please check your inbox.'**
  String get loginErrorEmailNotConfirmed;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect credentials. Please try again.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @forgotPasswordErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the recovery link. Please check the email and try again.'**
  String get forgotPasswordErrorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection took too long. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable right now. Please try again later.'**
  String get errorServerUnavailable;

  /// No description provided for @errorCouldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the information. Please try again.'**
  String get errorCouldNotLoadData;

  /// No description provided for @errorCouldNotSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save the changes. Please try again.'**
  String get errorCouldNotSaveChanges;

  /// No description provided for @deviceErrorNoCameraDetected.
  ///
  /// In en, this message translates to:
  /// **'No camera was detected on this device.'**
  String get deviceErrorNoCameraDetected;

  /// No description provided for @deviceErrorCameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t enable the camera. Check permissions and try again.'**
  String get deviceErrorCameraInitFailed;

  /// No description provided for @deviceErrorMicrophoneInitFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t enable the microphone. Check permissions and try again.'**
  String get deviceErrorMicrophoneInitFailed;

  /// No description provided for @deviceErrorVideoStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t start the camera stream. Please try again.'**
  String get deviceErrorVideoStreamFailed;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get ready for your next big professional challenge.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @rememberSession.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get rememberSession;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordLink;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginRegisterHere.
  ///
  /// In en, this message translates to:
  /// **'Sign up here'**
  String get loginRegisterHere;

  /// No description provided for @loginEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully! You can now sign in.'**
  String get loginEmailVerified;

  /// No description provided for @forgotPasswordEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get forgotPasswordEnterEmail;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Recovery link sent'**
  String get forgotPasswordSent;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your access'**
  String get forgotPasswordCardTitle;

  /// No description provided for @forgotPasswordCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a link'**
  String get forgotPasswordCardSubtitle;

  /// No description provided for @forgotPasswordSentShort.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get forgotPasswordSentShort;

  /// No description provided for @forgotPasswordSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get forgotPasswordSendLink;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @registerInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email with a valid domain (e.g. user@domain.com)'**
  String get registerInvalidEmail;

  /// No description provided for @registerPhoneLengthError.
  ///
  /// In en, this message translates to:
  /// **'Phone number must contain 10 digits'**
  String get registerPhoneLengthError;

  /// No description provided for @registerWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters and include uppercase, lowercase, number, and special character.'**
  String get registerWeakPassword;

  /// No description provided for @registerEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get registerEmailAlreadyExists;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. A confirmation email has been sent. Please verify it before signing in.'**
  String get registerSuccess;

  /// No description provided for @registerError.
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registerError;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the platform'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your professional profile and start training.'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @occupationLabel.
  ///
  /// In en, this message translates to:
  /// **'Occupation / Role'**
  String get occupationLabel;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerButton;

  /// No description provided for @registerAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member?'**
  String get registerAlreadyMember;

  /// No description provided for @interviewTypeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get interviewTypeTechnical;

  /// No description provided for @interviewTypeBehavioral.
  ///
  /// In en, this message translates to:
  /// **'Behavioral'**
  String get interviewTypeBehavioral;

  /// No description provided for @interviewTypeMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get interviewTypeMixed;

  /// No description provided for @interviewTypeTechnicalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Problems, concepts, and debugging'**
  String get interviewTypeTechnicalSubtitle;

  /// No description provided for @interviewTypeBehavioralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soft skills, stories, and leadership'**
  String get interviewTypeBehavioralSubtitle;

  /// No description provided for @interviewTypeMixedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The right balance of both'**
  String get interviewTypeMixedSubtitle;

  /// No description provided for @interviewModeSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get interviewModeSimulated;

  /// No description provided for @interviewModeRealtime.
  ///
  /// In en, this message translates to:
  /// **'Real-time'**
  String get interviewModeRealtime;

  /// No description provided for @jobRoleFrontendDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Frontend Developer'**
  String get jobRoleFrontendDeveloper;

  /// No description provided for @jobRoleBackendDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Backend Developer'**
  String get jobRoleBackendDeveloper;

  /// No description provided for @jobRoleMobileDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Mobile Developer'**
  String get jobRoleMobileDeveloper;

  /// No description provided for @jobRoleUiUxDesigner.
  ///
  /// In en, this message translates to:
  /// **'UI/UX Designer'**
  String get jobRoleUiUxDesigner;

  /// No description provided for @jobRoleDataAnalyst.
  ///
  /// In en, this message translates to:
  /// **'Data Analyst'**
  String get jobRoleDataAnalyst;

  /// No description provided for @jobRoleDataScientist.
  ///
  /// In en, this message translates to:
  /// **'Data Scientist'**
  String get jobRoleDataScientist;

  /// No description provided for @jobRoleQaTester.
  ///
  /// In en, this message translates to:
  /// **'QA Tester'**
  String get jobRoleQaTester;

  /// No description provided for @jobRoleDevOps.
  ///
  /// In en, this message translates to:
  /// **'DevOps'**
  String get jobRoleDevOps;

  /// No description provided for @jobRoleProductManager.
  ///
  /// In en, this message translates to:
  /// **'Product Manager'**
  String get jobRoleProductManager;

  /// No description provided for @interviewMissingFieldType.
  ///
  /// In en, this message translates to:
  /// **'interview type'**
  String get interviewMissingFieldType;

  /// No description provided for @interviewMissingFieldJobRole.
  ///
  /// In en, this message translates to:
  /// **'job role'**
  String get interviewMissingFieldJobRole;

  /// No description provided for @interviewMissingFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'duration'**
  String get interviewMissingFieldDuration;

  /// No description provided for @interviewMissingFieldMode.
  ///
  /// In en, this message translates to:
  /// **'mode'**
  String get interviewMissingFieldMode;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @interviewConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure interview'**
  String get interviewConfigTitle;

  /// No description provided for @interviewQuickSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick settings'**
  String get interviewQuickSettingsTitle;

  /// No description provided for @interviewQuickSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your interview duration'**
  String get interviewQuickSettingsSubtitle;

  /// No description provided for @interviewModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get interviewModeLabel;

  /// No description provided for @interviewPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get interviewPreviewTitle;

  /// No description provided for @interviewPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you are about to train'**
  String get interviewPreviewSubtitle;

  /// No description provided for @interviewPreviewType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get interviewPreviewType;

  /// No description provided for @interviewPreviewTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get interviewPreviewTime;

  /// No description provided for @interviewPreviewJobRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get interviewPreviewJobRole;

  /// No description provided for @interviewPreviewMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get interviewPreviewMode;

  /// No description provided for @interviewTimeLimitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Time limit: {minutes} {unit}'**
  String interviewTimeLimitMinutes(int minutes, String unit);

  /// No description provided for @interviewCompleteMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Complete these fields: {fields}'**
  String interviewCompleteMissingFields(String fields);

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @interviewSelectTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview type'**
  String get interviewSelectTypeTitle;

  /// No description provided for @interviewSelectTypeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose your\ntraining mode'**
  String get interviewSelectTypeHeadline;

  /// No description provided for @interviewSelectTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the simulation based on the focus\nof your next hiring process.'**
  String get interviewSelectTypeSubtitle;

  /// No description provided for @interviewSelectTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select an interview type.'**
  String get interviewSelectTypeError;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @selectJobRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Role / area'**
  String get selectJobRoleTitle;

  /// No description provided for @selectJobRoleHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get selectJobRoleHeadline;

  /// No description provided for @selectJobRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the role to focus your interview questions.'**
  String get selectJobRoleSubtitle;

  /// No description provided for @selectJobRoleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Backend Developer...'**
  String get selectJobRoleSearchHint;

  /// No description provided for @selectJobRoleSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested roles'**
  String get selectJobRoleSuggested;

  /// No description provided for @selectJobRoleNoResults.
  ///
  /// In en, this message translates to:
  /// **'No roles found for that search.'**
  String get selectJobRoleNoResults;

  /// No description provided for @selectJobRoleError.
  ///
  /// In en, this message translates to:
  /// **'Please select a role.'**
  String get selectJobRoleError;

  /// No description provided for @processingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get processingTitle;

  /// No description provided for @processingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your interview with AI...'**
  String get processingHeadline;

  /// No description provided for @processingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generating AI results from your answers.'**
  String get processingSubtitle;

  /// No description provided for @processingAnswersCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured answers: {count}'**
  String processingAnswersCaptured(int count);

  /// No description provided for @processingWorking.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingWorking;

  /// No description provided for @processingNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to generate results.'**
  String get processingNotEnoughData;

  /// No description provided for @processingInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The AI returned an invalid response while generating results.'**
  String get processingInvalidResponse;

  /// No description provided for @processingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not generate results'**
  String get processingErrorTitle;

  /// No description provided for @processingViewResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get processingViewResults;

  /// No description provided for @processingBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get processingBackToDashboard;

  /// No description provided for @processingSummaryReady.
  ///
  /// In en, this message translates to:
  /// **'Summary ready'**
  String get processingSummaryReady;

  /// No description provided for @processingOutcomeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String processingOutcomeStatus(String status);

  /// No description provided for @outcomeApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get outcomeApproved;

  /// No description provided for @outcomeImprove.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get outcomeImprove;

  /// No description provided for @processingConfigReceived.
  ///
  /// In en, this message translates to:
  /// **'Received configuration'**
  String get processingConfigReceived;

  /// No description provided for @processingConfigType.
  ///
  /// In en, this message translates to:
  /// **'Type: {value}'**
  String processingConfigType(String value);

  /// No description provided for @processingConfigJobRole.
  ///
  /// In en, this message translates to:
  /// **'Role: {value}'**
  String processingConfigJobRole(String value);

  /// No description provided for @processingConfigDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {value}'**
  String processingConfigDuration(String value);

  /// No description provided for @processingConfigMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {value}'**
  String processingConfigMode(String value);

  /// No description provided for @callExitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel interview?'**
  String get callExitConfirmTitle;

  /// No description provided for @callExitConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'If you leave now, you will lose the progress of this session. Are you sure?'**
  String get callExitConfirmMessage;

  /// No description provided for @callExitConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get callExitConfirmAction;

  /// No description provided for @deviceCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get deviceCheckTitle;

  /// No description provided for @deviceCheckChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment checklist'**
  String get deviceCheckChecklistTitle;

  /// No description provided for @deviceCheckChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone'**
  String get deviceCheckChecklistSubtitle;

  /// No description provided for @deviceCheckCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get deviceCheckCamera;

  /// No description provided for @deviceCheckMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get deviceCheckMicrophone;

  /// No description provided for @deviceCheckPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get deviceCheckPreviewTitle;

  /// No description provided for @deviceCheckCameraActive.
  ///
  /// In en, this message translates to:
  /// **'Camera active'**
  String get deviceCheckCameraActive;

  /// No description provided for @deviceCheckCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get deviceCheckCameraUnavailable;

  /// No description provided for @deviceCheckStartSimulation.
  ///
  /// In en, this message translates to:
  /// **'Start simulation'**
  String get deviceCheckStartSimulation;

  /// No description provided for @deviceCheckStartInterview.
  ///
  /// In en, this message translates to:
  /// **'Start interview'**
  String get deviceCheckStartInterview;

  /// No description provided for @deviceStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deviceStatusActive;

  /// No description provided for @deviceStatusEnabling.
  ///
  /// In en, this message translates to:
  /// **'Enabling...'**
  String get deviceStatusEnabling;

  /// No description provided for @deviceStatusPermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Permission blocked'**
  String get deviceStatusPermissionBlocked;

  /// No description provided for @deviceStatusPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get deviceStatusPermissionDenied;

  /// No description provided for @deviceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get deviceStatusUnavailable;

  /// No description provided for @deviceStatusOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get deviceStatusOpenSettings;

  /// No description provided for @deviceStatusAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get deviceStatusAllow;

  /// No description provided for @simulatedCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get simulatedCallTitle;

  /// No description provided for @simulatedCallLiveHeadline.
  ///
  /// In en, this message translates to:
  /// **'Live interview'**
  String get simulatedCallLiveHeadline;

  /// No description provided for @callStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Call status'**
  String get callStatusTitle;

  /// No description provided for @callStatusObjective.
  ///
  /// In en, this message translates to:
  /// **'Goal: {questions} questions in {minutes} min'**
  String callStatusObjective(int questions, int minutes);

  /// No description provided for @callStateAiSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AI speaking'**
  String get callStateAiSpeaking;

  /// No description provided for @callStateAiWaiting.
  ///
  /// In en, this message translates to:
  /// **'AI waiting'**
  String get callStateAiWaiting;

  /// No description provided for @callStateUserAnswering.
  ///
  /// In en, this message translates to:
  /// **'User answering'**
  String get callStateUserAnswering;

  /// No description provided for @callStateMicWaiting.
  ///
  /// In en, this message translates to:
  /// **'Microphone waiting'**
  String get callStateMicWaiting;

  /// No description provided for @callStateProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get callStateProcessing;

  /// No description provided for @callStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get callStateReady;

  /// No description provided for @callStateQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String callStateQuestionProgress(int current, int total);

  /// No description provided for @callQuestionCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String callQuestionCardTitle(int current, int total);

  /// No description provided for @callQuestionSubtitleSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AI is reading it out loud'**
  String get callQuestionSubtitleSpeaking;

  /// No description provided for @callQuestionSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'AI interviewer'**
  String get callQuestionSubtitleDefault;

  /// No description provided for @callQuestionProgressText.
  ///
  /// In en, this message translates to:
  /// **'You\'re on question {current} of {total}.'**
  String callQuestionProgressText(int current, int total);

  /// No description provided for @callQuestionNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No question yet.'**
  String get callQuestionNoneYet;

  /// No description provided for @callEvaluationTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation'**
  String get callEvaluationTitle;

  /// No description provided for @callEvaluationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time feedback'**
  String get callEvaluationSubtitle;

  /// No description provided for @callScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}/100'**
  String callScoreLabel(int score);

  /// No description provided for @callStrengthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Strengths: {items}'**
  String callStrengthsLabel(String items);

  /// No description provided for @callImprovementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Improvements: {items}'**
  String callImprovementsLabel(String items);

  /// No description provided for @callSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary: {text}'**
  String callSummaryLabel(String text);

  /// No description provided for @callYourAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get callYourAnswerTitle;

  /// No description provided for @callYourAnswerSubtitleListening.
  ///
  /// In en, this message translates to:
  /// **'Real-time transcription'**
  String get callYourAnswerSubtitleListening;

  /// No description provided for @callYourAnswerSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Voice with text fallback'**
  String get callYourAnswerSubtitleFallback;

  /// No description provided for @callAnswerFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Detected or typed answer'**
  String get callAnswerFieldLabel;

  /// No description provided for @callAnswerHelperTts.
  ///
  /// In en, this message translates to:
  /// **'Gemini asks by voice and text.'**
  String get callAnswerHelperTts;

  /// No description provided for @callAnswerHelperFallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback enabled: read the question on screen.'**
  String get callAnswerHelperFallback;

  /// No description provided for @callMicStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get callMicStop;

  /// No description provided for @callMicTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get callMicTalk;

  /// No description provided for @callRepeatQuestion.
  ///
  /// In en, this message translates to:
  /// **'Repeat question'**
  String get callRepeatQuestion;

  /// No description provided for @callSendToGemini.
  ///
  /// In en, this message translates to:
  /// **'Send and continue'**
  String get callSendToGemini;

  /// No description provided for @callRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Retry voice'**
  String get callRetryVoice;

  /// No description provided for @callSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get callSkip;

  /// No description provided for @callHangUp.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get callHangUp;

  /// No description provided for @callTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: keep answers clear; if audio fails, use text and Gemini will continue the conversation.'**
  String get callTip;

  /// No description provided for @callMicActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get callMicActive;

  /// No description provided for @callMicReady.
  ///
  /// In en, this message translates to:
  /// **'Mic ready'**
  String get callMicReady;

  /// No description provided for @callBadgeSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AI speaking'**
  String get callBadgeSpeaking;

  /// No description provided for @callBadgeListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get callBadgeListening;

  /// No description provided for @callBadgeProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get callBadgeProcessing;

  /// No description provided for @callBadgeIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get callBadgeIdle;

  /// No description provided for @callAiInterviewerLabel.
  ///
  /// In en, this message translates to:
  /// **'AI interviewer'**
  String get callAiInterviewerLabel;

  /// No description provided for @dashboardMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get dashboardMyAccount;

  /// No description provided for @dashboardMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get dashboardMenuTooltip;

  /// No description provided for @dashboardNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get dashboardNavProfile;

  /// No description provided for @dashboardNavHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get dashboardNavHistory;

  /// No description provided for @dashboardSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboardSettingsTooltip;

  /// No description provided for @dashboardWelcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {firstName}'**
  String dashboardWelcomeGreeting(String firstName);

  /// No description provided for @dashboardSubtitleReady.
  ///
  /// In en, this message translates to:
  /// **'Let\'s keep improving your level.'**
  String get dashboardSubtitleReady;

  /// No description provided for @dashboardSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ready for your first simulation?'**
  String get dashboardSubtitleEmpty;

  /// No description provided for @dashboardEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Training'**
  String get dashboardEmptyStateTitle;

  /// No description provided for @dashboardEmptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get dashboardEmptyStateSubtitle;

  /// No description provided for @dashboardEmptyStateBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your first interview to unlock metrics and performance charts.'**
  String get dashboardEmptyStateBody;

  /// No description provided for @dashboardChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Evolution'**
  String get dashboardChartTitle;

  /// No description provided for @dashboardChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress across your last {count} interviews'**
  String dashboardChartSubtitle(int count);

  /// No description provided for @dashboardStatAvgScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get dashboardStatAvgScoreTitle;

  /// No description provided for @dashboardStatAvgScoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} interviews'**
  String dashboardStatAvgScoreSubtitle(int count);

  /// No description provided for @dashboardStatTotalTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed Interviews'**
  String get dashboardStatTotalTitle;

  /// No description provided for @dashboardStatTotalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total simulations completed'**
  String get dashboardStatTotalSubtitle;

  /// No description provided for @dashboardLastInterviewLabel.
  ///
  /// In en, this message translates to:
  /// **'LAST INTERVIEW'**
  String get dashboardLastInterviewLabel;

  /// No description provided for @dashboardScoreDetail.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / 100'**
  String dashboardScoreDetail(int score);

  /// No description provided for @dashboardJobRoleFallback.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get dashboardJobRoleFallback;

  /// No description provided for @statsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsScreenTitle;

  /// No description provided for @statsNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get statsNoDataTitle;

  /// No description provided for @statsNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No analyzed interview selected'**
  String get statsNoDataSubtitle;

  /// No description provided for @statsNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Finish an interview to see real charts for score, quality and time per answer.'**
  String get statsNoDataBody;

  /// No description provided for @statsMainCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your performance'**
  String get statsMainCardTitle;

  /// No description provided for @statsMainCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real charts from the interview'**
  String get statsMainCardSubtitle;

  /// No description provided for @statsPieTitle.
  ///
  /// In en, this message translates to:
  /// **'Global evaluation'**
  String get statsPieTitle;

  /// No description provided for @statsPieSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Relative weight of main dimensions'**
  String get statsPieSubtitle;

  /// No description provided for @statsBarScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Score per answer'**
  String get statsBarScoreTitle;

  /// No description provided for @statsBarScoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score comparison for each turn'**
  String get statsBarScoreSubtitle;

  /// No description provided for @statsBarQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality per answer'**
  String get statsBarQualityTitle;

  /// No description provided for @statsBarQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate based on score and richness of content'**
  String get statsBarQualitySubtitle;

  /// No description provided for @statsBarTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time per answer'**
  String get statsBarTimeTitle;

  /// No description provided for @statsBarTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seconds spent on each question'**
  String get statsBarTimeSubtitle;

  /// No description provided for @statsQuickReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick read'**
  String get statsQuickReadTitle;

  /// No description provided for @statsQuickReadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Performance interpretation'**
  String get statsQuickReadSubtitle;

  /// No description provided for @statsQuickReadOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall score: {score}/100'**
  String statsQuickReadOverallScore(int score);

  /// No description provided for @statsQuickReadAvgQuality.
  ///
  /// In en, this message translates to:
  /// **'Average answer quality: {quality}/100'**
  String statsQuickReadAvgQuality(int quality);

  /// No description provided for @statsQuickReadAvgTime.
  ///
  /// In en, this message translates to:
  /// **'Average time per answer: {seconds} seconds'**
  String statsQuickReadAvgTime(int seconds);

  /// No description provided for @statsQuickReadSlow.
  ///
  /// In en, this message translates to:
  /// **'Your pace was reflective; try to synthesize your answers a bit.'**
  String get statsQuickReadSlow;

  /// No description provided for @statsQuickReadFast.
  ///
  /// In en, this message translates to:
  /// **'Your pace was agile; make sure you keep enough depth in each example.'**
  String get statsQuickReadFast;

  /// No description provided for @statsLabelNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get statsLabelNoData;

  /// No description provided for @statsLabelAverage.
  ///
  /// In en, this message translates to:
  /// **'average'**
  String get statsLabelAverage;

  /// No description provided for @statsLabelNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to display chart.'**
  String get statsLabelNotEnoughData;

  /// No description provided for @statsGridScoreGeneral.
  ///
  /// In en, this message translates to:
  /// **'Overall score'**
  String get statsGridScoreGeneral;

  /// No description provided for @statsGridAvgQuality.
  ///
  /// In en, this message translates to:
  /// **'Avg. quality'**
  String get statsGridAvgQuality;

  /// No description provided for @statsGridValidAnswers.
  ///
  /// In en, this message translates to:
  /// **'Valid answers'**
  String get statsGridValidAnswers;

  /// No description provided for @statsGridAvgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. time'**
  String get statsGridAvgTime;

  /// No description provided for @statsGridTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get statsGridTotalTime;

  /// No description provided for @statsBreakdownCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get statsBreakdownCommunication;

  /// No description provided for @statsBreakdownMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get statsBreakdownMastery;

  /// No description provided for @statsBreakdownConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get statsBreakdownConfidence;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @generalResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get generalResultsTitle;

  /// No description provided for @generalResultsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'General results'**
  String get generalResultsCardTitle;

  /// No description provided for @generalResultsNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No data received'**
  String get generalResultsNoDataSubtitle;

  /// No description provided for @generalResultsNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Finish an interview again to see results.'**
  String get generalResultsNoDataBody;

  /// No description provided for @generalResultsSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interview summary'**
  String get generalResultsSummarySubtitle;

  /// No description provided for @generalResultsScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get generalResultsScoreLabel;

  /// No description provided for @generalResultsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get generalResultsStatusLabel;

  /// No description provided for @generalResultsStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get generalResultsStatsTitle;

  /// No description provided for @generalResultsStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visual summary of your performance'**
  String get generalResultsStatsSubtitle;

  /// No description provided for @generalResultsDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation distribution'**
  String get generalResultsDistributionTitle;

  /// No description provided for @generalResultsDistributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Communication, technical, and confidence'**
  String get generalResultsDistributionSubtitle;

  /// No description provided for @generalResultsAnswerQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer quality'**
  String get generalResultsAnswerQualityTitle;

  /// No description provided for @generalResultsAnswerQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn-by-turn estimate based on score and richness'**
  String get generalResultsAnswerQualitySubtitle;

  /// No description provided for @generalResultsTimePerAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'Time per answer'**
  String get generalResultsTimePerAnswerTitle;

  /// No description provided for @generalResultsTimePerAnswerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seconds you took to answer each question'**
  String get generalResultsTimePerAnswerSubtitle;

  /// No description provided for @generalResultsHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get generalResultsHighlightsTitle;

  /// No description provided for @generalResultsHighlightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top takeaways'**
  String get generalResultsHighlightsSubtitle;

  /// No description provided for @generalResultsNoHighlights.
  ///
  /// In en, this message translates to:
  /// **'No highlights available.'**
  String get generalResultsNoHighlights;

  /// No description provided for @generalResultsViewFullStats.
  ///
  /// In en, this message translates to:
  /// **'View full statistics'**
  String get generalResultsViewFullStats;

  /// No description provided for @generalResultsViewDetailedAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View detailed analysis'**
  String get generalResultsViewDetailedAnalysis;

  /// No description provided for @detailedAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed analysis'**
  String get detailedAnalysisTitle;

  /// No description provided for @detailedAnalysisNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No results received'**
  String get detailedAnalysisNoDataSubtitle;

  /// No description provided for @detailedAnalysisNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Finish an interview again to see the analysis.'**
  String get detailedAnalysisNoDataBody;

  /// No description provided for @detailedAnalysisMainMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key metrics'**
  String get detailedAnalysisMainMetricsTitle;

  /// No description provided for @detailedAnalysisMainMetricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Category analysis'**
  String get detailedAnalysisMainMetricsSubtitle;

  /// No description provided for @metricCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get metricCommunication;

  /// No description provided for @metricTechnicalKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Technical knowledge'**
  String get metricTechnicalKnowledge;

  /// No description provided for @metricConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get metricConfidence;

  /// No description provided for @metricSubjectMastery.
  ///
  /// In en, this message translates to:
  /// **'Subject mastery'**
  String get metricSubjectMastery;

  /// No description provided for @metricValidAnswers.
  ///
  /// In en, this message translates to:
  /// **'Valid answers'**
  String get metricValidAnswers;

  /// No description provided for @detailedAnalysisChartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Charts per answer'**
  String get detailedAnalysisChartsTitle;

  /// No description provided for @detailedAnalysisChartsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score, quality, and time evolution'**
  String get detailedAnalysisChartsSubtitle;

  /// No description provided for @detailedAnalysisScorePerAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'Score per answer'**
  String get detailedAnalysisScorePerAnswerTitle;

  /// No description provided for @detailedAnalysisScorePerAnswerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score obtained on each turn'**
  String get detailedAnalysisScorePerAnswerSubtitle;

  /// No description provided for @detailedAnalysisTimePerAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'Time per answer'**
  String get detailedAnalysisTimePerAnswerTitle;

  /// No description provided for @detailedAnalysisTimePerAnswerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time spent per turn'**
  String get detailedAnalysisTimePerAnswerSubtitle;

  /// No description provided for @detailedAnalysisPersonalizedFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized feedback'**
  String get detailedAnalysisPersonalizedFeedbackTitle;

  /// No description provided for @detailedAnalysisPersonalizedFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generated by AI'**
  String get detailedAnalysisPersonalizedFeedbackSubtitle;

  /// No description provided for @detailedAnalysisNoFeedback.
  ///
  /// In en, this message translates to:
  /// **'No feedback available.'**
  String get detailedAnalysisNoFeedback;

  /// No description provided for @detailedAnalysisImprovementTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Improvement tips'**
  String get detailedAnalysisImprovementTipsTitle;

  /// No description provided for @detailedAnalysisViewRecommendations.
  ///
  /// In en, this message translates to:
  /// **'View recommendations'**
  String get detailedAnalysisViewRecommendations;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsTitle;

  /// No description provided for @recommendationsNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No results received'**
  String get recommendationsNoDataSubtitle;

  /// No description provided for @recommendationsNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Finish an interview again to see recommendations.'**
  String get recommendationsNoDataBody;

  /// No description provided for @recommendationsSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get recommendationsSuggestionsTitle;

  /// No description provided for @recommendationsSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generated by AI based on your interview'**
  String get recommendationsSuggestionsSubtitle;

  /// No description provided for @recommendationsNone.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available.'**
  String get recommendationsNone;

  /// No description provided for @recommendationsTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Improvement tips'**
  String get recommendationsTipsTitle;

  /// No description provided for @recommendationsTipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions for your next session'**
  String get recommendationsTipsSubtitle;

  /// No description provided for @recommendationsNextSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get recommendationsNextSessionTitle;

  /// No description provided for @recommendationsNextSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat and increase your score'**
  String get recommendationsNextSessionSubtitle;

  /// No description provided for @repeatButton.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatButton;

  /// No description provided for @dashboardButton.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardButton;

  /// No description provided for @repeatInterviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat interview'**
  String get repeatInterviewTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyWhenDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String historyWhenDaysAgo(int days);

  /// No description provided for @historyWhenWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String historyWhenWeeksAgo(int weeks);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileDemoName.
  ///
  /// In en, this message translates to:
  /// **'Alex'**
  String get profileDemoName;

  /// No description provided for @profileDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frontend Jr • growth mode'**
  String get profileDemoSubtitle;

  /// No description provided for @profileStatInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get profileStatInterviews;

  /// No description provided for @profileStatAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg. score'**
  String get profileStatAvgScore;

  /// No description provided for @profileStatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStatStreak;

  /// No description provided for @profileStatLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get profileStatLevel;

  /// No description provided for @profileAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievementsTitle;

  /// No description provided for @profileAchievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks and progress'**
  String get profileAchievementsSubtitle;

  /// No description provided for @profileAchievementFirstWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'First week'**
  String get profileAchievementFirstWeekTitle;

  /// No description provided for @profileAchievementFirstWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'7 days practicing'**
  String get profileAchievementFirstWeekSubtitle;

  /// No description provided for @profileAchievementAiModeTitle.
  ///
  /// In en, this message translates to:
  /// **'AI mode'**
  String get profileAchievementAiModeTitle;

  /// No description provided for @profileAchievementAiModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'10 simulated interviews'**
  String get profileAchievementAiModeSubtitle;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @genericBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get genericBack;

  /// No description provided for @genericContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get genericContinue;

  /// No description provided for @genericRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get genericRetry;

  /// No description provided for @genericCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get genericCancel;

  /// No description provided for @genericClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get genericClose;

  /// No description provided for @genericSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get genericSave;

  /// No description provided for @genericLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get genericLoading;

  /// No description provided for @modelGemini.
  ///
  /// In en, this message translates to:
  /// **'Model: Gemini'**
  String get modelGemini;

  /// No description provided for @interviewPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing interview...'**
  String get interviewPreparing;

  /// No description provided for @interviewStarted.
  ///
  /// In en, this message translates to:
  /// **'Interview has started.'**
  String get interviewStarted;

  /// No description provided for @interviewAnswerSavedAndNext.
  ///
  /// In en, this message translates to:
  /// **'Answer saved. Preparing the next question...'**
  String get interviewAnswerSavedAndNext;

  /// No description provided for @interviewListening.
  ///
  /// In en, this message translates to:
  /// **'Listening to your answer...'**
  String get interviewListening;

  /// No description provided for @interviewAiSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AI is speaking...'**
  String get interviewAiSpeaking;

  /// No description provided for @interviewWaitingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your answer...'**
  String get interviewWaitingAnswer;

  /// No description provided for @interviewNoClearVoice.
  ///
  /// In en, this message translates to:
  /// **'No clear response detected. Please answer again.'**
  String get interviewNoClearVoice;

  /// No description provided for @interviewCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start the interview.'**
  String get interviewCouldNotStart;

  /// No description provided for @interviewCouldNotProcess.
  ///
  /// In en, this message translates to:
  /// **'Could not process the answer. You can try again.'**
  String get interviewCouldNotProcess;

  /// No description provided for @interviewTimeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Interview completed: there is not enough remaining time for a quality new question.'**
  String get interviewTimeCompleted;

  /// No description provided for @interviewStoppedListeningTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Listening stopped. You can try again.'**
  String get interviewStoppedListeningTryAgain;

  /// No description provided for @interviewReviewTranscriptOrSubmit.
  ///
  /// In en, this message translates to:
  /// **'You can review the transcript or submit it.'**
  String get interviewReviewTranscriptOrSubmit;

  /// No description provided for @interviewAskDifferentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Asking for a different question...'**
  String get interviewAskDifferentQuestion;

  /// No description provided for @interviewDifferentQuestionIntro.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go with a different question.'**
  String get interviewDifferentQuestionIntro;

  /// No description provided for @interviewCouldNotSkipCurrentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Could not skip the current question.'**
  String get interviewCouldNotSkipCurrentQuestion;

  /// No description provided for @interviewRepeatQuestionIntro.
  ///
  /// In en, this message translates to:
  /// **'Repeating the question.'**
  String get interviewRepeatQuestionIntro;

  /// No description provided for @interviewCouldNotEnableAiVoice.
  ///
  /// In en, this message translates to:
  /// **'Could not enable AI voice. The question remains visible on screen.'**
  String get interviewCouldNotEnableAiVoice;

  /// No description provided for @interviewCouldNotPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Could not play audio. The question remains available in text.'**
  String get interviewCouldNotPlayAudio;

  /// No description provided for @interviewSpeechRecognitionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device.'**
  String get interviewSpeechRecognitionUnavailable;

  /// No description provided for @interviewContinueTypingFallback.
  ///
  /// In en, this message translates to:
  /// **'You can continue by typing your answer while the conversation continues.'**
  String get interviewContinueTypingFallback;

  /// No description provided for @interviewMissingJobRole.
  ///
  /// In en, this message translates to:
  /// **'Job role is required to start the interview.'**
  String get interviewMissingJobRole;

  /// No description provided for @interviewMissingType.
  ///
  /// In en, this message translates to:
  /// **'Interview type is required.'**
  String get interviewMissingType;

  /// No description provided for @interviewCouldNotGenerateFirstQuestion.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the first question.'**
  String get interviewCouldNotGenerateFirstQuestion;

  /// No description provided for @interviewCouldNotGenerateQualityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a strong next question.'**
  String get interviewCouldNotGenerateQualityQuestion;

  /// No description provided for @interviewCouldNotGenerateAlternativeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a different question.'**
  String get interviewCouldNotGenerateAlternativeQuestion;

  /// No description provided for @interviewQuestionReady.
  ///
  /// In en, this message translates to:
  /// **'New question ready.'**
  String get interviewQuestionReady;

  /// No description provided for @interviewEmptyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Gemini returned an empty question.'**
  String get interviewEmptyQuestion;

  /// No description provided for @interviewCouldNotPlayQuestionTextMode.
  ///
  /// In en, this message translates to:
  /// **'Could not play the question. Continuing in text mode.'**
  String get interviewCouldNotPlayQuestionTextMode;

  /// No description provided for @interviewQuestionAvailableInText.
  ///
  /// In en, this message translates to:
  /// **'The question is available in text. Answer by voice or typing.'**
  String get interviewQuestionAvailableInText;

  /// No description provided for @interviewTypeAnswerContinue.
  ///
  /// In en, this message translates to:
  /// **'Type your answer so the next question can be generated.'**
  String get interviewTypeAnswerContinue;

  /// No description provided for @interviewCouldNotActivateMic.
  ///
  /// In en, this message translates to:
  /// **'Could not activate the microphone.'**
  String get interviewCouldNotActivateMic;

  /// No description provided for @interviewCouldNotTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Could not transcribe your answer. You can try again.'**
  String get interviewCouldNotTranscribe;

  /// No description provided for @interviewNoVoiceDetectedWrite.
  ///
  /// In en, this message translates to:
  /// **'No voice detected. You can try again or type your answer.'**
  String get interviewNoVoiceDetectedWrite;

  /// No description provided for @interviewNoVoiceDetectedRetrying.
  ///
  /// In en, this message translates to:
  /// **'No voice detected. I will listen again.'**
  String get interviewNoVoiceDetectedRetrying;

  /// No description provided for @interviewCouldNotHearClearly.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t hear you clearly. Please answer again.'**
  String get interviewCouldNotHearClearly;

  /// No description provided for @interviewQuestionGoalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Interview completed: reached {questions} questions for {minutes} minutes.'**
  String interviewQuestionGoalCompleted(int questions, int minutes);

  /// No description provided for @callAnswersSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Answers saved'**
  String get callAnswersSavedTitle;

  /// No description provided for @callAnswersSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback is generated at the end'**
  String get callAnswersSavedSubtitle;

  /// No description provided for @callAnswersSavedProgress.
  ///
  /// In en, this message translates to:
  /// **'You have {current} of {total} answers recorded.'**
  String callAnswersSavedProgress(int current, int total);

  /// No description provided for @callAnswersSavedBody.
  ///
  /// In en, this message translates to:
  /// **'During the call we only save your answers to keep the interview fluid. Once it ends, we generate the full analysis.'**
  String get callAnswersSavedBody;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileEditName;

  /// No description provided for @profileEditOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get profileEditOccupation;

  /// No description provided for @profileEditPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profileEditPhone;

  /// No description provided for @profileLevelPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get profileLevelPro;

  /// No description provided for @profileLevelRookie.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get profileLevelRookie;

  /// No description provided for @aiFocusArea_edgeCases.
  ///
  /// In en, this message translates to:
  /// **'edge cases or unusual scenarios'**
  String get aiFocusArea_edgeCases;

  /// No description provided for @aiFocusArea_performance.
  ///
  /// In en, this message translates to:
  /// **'low-level optimization and performance'**
  String get aiFocusArea_performance;

  /// No description provided for @aiFocusArea_security.
  ///
  /// In en, this message translates to:
  /// **'security, vulnerabilities, and prevention'**
  String get aiFocusArea_security;

  /// No description provided for @aiFocusArea_dbDesign.
  ///
  /// In en, this message translates to:
  /// **'database scalability and design'**
  String get aiFocusArea_dbDesign;

  /// No description provided for @aiFocusArea_designPatterns.
  ///
  /// In en, this message translates to:
  /// **'uncommon design patterns'**
  String get aiFocusArea_designPatterns;

  /// No description provided for @aiFocusArea_errorHandling.
  ///
  /// In en, this message translates to:
  /// **'error handling, concurrency, and resilience'**
  String get aiFocusArea_errorHandling;

  /// No description provided for @aiFocusArea_legacyCode.
  ///
  /// In en, this message translates to:
  /// **'refactoring and legacy code'**
  String get aiFocusArea_legacyCode;

  /// No description provided for @aiFocusArea_eventDriven.
  ///
  /// In en, this message translates to:
  /// **'asynchronous communication and event-driven architecture'**
  String get aiFocusArea_eventDriven;

  /// No description provided for @aiFocusArea_testing.
  ///
  /// In en, this message translates to:
  /// **'testing, code quality, and TDD'**
  String get aiFocusArea_testing;

  /// No description provided for @aiFocusArea_troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'production incident resolution (troubleshooting)'**
  String get aiFocusArea_troubleshooting;

  /// No description provided for @aiFocusArea_apiDesign.
  ///
  /// In en, this message translates to:
  /// **'API design and integration best practices'**
  String get aiFocusArea_apiDesign;

  /// No description provided for @aiFocusArea_stateManagement.
  ///
  /// In en, this message translates to:
  /// **'complex state management'**
  String get aiFocusArea_stateManagement;

  /// No description provided for @aiFocusArea_iac.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure as Code and CI/CD'**
  String get aiFocusArea_iac;

  /// No description provided for @aiFocusArea_observability.
  ///
  /// In en, this message translates to:
  /// **'observability, metrics, and traceability'**
  String get aiFocusArea_observability;

  /// No description provided for @aiFocusArea_dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'data governance and privacy'**
  String get aiFocusArea_dataPrivacy;

  /// No description provided for @aiFocusArea_network.
  ///
  /// In en, this message translates to:
  /// **'network performance and latency'**
  String get aiFocusArea_network;

  /// No description provided for @aiFocusArea_algorithms.
  ///
  /// In en, this message translates to:
  /// **'advanced algorithms and data structures'**
  String get aiFocusArea_algorithms;

  /// No description provided for @aiFocusArea_memory.
  ///
  /// In en, this message translates to:
  /// **'memory management and garbage collection'**
  String get aiFocusArea_memory;

  /// No description provided for @aiFocusArea_caching.
  ///
  /// In en, this message translates to:
  /// **'caching strategies (Redis, Memcached)'**
  String get aiFocusArea_caching;

  /// No description provided for @aiFocusArea_messaging.
  ///
  /// In en, this message translates to:
  /// **'message queues (RabbitMQ, Kafka)'**
  String get aiFocusArea_messaging;

  /// No description provided for @aiFocusArea_auth.
  ///
  /// In en, this message translates to:
  /// **'authentication and authorization (OAuth2, JWT, RBAC)'**
  String get aiFocusArea_auth;

  /// No description provided for @aiFocusArea_sqlOpt.
  ///
  /// In en, this message translates to:
  /// **'SQL query optimization and indexing'**
  String get aiFocusArea_sqlOpt;

  /// No description provided for @aiFocusArea_consistency.
  ///
  /// In en, this message translates to:
  /// **'eventual vs. strong consistency'**
  String get aiFocusArea_consistency;

  /// No description provided for @aiFocusArea_serverless.
  ///
  /// In en, this message translates to:
  /// **'serverless architectures and FaaS'**
  String get aiFocusArea_serverless;

  /// No description provided for @aiFocusArea_containers.
  ///
  /// In en, this message translates to:
  /// **'containers and orchestration (Docker, Kubernetes)'**
  String get aiFocusArea_containers;

  /// No description provided for @aiFocusArea_websockets.
  ///
  /// In en, this message translates to:
  /// **'WebSockets and bi-directional communication'**
  String get aiFocusArea_websockets;

  /// No description provided for @aiFocusArea_apiComparison.
  ///
  /// In en, this message translates to:
  /// **'GraphQL vs. gRPC vs. REST'**
  String get aiFocusArea_apiComparison;

  /// No description provided for @aiFocusArea_idempotency.
  ///
  /// In en, this message translates to:
  /// **'idempotency in APIs'**
  String get aiFocusArea_idempotency;

  /// No description provided for @aiFocusArea_zeroDowntime.
  ///
  /// In en, this message translates to:
  /// **'zero-downtime database migrations'**
  String get aiFocusArea_zeroDowntime;

  /// No description provided for @aiFocusArea_bigData.
  ///
  /// In en, this message translates to:
  /// **'large-scale data handling (Sharding, Partitioning)'**
  String get aiFocusArea_bigData;

  /// No description provided for @aiFocusArea_tls.
  ///
  /// In en, this message translates to:
  /// **'data transport security (TLS/SSL)'**
  String get aiFocusArea_tls;

  /// No description provided for @aiFocusArea_distributed.
  ///
  /// In en, this message translates to:
  /// **'distributed systems design'**
  String get aiFocusArea_distributed;

  /// No description provided for @aiFocusArea_cleanArch.
  ///
  /// In en, this message translates to:
  /// **'SOLID principles and Clean Architecture'**
  String get aiFocusArea_cleanArch;

  /// No description provided for @aiFocusArea_packaging.
  ///
  /// In en, this message translates to:
  /// **'dependency management and packaging'**
  String get aiFocusArea_packaging;

  /// No description provided for @aiFocusArea_maintenance.
  ///
  /// In en, this message translates to:
  /// **'task automation and maintenance scripts'**
  String get aiFocusArea_maintenance;

  /// No description provided for @aiPromptSystemInterviewer.
  ///
  /// In en, this message translates to:
  /// **'You are an expert interviewer. Reply in {language}. When asked for JSON, return JSON only with no extra text.'**
  String aiPromptSystemInterviewer(String language);

  /// No description provided for @aiPromptSystemCoach.
  ///
  /// In en, this message translates to:
  /// **'You are an interview coach. Reply in {language}. When asked for JSON, return JSON only with no extra text.'**
  String aiPromptSystemCoach(String language);

  /// No description provided for @aiPromptVarietyInstructions.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: Specifically focus the questions around these themes: {focusText}. DO NOT ask about \'microservicios vs monoliths\', \'SQL vs NoSQL\', or other extremely common entry-level topics unless they are the only way to address the specific themes selected. We want deep, specific, and varied questions that test real-world experience across the ENTIRE spectrum of the role.'**
  String aiPromptVarietyInstructions(String focusText);

  /// No description provided for @aiPromptQuestionGen.
  ///
  /// In en, this message translates to:
  /// **'Generate {count} {type} interview questions for the role: \"{jobRole}\". Make sure the questions are highly varied, creative, and cover different angles. Avoid generic or cliché questions (e.g., \"What are your strengths?\", \"Tell me about yourself\"). {varietyInstructions} (Random Seed: {seed}) Return ONLY JSON with this exact schema: {jsonSchema} Requirements: - Questions must be clear and specific - No numbering in the question text - No markdown'**
  String aiPromptQuestionGen(
    int count,
    String type,
    String jobRole,
    String varietyInstructions,
    int seed,
    String jsonSchema,
  );

  /// No description provided for @aiPromptEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Evaluate the user\'s answer for a {type} interview for the \"{jobRole}\" role. Question: \"{question}\" User answer: \"{answer}\" (Random Seed: {seed}) Return ONLY JSON with this exact schema: {jsonSchema} Rules: - overallScore must be an integer 0..100 - strengths/improvements: 2 to 5 items each - suggestedAnswer: concise, improved, and results-oriented - followUpQuestions: 0 to 3 highly contextual, creative, and non-cliché follow-up questions based on the user\'s specific answer. - No markdown'**
  String aiPromptEvaluation(
    String type,
    String jobRole,
    String question,
    String answer,
    int seed,
    String jsonSchema,
  );

  /// No description provided for @aiPromptFeedback.
  ///
  /// In en, this message translates to:
  /// **'Based on the question, the user\'s answer, and the evaluation, generate actionable feedback. Question: \"{question}\" User answer: \"{answer}\" Evaluation (JSON): {evaluationJson} Return ONLY JSON with this exact schema: {jsonSchema} Rules: - summary: max 3 sentences - actionItems: 3 to 6 actionable items - keyPhrasesToUse: 3 to 8 short phrases the user can use - No markdown'**
  String aiPromptFeedback(
    String question,
    String answer,
    String evaluationJson,
    String jsonSchema,
  );

  /// No description provided for @aiPromptResultsAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analyze the interview results for the \"{jobRole}\" role ({typeLabel} interview). Overall score (already calculated): {overallScore} Outcome: {outcome} Interview history (Q&A with per-answer scores): {history} Return ONLY a valid JSON object — no markdown, no extra text, no explanation: {jsonSchema}'**
  String aiPromptResultsAnalysis(
    String jobRole,
    String typeLabel,
    int overallScore,
    String outcome,
    String history,
    String jsonSchema,
  );

  /// No description provided for @aiPromptNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Act as an expert interviewer for the \"{jobRole}\" role. Interview type: {typeLabel}. History (question, answer, evaluation): {history} Generate the next question in English: - It must be a single question. - It must adapt to the last answer. - If score was low, ask for clarification or a concrete example. - If score was high, increase difficulty or go deeper. {varietyInstructions} - AVOID generic or overused topics (e.g., \'microservicios vs monoliths\', \'SQL vs NoSQL\') unless directly related to the previous answer. - Ensure the topic is different from previous questions in the history to maintain variety. - No numbering. - No markdown. Return ONLY the question text.'**
  String aiPromptNextQuestion(
    String jobRole,
    String typeLabel,
    String history,
    String varietyInstructions,
  );

  /// No description provided for @aiPromptOpening.
  ///
  /// In en, this message translates to:
  /// **'You are a professional and friendly interviewer for the role: \"{jobRole}\". Introduce yourself briefly and ask the first question for a {typeLabel} interview. {varietyInstructions} Rules: - Return ONLY the text of the greeting and the question. - DO NOT use JSON, markdown, or any other formatting. - Be natural and professional.'**
  String aiPromptOpening(
    String jobRole,
    String typeLabel,
    String varietyInstructions,
  );

  /// No description provided for @aiPromptConversationalNext.
  ///
  /// In en, this message translates to:
  /// **'Interviewer for \"{jobRole}\" ({typeLabel}). Last Q: \"{lastQuestion}\" Candidate A: \"{lastAnswer}\" Goal: Ask the next question. 1. Briefly acknowledge or react to the candidate\'s last answer. 2. Ask a follow-up or a new relevant question. {varietyInstructions} 3. Keep it natural and professional. 4. Return ONLY the text of the reaction and the question. No JSON. History context: {history}'**
  String aiPromptConversationalNext(
    String jobRole,
    String typeLabel,
    String lastQuestion,
    String lastAnswer,
    String varietyInstructions,
    String history,
  );

  /// No description provided for @aiPromptAlternative.
  ///
  /// In en, this message translates to:
  /// **'Act as an expert interviewer for the \"{jobRole}\" role. Interview type: {typeLabel}. Current question: \"{currentQuestion}\" Real history: {history} Generate a new question in English to replace the current one. {varietyInstructions} Rules: - It must be different from the current question. - It must keep continuity with the history. - It must sound natural, concise, and direct. - No numbering. - No markdown. Return ONLY the question text.'**
  String aiPromptAlternative(
    String jobRole,
    String typeLabel,
    String currentQuestion,
    String history,
    String varietyInstructions,
  );

  /// No description provided for @statsLabelQuestionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Q'**
  String get statsLabelQuestionPrefix;

  /// No description provided for @statsLabelChartStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get statsLabelChartStart;

  /// No description provided for @errorGeminiMissingKey.
  ///
  /// In en, this message translates to:
  /// **'Missing GEMINI_API_KEY. Configure it in the .env file.'**
  String get errorGeminiMissingKey;

  /// No description provided for @errorGeminiContact.
  ///
  /// In en, this message translates to:
  /// **'Could not contact Gemini.'**
  String get errorGeminiContact;

  /// No description provided for @errorGeminiNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection or could not contact Gemini.'**
  String get errorGeminiNoInternet;

  /// No description provided for @errorGeminiParse.
  ///
  /// In en, this message translates to:
  /// **'Error parsing Gemini response.'**
  String get errorGeminiParse;

  /// No description provided for @errorGeminiApiGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error calling Gemini.'**
  String get errorGeminiApiGeneric;

  /// No description provided for @errorGeminiInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from Gemini.'**
  String get errorGeminiInvalidResponse;

  /// No description provided for @errorGeminiNoCandidates.
  ///
  /// In en, this message translates to:
  /// **'Gemini returned no candidates.'**
  String get errorGeminiNoCandidates;

  /// No description provided for @errorGeminiEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'Gemini returned an empty response.'**
  String get errorGeminiEmptyResponse;

  /// No description provided for @errorGeminiFallbackFeedback.
  ///
  /// In en, this message translates to:
  /// **'Review complete. Check your score breakdown for details.'**
  String get errorGeminiFallbackFeedback;

  /// No description provided for @aiPromptRewriteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Rewrite this interview question so it is more complete, specific, and natural. Weak question: \"{weakQuestion}\" Previous question: \"{lastQuestion}\" Last candidate answer: \"{lastAnswer}\" Return ONLY one question in English. Rules: - Exactly one question. - It must ask for concrete context, example, decision, impact, or result. - It must not repeat the previous question. - It should not be vague or too short. - No markdown.'**
  String aiPromptRewriteQuestion(
    String weakQuestion,
    String lastQuestion,
    String lastAnswer,
  );

  /// No description provided for @aiPromptSystemInterviewerSpoken.
  ///
  /// In en, this message translates to:
  /// **'You are a human interviewer. Create clear and specific spoken questions.'**
  String get aiPromptSystemInterviewerSpoken;

  /// No description provided for @feedbackSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Analysis'**
  String get feedbackSummaryTitle;

  /// No description provided for @feedbackActionItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Next Steps'**
  String get feedbackActionItemsTitle;

  /// No description provided for @feedbackKeyPhrasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended Key Phrases'**
  String get feedbackKeyPhrasesTitle;

  /// No description provided for @errorAIFailureFriendly.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t process the detailed feedback at this moment. Please check your scores below.'**
  String get errorAIFailureFriendly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
