import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prep_up/features/interview/infrastructure/groq_service.dart';

import '../support/groq_fake_server.dart';

/// Concurrencia del adapter contra el servidor local. No mide la cuota ni
/// la latencia de api.groq.com.
void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  test(
    'cuarenta sendPrompt concurrentes completan sin perder respuestas',
    () async {
      const total = 40;
      final server = await GroqFakeServer.start(
        delay: const Duration(milliseconds: 30),
        content: 'ok',
      );
      final client = http.Client();
      final service = GroqService(
        httpClient: client,
        apiKey: 'load-key',
        model: 'llama-3.3-70b-versatile',
        reasoningEffort: null,
        chatCompletionsUri: server.chatCompletionsUri,
      );
      addTearDown(() async {
        client.close();
        await server.close();
      });

      final started = DateTime.now();
      final results = await Future.wait([
        for (var i = 0; i < total; i++)
          service.sendPrompt(prompt: 'carga $i', maxOutputTokens: 32),
      ]);
      final elapsed = DateTime.now().difference(started);

      expect(results, everyElement('ok'));
      expect(server.requestCount, total);
      expect(server.authorizationOf(0), 'Bearer load-key');
      expect(server.maxInFlight, greaterThan(1));
      // 40 veces 30 ms en serie serían 1.2 s. Con concurrencia cabe en menos.
      expect(elapsed.inMilliseconds, lessThan(1200));
    },
  );
}
