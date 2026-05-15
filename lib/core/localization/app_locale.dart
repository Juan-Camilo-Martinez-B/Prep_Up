import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleRuntime {
  static Locale _locale = const Locale('es');

  static Locale get locale => _locale;
  static String get languageCode => _locale.languageCode;
  static bool get isSpanish => _locale.languageCode == 'es';
  static bool get isEnglish => _locale.languageCode == 'en';

  static void setLocale(Locale locale) {
    _locale = locale;
  }
}

class AppLocaleController extends ChangeNotifier {
  static const _localeKey = 'app_locale';

  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> load() async {
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
