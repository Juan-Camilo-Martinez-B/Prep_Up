import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/core/config/app_config.dart';

void main() {
  test('sin modelo en el entorno usa el de Groq por defecto', () {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=clave\n');

    expect(AppConfig.groqApiKey, 'clave');
    expect(AppConfig.groqModel, AppConfig.defaultGroqModel);
    expect(AppConfig.groqReasoningEffort, isNull);
  });

  test('respeta modelo y esfuerzo cuando vienen en el entorno', () {
    dotenv.testLoad(
      fileInput:
          'GROQ_MODEL=llama-3.3-70b-versatile\nGROQ_REASONING_EFFORT=High\n',
    );

    expect(AppConfig.groqModel, 'llama-3.3-70b-versatile');
    expect(AppConfig.groqReasoningEffort, 'high');
  });

  test('solo gpt-oss recibe razonamiento bajo por defecto', () {
    expect(AppConfig.defaultReasoningEffortFor('openai/gpt-oss-120b'), 'low');
    expect(
      AppConfig.defaultReasoningEffortFor('llama-3.3-70b-versatile'),
      isNull,
    );
  });
}
