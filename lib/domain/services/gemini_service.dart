import 'dart:convert';
import 'dart:io';

import 'package:prep_up/core/config/app_config.dart';
import 'package:prep_up/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/domain/entities/interview_feedback_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';

class GeminiException implements Exception {
  const GeminiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (statusCode: $statusCode)';
    return 'GeminiException$status: $message';
  }
}

class GeminiService {
  GeminiService({
    HttpClient? httpClient,
    String? apiKey,
    String? model,
  })  : _httpClient = httpClient ?? HttpClient(),
        _apiKey = (apiKey ?? AppConfig.geminiApiKey).trim(),
        _model = (model ?? AppConfig.geminiModel).trim();

  final HttpClient _httpClient;
  final String _apiKey;
  final String _model;

  Future<String> sendPrompt({
    required String prompt,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 1024,
  }) async {
    if (_apiKey.isEmpty) {
      throw const GeminiException(
        'Falta GEMINI_API_KEY. Configúrala en el archivo .env.',
      );
    }

    final uri = AppConfig.geminiGenerateContentUri(
      model: _model,
      apiKey: _apiKey,
    );

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      },
    };

    if (systemInstruction != null && systemInstruction.trim().isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction.trim()},
        ],
      };
    }

    try {
      final request = await _httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _tryExtractApiErrorMessage(responseBody) ??
            'Error al llamar a Gemini.';
        throw GeminiException(
          message,
          statusCode: response.statusCode,
          details: responseBody,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw GeminiException(
          'Respuesta inválida de Gemini.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw GeminiException(
          'Gemini no devolvió candidatos.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      final candidate = candidates.first;
      if (candidate is! Map) {
        throw GeminiException(
          'Candidato inválido en respuesta de Gemini.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      final content = candidate['content'];
      if (content is! Map) {
        throw GeminiException(
          'Contenido inválido en respuesta de Gemini.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        throw GeminiException(
          'Gemini devolvió una respuesta vacía.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          buffer.writeln(part['text'] as String);
        }
      }

      final text = buffer.toString().trim();
      if (text.isEmpty) {
        throw GeminiException(
          'Gemini devolvió una respuesta vacía.',
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      return text;
    } on SocketException catch (e) {
      throw GeminiException(
        'No hay conexión a internet o no se pudo contactar a Gemini.',
        details: e,
      );
    } on HttpException catch (e) {
      throw GeminiException('Error HTTP al contactar a Gemini.', details: e);
    } on FormatException catch (e) {
      throw GeminiException('Error al parsear respuesta de Gemini.', details: e);
    }
  }

  Future<List<String>> generateInterviewQuestions({
    required InterviewType type,
    required String jobRole,
    required int count,
    String language = 'es',
  }) async {
    final safeCount = count <= 0 ? 5 : count;
    final typeLabel = switch (type) {
      InterviewType.behavioral => 'conductual',
      InterviewType.technical => 'técnica',
      InterviewType.mixed => 'mixta',
    };

    final systemInstruction =
        'Eres un entrevistador experto. Respondes en $language. '
        'Cuando te pidan JSON, devuélvelo sin texto adicional.';

    final prompt = '''
Genera $safeCount preguntas de entrevista de tipo $typeLabel para el rol: "$jobRole".
Devuelve SOLO JSON con este esquema exacto:
{"questions":["...","..."]}
Requisitos:
- Preguntas claras y específicas
- Sin numeración en el texto
- Sin markdown
''';

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.8,
      maxOutputTokens: 1024,
    );

    final jsonText = _extractJsonText(raw);
    final decoded = _tryDecodeJsonMap(jsonText);
    final questionsRaw = decoded?['questions'];
    if (questionsRaw is List) {
      final questions =
          questionsRaw.whereType<String>().map((e) => e.trim()).toList();
      final filtered = questions.where((q) => q.isNotEmpty).toList();
      if (filtered.isNotEmpty) return filtered.take(safeCount).toList();
    }

    return _fallbackQuestionsFromText(raw).take(safeCount).toList();
  }

  Future<AnswerEvaluationModel> evaluateUserAnswer({
    required String question,
    required String userAnswer,
    required String jobRole,
    InterviewType type = InterviewType.mixed,
    String language = 'es',
  }) async {
    final typeLabel = switch (type) {
      InterviewType.behavioral => 'conductual',
      InterviewType.technical => 'técnica',
      InterviewType.mixed => 'mixta',
    };

    final systemInstruction =
        'Eres un entrevistador experto. Respondes en $language. '
        'Cuando te pidan JSON, devuélvelo sin texto adicional.';

    final prompt = '''
Evalúa la respuesta del usuario para una entrevista $typeLabel del rol "$jobRole".
Pregunta: "$question"
Respuesta del usuario: "$userAnswer"

Devuelve SOLO JSON con este esquema exacto:
{
  "overallScore": 0,
  "strengths": ["..."],
  "improvements": ["..."],
  "suggestedAnswer": "...",
  "followUpQuestions": ["..."]
}

Reglas:
- overallScore es entero 0..100
- strengths/improvements: 2 a 5 elementos cada uno
- suggestedAnswer: una versión mejorada, concisa, orientada a resultados
- followUpQuestions: 0 a 3 preguntas
- Sin markdown
''';

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.4,
      maxOutputTokens: 1200,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded != null) return AnswerEvaluationModel.fromJson(decoded);

    return AnswerEvaluationModel(
      overallScore: 0,
      strengths: const [],
      improvements: const [],
      suggestedAnswer: raw.trim(),
      followUpQuestions: const [],
    );
  }

  Future<InterviewFeedbackModel> generateFeedback({
    required String question,
    required String userAnswer,
    required AnswerEvaluationModel evaluation,
    String language = 'es',
  }) async {
    final systemInstruction =
        'Eres un coach de entrevistas. Respondes en $language. '
        'Cuando te pidan JSON, devuélvelo sin texto adicional.';

    final prompt = '''
Con base en la pregunta, la respuesta del usuario y la evaluación, genera retroalimentación accionable.
Pregunta: "$question"
Respuesta del usuario: "$userAnswer"
Evaluación (JSON): ${jsonEncode(evaluation.toJson())}

Devuelve SOLO JSON con este esquema exacto:
{
  "summary": "...",
  "actionItems": ["..."],
  "keyPhrasesToUse": ["..."]
}

Reglas:
- summary: máximo 3 frases
- actionItems: 3 a 6 puntos accionables
- keyPhrasesToUse: 3 a 8 frases cortas que el usuario podría usar
- Sin markdown
''';

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.5,
      maxOutputTokens: 1200,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded != null) return InterviewFeedbackModel.fromJson(decoded);

    return InterviewFeedbackModel(
      summary: raw.trim(),
      actionItems: const [],
      keyPhrasesToUse: const [],
    );
  }
}

String? _tryExtractApiErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map && error['message'] is String) {
        return (error['message'] as String).trim();
      }
    }
  } catch (_) {}
  return null;
}

Map<String, dynamic>? _tryDecodeJsonMap(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return null;
}

String _extractJsonText(String raw) {
  final trimmed = raw.trim();
  final fenceStart = trimmed.indexOf('```');
  if (fenceStart == -1) return trimmed;
  final fenceEnd = trimmed.lastIndexOf('```');
  if (fenceEnd == -1 || fenceEnd <= fenceStart) return trimmed;
  final inside = trimmed.substring(fenceStart + 3, fenceEnd).trim();
  final firstNewline = inside.indexOf('\n');
  if (firstNewline == -1) return inside.trim();
  final firstLine = inside.substring(0, firstNewline).trim().toLowerCase();
  final rest = inside.substring(firstNewline + 1).trim();
  if (firstLine == 'json') return rest;
  return inside.trim();
}

List<String> _fallbackQuestionsFromText(String raw) {
  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final cleaned = <String>[];
  for (final line in lines) {
    final normalized = line.replaceFirst(RegExp(r'^\d+[\).\-\s]+'), '');
    final value = normalized.trim();
    if (value.isNotEmpty) cleaned.add(value);
  }
  return cleaned;
}

