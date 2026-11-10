import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prep_up/features/interview/domain/ai_provider_exception.dart';
import 'package:prep_up/features/interview/infrastructure/groq_service.dart';

import '../support/groq_fake_server.dart';

/// El cliente HTTP real habla con un servidor local. Cubre el socket, las
/// cabeceras y el parseo. El archivo de unidad sigue usando MockClient.
void main() {
  late GroqFakeServer server;
  late http.Client client;

  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  tearDown(() async {
    client.close();
    await server.close();
  });

  GroqService serviceFor(GroqFakeServer target) {
    return GroqService(
      httpClient: client,
      apiKey: 'integration-key',
      model: 'llama-3.3-70b-versatile',
      reasoningEffort: null,
      chatCompletionsUri: target.chatCompletionsUri,
    );
  }

  test(
    'sendPrompt recorre el cliente HTTP real hasta el servidor local',
    () async {
      server = await GroqFakeServer.start(content: 'pregunta de seguimiento');
      client = http.Client();

      final result = await serviceFor(server).sendPrompt(
        prompt: 'explica la caché',
        systemInstruction: 'eres un entrevistador',
        temperature: 0.2,
        maxOutputTokens: 128,
      );

      expect(result, 'pregunta de seguimiento');
      expect(server.requestCount, 1);
      expect(server.authorizationOf(0), 'Bearer integration-key');
      final body = server.bodyOf(0);
      expect(body['model'], 'llama-3.3-70b-versatile');
      expect(body.containsKey('reasoning_effort'), isFalse);
      expect(body['max_completion_tokens'], 128);
      expect(body['messages'], [
        {'role': 'system', 'content': 'eres un entrevistador'},
        {'role': 'user', 'content': 'explica la caché'},
      ]);
      expect(server.chatCompletionsUri.host, isNot('api.groq.com'));
    },
  );

  test('un 401 del servidor local llega como AiProviderException', () async {
    server = await GroqFakeServer.start(
      statusCode: 401,
      errorMessage: 'Invalid API Key',
    );
    client = http.Client();

    await expectLater(
      serviceFor(server).sendPrompt(prompt: 'p'),
      throwsA(
        isA<AiProviderException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid API Key'),
      ),
    );
  });
}
