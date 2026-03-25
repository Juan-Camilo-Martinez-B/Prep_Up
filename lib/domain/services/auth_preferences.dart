import 'package:shared_preferences/shared_preferences.dart';

class AuthPreferences {
  static const _rememberKey = 'remember_session';

  static Future<bool> getRememberSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  static Future<void> setRememberSession(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
  }
}
