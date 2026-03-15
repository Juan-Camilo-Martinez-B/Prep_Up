import 'package:flutter/material.dart';
import 'package:prep_up/models/app_settings_model.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  void setThemeMode(AppThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}

class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    final controller = scope?.notifier;
    if (controller == null) {
      throw StateError('AppThemeScope no encontrado en el árbol de widgets');
    }
    return controller;
  }
}
