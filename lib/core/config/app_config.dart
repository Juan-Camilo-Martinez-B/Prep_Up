import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get geminiModel {
    final raw = (dotenv.env['GEMINI_MODEL'] ?? '').trim();
    if (raw.isEmpty) return 'gemini-1.5-flash-latest';
    if (raw == 'gemini-1.5-flash') return 'gemini-1.5-flash-latest';
    if (raw.startsWith('models/')) return raw.substring('models/'.length);
    return raw;
  }

  static Uri geminiGenerateContentUri({
    required String model,
    required String apiKey,
  }) {
    return Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );
  }

  static Uri geminiListModelsUri({required String apiKey}) {
    return Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
    );
  }
}

