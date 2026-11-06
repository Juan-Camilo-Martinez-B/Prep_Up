import 'package:prep_up/features/auth/domain/session_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPreferences implements SessionPreferences {
  static const _rememberKey = 'remember_session';

  @override
  Future<bool> getRememberSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  @override
  Future<void> setRememberSession(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
  }
}
