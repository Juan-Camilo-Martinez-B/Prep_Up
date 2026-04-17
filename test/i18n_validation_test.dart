import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('i18n validation', () {
    test('ARB keys are synchronized between English and Spanish', () {
      final en = _readArb('lib/l10n/app_en.arb');
      final es = _readArb('lib/l10n/app_es.arb');

      final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
      final esKeys = es.keys.where((k) => !k.startsWith('@')).toSet();

      expect(enKeys.difference(esKeys), isEmpty);
      expect(esKeys.difference(enKeys), isEmpty);
    });

    test('No hardcoded UI literals remain in migrated UI files', () {
      const migratedFiles = <String>[
        'lib/presentation/screens/settings/settings_screen.dart',
        'lib/presentation/screens/auth/splash_screen.dart',
        'lib/presentation/screens/auth/login_screen.dart',
        'lib/presentation/screens/auth/register_screen.dart',
        'lib/presentation/screens/auth/forgot_password_screen.dart',
        'lib/presentation/screens/interview/interview_configuration_screen.dart',
        'lib/presentation/screens/interview/select_interview_type_screen.dart',
        'lib/presentation/screens/interview/select_job_role_screen.dart',
        'lib/presentation/screens/interview/device_check_screen.dart',
        'lib/presentation/screens/interview/simulated_call_screen.dart',
        'lib/presentation/screens/analysis/interview_processing_screen.dart',
        'lib/presentation/screens/analysis/general_results_screen.dart',
        'lib/presentation/screens/analysis/detailed_analysis_screen.dart',
        'lib/presentation/screens/analysis/recommendations_screen.dart',
        'lib/presentation/screens/tracking/statistics_screen.dart',
        'lib/presentation/screens/tracking/repeat_interview_screen.dart',
        'lib/presentation/screens/tracking/interview_history_screen.dart',
        'lib/presentation/screens/profile/user_profile_screen.dart',
        'lib/presentation/screens/dashboard/dashboard_screen.dart',
      ];

      final forbiddenPatterns = <RegExp>[
        RegExp(r"Text\(\s*'(?!\$)[^']+'"),
        RegExp(r"label:[ \t]*'(?!\$)[^']+'"),
        RegExp(r"title:[ \t]*'(?!\$)[^']+'"),
        RegExp(r"subtitle:[ \t]*'(?!\$)[^']+'"),
        RegExp(r"labelText:[ \t]*'(?!\$)[^']+'"),
        RegExp(r"hintText:[ \t]*'(?!\$)[^']+'"),
      ];

      final violations = <String>[];
      for (final relativePath in migratedFiles) {
        final file = File(_abs(relativePath));
        final content = file.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          if (pattern.hasMatch(content)) {
            violations.add('$relativePath -> ${pattern.pattern}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Found hardcoded literals in migrated files:\n${violations.join('\n')}',
      );
    });
  });

  group('locale persistence', () {
    test('language preference is persisted and restored', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppLocaleController();
      await controller.load();
      expect(controller.languageCode, 'es');

      await controller.setLocale(const Locale('en'));
      expect(controller.languageCode, 'en');

      final next = AppLocaleController();
      await next.load();
      expect(next.languageCode, 'en');
    });
  });
}

Map<String, dynamic> _readArb(String path) {
  final file = File(_abs(path));
  final raw = file.readAsStringSync();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Invalid ARB file: $path');
  }
  return decoded;
}

String _abs(String relative) {
  return '${Directory.current.path}${Platform.pathSeparator}$relative';
}
