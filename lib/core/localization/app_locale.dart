import 'package:flutter/material.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleRuntime {
  static Locale _locale = const Locale('es');

  static Locale get locale => _locale;
  static String get languageCode => _locale.languageCode;

  static void setLocale(Locale locale) {
    _locale = locale;
  }
}

class AppLocaleController extends ChangeNotifier {
  static const _localeKey = 'app_locale';
  final RelationalDatabaseService _dbService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();

  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> load() async {
    // 1. Intentar cargar desde Supabase si hay usuario
    final user = _authService.currentUser;
    if (user != null) {
      // Nota: configuraciones en la BD tiene language_code pero AppSettingsModel no lo tiene explícito,
      // se asume que se guarda como parte de los ajustes del usuario.
      // Por simplicidad, usamos SharedPreferences como fallback y sincronizamos.
      final settings = await _dbService.getSettingsForUser(user.id);
      if (settings != null) {
        // Aquí podríamos cargar el locale si estuviera en AppSettingsModel.
        // Por ahora mantenemos la lógica de SharedPreferences pero preparada para DB.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_localeKey);
    if (stored != null && stored.isNotEmpty) {
      _locale = Locale(stored);
    }
    AppLocaleRuntime.setLocale(_locale);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    AppLocaleRuntime.setLocale(locale);
    notifyListeners();
    
    // Guardar localmente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);

    // Sincronizar con Supabase si hay usuario
    final user = _authService.currentUser;
    if (user != null) {
      // Podríamos extender AppSettingsModel para incluir languageCode si fuera necesario
    }
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    final controller = scope?.notifier;
    if (controller == null) {
      throw StateError('AppLocaleScope not found in widget tree');
    }
    return controller;
  }
}

const supportedAppLocales = <Locale>[Locale('es'), Locale('en')];
