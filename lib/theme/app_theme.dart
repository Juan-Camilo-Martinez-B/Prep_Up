import 'package:flutter/material.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';

class AppThemeController extends ChangeNotifier {
  final RelationalDatabaseService _dbService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final user = _authService.currentUser;
    if (user != null) {
      final settings = await _dbService.getSettingsForUser(user.id);
      if (settings != null) {
        _themeMode = settings.themeMode;
        notifyListeners();
      }
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final user = _authService.currentUser;
    if (user != null) {
      final currentSettings = await _dbService.getSettingsForUser(user.id) ?? AppSettingsModel.defaults();
      await _dbService.saveSettingsForUser(
        user.id,
        currentSettings.copyWith(themeMode: mode),
      );
    }
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
