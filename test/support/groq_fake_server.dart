import 'dart:convert';
import 'dart:io';

/// Servidor HTTP local con la forma de `POST /openai/v1/chat/completions`.
/// Las pruebas de integración y de carga apuntan aquí. No llama a Groq.
class GroqFakeServer {
  GroqFakeServer._(this._server);

  final HttpServer _server;
  final List<String?> _authorizations = [];
  final List<Map<String, dynamic>> _bodies = [];
  int _inFlight = 0;
  int maxInFlight = 0;

  int get requestCount => _bodies.length;

  Uri get chatCompletionsUri => Uri.parse(
    'http://${_server.address.host}:${_server.port}/openai/v1/chat/completions',
  );

  String? authorizationOf(int index) => _authorizations[index];

  Map<String, dynamic> bodyOf(int index) => _bodies[index];

  static Future<GroqFakeServer> start({
    Duration delay = Duration.zero,
    int statusCode = 200,
    String content = 'respuesta local',
    String? errorMessage,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = GroqFakeServer._(server);
    server.listen((request) async {
      fake._inFlight++;
      if (fake._inFlight > fake.maxInFlight) {
        fake.maxInFlight = fake._inFlight;
      }
      try {
        final raw = await utf8.decoder.bind(request).join();
        fake._authorizations.add(
          request.headers.value(HttpHeaders.authorizationHeader),
        );
        fake._bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        request.response.statusCode = statusCode;
        request.response.headers.contentType = ContentType.json;
        final payload = statusCode >= 200 && statusCode < 300
            ? {
                'choices': [
                  {
                    'message': {'role': 'assistant', 'content': content},
                    'finish_reason': 'stop',
                  },
                ],
              }
            : {
                'error': {
                  'message': errorMessage ?? 'error local',
                  'type': 'invalid_request_error',
                },
              };
        request.response.write(jsonEncode(payload));
        await request.response.close();
      } finally {
        fake._inFlight--;
      }
    });
    return fake;
  }

  Future<void> close() => _server.close(force: true);
}
