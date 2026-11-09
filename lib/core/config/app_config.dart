import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const String defaultGroqModel = 'openai/gpt-oss-120b';

  static String get groqApiKey => (dotenv.env['GROQ_API_KEY'] ?? '').trim();

  static String get groqModel {
    final raw = (dotenv.env['GROQ_MODEL'] ?? '').trim();
    return raw.isEmpty ? defaultGroqModel : raw;
  }

  /// Esfuerzo de razonamiento definido en el .env (low, medium, high), o null.
  static String? get groqReasoningEffort {
    final raw = (dotenv.env['GROQ_REASONING_EFFORT'] ?? '')
        .trim()
        .toLowerCase();
    return raw.isEmpty ? null : raw;
  }

  /// Valor por defecto según el modelo: "low" en gpt-oss para no gastar el
  /// presupuesto de tokens en razonamiento; otros modelos no aceptan el campo.
  static String? defaultReasoningEffortFor(String model) {
    return model.contains('gpt-oss') ? 'low' : null;
  }

  static final Uri groqChatCompletionsUri = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );
}
