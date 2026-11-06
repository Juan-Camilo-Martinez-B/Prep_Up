/// Recuerda si la sesión debe persistir en el dispositivo.
abstract class SessionPreferences {
  Future<bool> getRememberSession();

  Future<void> setRememberSession(bool remember);
}
