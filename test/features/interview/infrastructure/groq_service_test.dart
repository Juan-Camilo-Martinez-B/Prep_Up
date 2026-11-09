import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prep_up/features/interview/domain/ai_provider_exception.dart';
import 'package:prep_up/features/interview/infrastructure/groq_service.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:prep_up/shared/domain/entities/interview_tags.dart';

/// Respuesta de chat completions con el formato que devuelve Groq.
http.Response _chatResponse(String content, {String finishReason = 'stop'}) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'choices': [
          {
            'index': 0,
            'message': {'role': 'assistant', 'content': content},
            'finish_reason': finishReason,
          },
        ],
      }),
    ),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

http.Response _errorResponse(int statusCode, String message) {
  return http.Response(
    jsonEncode({
      'error': {'message': message, 'type': 'invalid_request_error'},
    }),
    statusCode,
  );
}

GroqService _service(
  MockClientHandler handler, {
  String apiKey = 'test-key',
  String model = 'openai/gpt-oss-120b',
  String? reasoningEffort = 'low',
}) {
  return GroqService(
    httpClient: MockClient(handler),
    apiKey: apiKey,
    model: model,
    reasoningEffort: reasoningEffort,
  );
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    // GroqService lee AppConfig cuando un parametro llega nulo; sin cargar
    // dotenv, flutter_dotenv lanza NotInitializedError.
    dotenv.testLoad(fileInput: '');
    l10n = lookupAppLocalizations(const Locale('es'));
  });

  group('GroqService.sendPrompt', () {
    test('envia la peticion con el formato de Groq', () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return _chatResponse('hola');
      });

      final result = await service.sendPrompt(
        prompt: 'pregunta',
        systemInstruction: '  eres un entrevistador  ',
        temperature: 0.4,
        maxOutputTokens: 500,
      );

      expect(result, 'hola');
      expect(captured.method, 'POST');
      expect(
        captured.url.toString(),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(captured.headers['Authorization'], 'Bearer test-key');
      expect(captured.url.queryParameters, isEmpty);

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'openai/gpt-oss-120b');
      expect(body['temperature'], 0.4);
      expect(body['reasoning_effort'], 'low');
      // El presupuesto de razonamiento se suma al limite pedido.
      expect(body['max_completion_tokens'], greaterThan(500));
      expect(body['messages'], [
        {'role': 'system', 'content': 'eres un entrevistador'},
        {'role': 'user', 'content': 'pregunta'},
      ]);
    });

    test('un modelo sin razonamiento no recibe reasoning_effort', () async {
      late Map<String, dynamic> body;
      final service = _service(
        (request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _chatResponse('ok');
        },
        model: 'llama-3.3-70b-versatile',
        reasoningEffort: null,
      );

      await service.sendPrompt(prompt: 'p', maxOutputTokens: 300);

      expect(body['model'], 'llama-3.3-70b-versatile');
      expect(body.containsKey('reasoning_effort'), isFalse);
      expect(body['max_completion_tokens'], 300);
    });

    test('gpt-oss usa reasoning_effort low por defecto', () async {
      late Map<String, dynamic> body;
      final service = _service((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _chatResponse('ok');
      }, reasoningEffort: null);

      await service.sendPrompt(prompt: 'p');

      expect(body['reasoning_effort'], 'low');
    });

    test('omite el mensaje system cuando viene vacio', () async {
      late Map<String, dynamic> body;
      final service = _service((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _chatResponse('ok');
      });

      await service.sendPrompt(prompt: 'p', systemInstruction: '   ');

      expect(body['messages'], [
        {'role': 'user', 'content': 'p'},
      ]);
    });

    test('decodifica tildes y enies en UTF-8', () async {
      final service = _service(
        (_) async => _chatResponse('¿Cómo diseñarías la caché?'),
      );

      expect(
        await service.sendPrompt(prompt: 'p'),
        '¿Cómo diseñarías la caché?',
      );
    });

    test('falla sin llamar a la red si falta la API key', () async {
      var calls = 0;
      final service = _service((_) async {
        calls++;
        return _chatResponse('no deberia llegar');
      }, apiKey: '  ');

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            contains('GROQ_API_KEY'),
          ),
        ),
      );
      expect(calls, 0);
    });

    test('propaga el mensaje y el status de un error de la API', () async {
      final service = _service(
        (_) async => _errorResponse(401, 'Invalid API Key'),
      );

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(
          isA<AiProviderException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Invalid API Key'),
        ),
      );
    });

    test('usa un mensaje generico si el error no trae cuerpo JSON', () async {
      final service = _service((_) async => http.Response('Bad Gateway', 502));

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(
          isA<AiProviderException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.message, 'message', 'Error al llamar a Groq.'),
        ),
      );
    });

    test('avisa cuando se agota el limite de tokens', () async {
      final service = _service(
        (_) async => _chatResponse('', finishReason: 'length'),
      );

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            contains('límite de tokens'),
          ),
        ),
      );
    });

    test('rechaza una respuesta sin choices', () async {
      final service = _service(
        (_) async => http.Response(jsonEncode({'choices': []}), 200),
      );

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(isA<AiProviderException>()),
      );
    });

    test('traduce un JSON invalido a AiProviderException', () async {
      final service = _service((_) async => http.Response('<html>', 200));

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(isA<AiProviderException>()),
      );
    });

    test('traduce un fallo de red a AiProviderException', () async {
      final service = _service(
        (_) async => throw http.ClientException('sin red'),
      );

      await expectLater(
        service.sendPrompt(prompt: 'p'),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            contains('internet'),
          ),
        ),
      );
    });
  });

  group('GroqService sobre respuestas del modelo', () {
    test(
      'generateInterviewQuestions lee el JSON aunque venga en markdown',
      () async {
        final service = _service(
          (_) async => _chatResponse(
            '```json\n{"questions": ["Pregunta uno larga", "Pregunta dos larga", "Pregunta tres larga"]}\n```',
          ),
        );

        final questions = await service.generateInterviewQuestions(
          type: InterviewType.technical,
          role: JobRole.mobileDeveloper,
          jobRoleLabel: 'Desarrollador móvil',
          count: 2,
          l10n: l10n,
          selectedFocus: const ['testing'],
        );

        expect(questions, ['Pregunta uno larga', 'Pregunta dos larga']);
      },
    );

    test(
      'generateInterviewQuestions usa el texto plano si no hay JSON',
      () async {
        final service = _service(
          (_) async => _chatResponse(
            '1. Explica el ciclo de vida de un widget\n2. Como manejas el estado global',
          ),
        );

        final questions = await service.generateInterviewQuestions(
          type: InterviewType.technical,
          role: null,
          jobRoleLabel: 'Flutter',
          count: 5,
          l10n: l10n,
          selectedFocus: const ['testing'],
        );

        expect(questions, [
          'Explica el ciclo de vida de un widget',
          'Como manejas el estado global',
        ]);
      },
    );

    test('evaluateUserAnswer convierte el JSON en el modelo', () async {
      final service = _service(
        (_) async => _chatResponse(
          jsonEncode({
            'overallScore': 85,
            'subjectMastery': 80,
            'strengths': ['Claridad'],
            'improvements': ['Dar un ejemplo'],
            'suggestedAnswer': 'Usaria Provider.',
            'followUpQuestions': ['Y con Riverpod?'],
          }),
        ),
      );

      final evaluation = await service.evaluateUserAnswer(
        question: 'Como manejas el estado?',
        userAnswer: 'Con Provider.',
        role: JobRole.mobileDeveloper,
        jobRoleLabel: 'Desarrollador móvil',
        l10n: l10n,
      );

      expect(evaluation.overallScore, 85);
      expect(evaluation.strengths, ['Claridad']);
      expect(evaluation.improvements, ['Dar un ejemplo']);
      expect(evaluation.followUpQuestions, ['Y con Riverpod?']);
    });

    test(
      'evaluateUserAnswer degrada a un modelo por defecto sin JSON',
      () async {
        final service = _service((_) async => _chatResponse('texto libre'));

        final evaluation = await service.evaluateUserAnswer(
          question: 'q',
          userAnswer: 'a',
          role: null,
          jobRoleLabel: 'Flutter',
          l10n: l10n,
        );

        expect(evaluation.overallScore, 0);
        expect(evaluation.suggestedAnswer, 'texto libre');
      },
    );
  });
}
