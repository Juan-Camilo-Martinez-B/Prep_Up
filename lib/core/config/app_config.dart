import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get geminiModel =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

  static Uri geminiGenerateContentUri({
    required String model,
    required String apiKey,
  }) {
    return Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );
  }
}

