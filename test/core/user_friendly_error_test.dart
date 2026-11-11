import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/features/interview/domain/ai_provider_exception.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('es'));
  });

  test('un mensaje del proveedor se muestra tal cual', () {
    final message = userFriendlyErrorMessage(
      AiProviderException('Invalid API Key', statusCode: 401),
      l10n,
    );

    expect(message, 'Invalid API Key');
  });

  test('credenciales, correo duplicado y límite usan el texto de la app', () {
    expect(
      userFriendlyAuthErrorMessage(
        const AuthException('Invalid login credentials'),
        l10n,
        action: AuthAction.login,
      ),
      l10n.loginErrorInvalidCredentials,
    );
    expect(
      userFriendlyAuthErrorMessage(
        const AuthException('User already registered'),
        l10n,
        action: AuthAction.register,
      ),
      l10n.registerEmailAlreadyExists,
    );
    expect(
      userFriendlyErrorMessage(
        const AuthException('rate limit exceeded'),
        l10n,
      ),
      l10n.authRateLimitExceeded,
    );
  });

  test('un fallo de red o de tiempo no muestra la excepción cruda', () {
    expect(
      userFriendlyErrorMessage(
        const SocketException('Failed host lookup'),
        l10n,
      ),
      l10n.errorNoInternet,
    );
    expect(
      userFriendlyErrorMessage(http.ClientException('caída'), l10n),
      l10n.errorNoInternet,
    );
    expect(
      userFriendlyErrorMessage(TimeoutException('timed out'), l10n),
      l10n.errorTimeout,
    );
  });

  test('un error desconocido cae en el texto genérico', () {
    expect(
      userFriendlyErrorMessage(StateError('x'), l10n),
      l10n.unexpectedError,
    );
  });
}
