import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const String defaultGroqModel = 'openai/gpt-oss-120b';

  static String get groqApiKey => (dotenv.env['GROQ_API_KEY'] ?? '').trim();

  static String get groqModel {
    final raw = (dotenv.env['GROQ_MODEL'] ?? '').trim();
    return raw.isEmpty ? defaultGroqModel : raw;
  }

  /// Esfuerzo de razonamiento para modelos que lo soportan (low, medium, high).
  /// Si no se define y el modelo es gpt-oss, se usa "low" para no gastar el
  /// presupuesto de tokens en razonamiento.
  static String? get groqReasoningEffort {
    final raw = (dotenv.env['GROQ_REASONING_EFFORT'] ?? '').trim().toLowerCase();
    if (raw.isNotEmpty) return raw;
    return groqModel.contains('gpt-oss') ? 'low' : null;
  }

  static final Uri groqChatCompletionsUri = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );
}
