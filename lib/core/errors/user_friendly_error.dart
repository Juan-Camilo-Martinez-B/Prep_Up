import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthAction { login, register, resetPassword, generic }

String userFriendlyErrorMessage(
  Object error,
  AppLocalizations l10n, {
  AuthAction authAction = AuthAction.generic,
}) {
  if (error is GeminiException) {
    return _normalizeUserMessage(error.message, l10n);
  }

  if (error is AuthException) {
    return userFriendlyAuthErrorMessage(error, l10n, action: authAction);
  }

  if (error is PostgrestException || error is StorageException) {
    return l10n.errorServerUnavailable;
  }

  if (error is TimeoutException) {
    return l10n.errorTimeout;
  }

  if (error is http.ClientException) {
    return l10n.errorNoInternet;
  }

  final raw = error.toString();
  if (_looksLikeNoInternet(raw)) {
    return l10n.errorNoInternet;
  }
  if (_looksLikeTimeout(raw)) {
    return l10n.errorTimeout;
  }

  return l10n.unexpectedError;
}

String userFriendlyAuthErrorMessage(
  AuthException error,
  AppLocalizations l10n, {
  AuthAction action = AuthAction.generic,
}) {
  final message = error.message.toLowerCase();

  if (message.contains('email not confirmed') ||
      message.contains('email_not_confirmed')) {
    return l10n.loginErrorEmailNotConfirmed;
  }

  if (message.contains('invalid login credentials') ||
      message.contains('invalid_credentials')) {
    return l10n.loginErrorInvalidCredentials;
  }

  if (message.contains('user already registered') ||
      message.contains('already registered') ||
      message.contains('user_already_exists') ||
      message.contains('email already') ||
      message.contains('already_exists')) {
    return l10n.registerEmailAlreadyExists;
  }

  if (message.contains('rate limit') || message.contains('too many requests')) {
    return l10n.authRateLimitExceeded;
  }

  if (message.contains('signup is disabled')) {
    return l10n.authSignupDisabled;
  }

  if (message.contains('password') &&
      (message.contains('weak') ||
          message.contains('at least') ||
          message.contains('should be') ||
          message.contains('invalid'))) {
    return l10n.registerWeakPassword;
  }

  if (action == AuthAction.register) return l10n.registerError;
  if (action == AuthAction.login) return l10n.loginErrorGeneric;
  if (action == AuthAction.resetPassword) return l10n.forgotPasswordErrorGeneric;
  return l10n.authErrorGeneric;
}

String _normalizeUserMessage(String message, AppLocalizations l10n) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return l10n.unexpectedError;
  return trimmed;
}

bool _looksLikeNoInternet(String raw) {
  final s = raw.toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection failed') ||
      s.contains('no address associated with hostname') ||
      s.contains('name not resolved');
}

bool _looksLikeTimeout(String raw) {
  final s = raw.toLowerCase();
  return s.contains('timed out') || s.contains('timeout');
}

