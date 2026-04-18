import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:prep_up/core/config/app_config.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_feedback_model.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/l10n/app_localizations.dart';

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
  GeminiService({http.Client? httpClient, String? apiKey, String? model})
    : _httpClient = httpClient ?? http.Client(),
      _apiKey = (apiKey ?? AppConfig.geminiApiKey).trim(),
      _model = _normalizeModelName((model ?? AppConfig.geminiModel).trim());

  final http.Client _httpClient;
  final String _apiKey;
  final String _model;

  static final Map<String, String> _resolvedModelByApiKey = {};

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

    final resolved = _resolvedModelByApiKey[_apiKey];
    final baseModel = resolved == null ? _model : _normalizeModelName(resolved);
    final modelsToTry = _modelsToTry(baseModel);

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
      GeminiException? lastModelError;
      for (final model in modelsToTry) {
        try {
          return await _sendPromptOnce(model: model, body: body);
        } on GeminiException catch (e) {
          lastModelError = e;
          if (e.statusCode == 404) continue;
          rethrow;
        }
      }
      if (lastModelError?.statusCode == 404) {
        final discovered = await _discoverBestModel();
        if (discovered != null) {
          _resolvedModelByApiKey[_apiKey] = discovered;
          return await _sendPromptOnce(model: discovered, body: body);
        }
      }
      if (lastModelError != null) throw lastModelError;
      throw const GeminiException('No se pudo contactar a Gemini.');
    } on http.ClientException catch (e) {
      throw GeminiException(
        'No hay conexión a internet o no se pudo contactar a Gemini.',
        details: e,
      );
    } on FormatException catch (e) {
      throw GeminiException(
        'Error al parsear respuesta de Gemini.',
        details: e,
      );
    }
  }

  Future<String> _sendPromptOnce({
    required String model,
    required Map<String, dynamic> body,
  }) async {
    final uri = AppConfig.geminiGenerateContentUri(
      model: _normalizeModelName(model),
      apiKey: _apiKey,
    );

    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final responseBody = response.body;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _tryExtractApiErrorMessage(responseBody) ??
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
  }

  Future<String?> _discoverBestModel() async {
    try {
      final uri = AppConfig.geminiListModelsUri(apiKey: _apiKey);
      final response = await _httpClient.get(uri);
      final responseBody = response.body;

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;
      final models = decoded['models'];
      if (models is! List) return null;

      final available = <_GeminiModelInfo>[];
      for (final item in models) {
        if (item is! Map) continue;
        final name = item['name'];
        if (name is! String || name.trim().isEmpty) continue;
        final supported = item['supportedGenerationMethods'];
        final methods = supported is List
            ? supported.whereType<String>().map((e) => e.trim()).toList()
            : const <String>[];
        if (!methods.contains('generateContent')) continue;
        available.add(
          _GeminiModelInfo(
            name: _normalizeModelName(name),
            supportedMethods: methods,
          ),
        );
      }

      if (available.isEmpty) return null;

      final preferences = <String>[
        _normalizeModelName(_model),
        'gemini-2.0-flash',
        'gemini-2.0-flash-lite',
        'gemini-2.0-flash-exp',
        'gemini-1.5-flash-latest',
        'gemini-1.5-flash',
        'gemini-flash-latest',
        'gemini-flash',
        'gemini-1.5-pro-latest',
        'gemini-1.5-pro',
      ];

      for (final pref in preferences) {
        final match = available.where((m) => m.name == pref).toList();
        if (match.isNotEmpty) return match.first.name;
      }

      return available.first.name;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> generateInterviewQuestions({
    required InterviewType type,
    required String jobRole,
    required int count,
    String language = 'es',
  }) async {
    final isEnglish = language.toLowerCase().startsWith('en');
    final safeCount = count <= 0 ? 5 : count;
    final typeLabel = switch (type) {
      InterviewType.behavioral => isEnglish ? 'behavioral' : 'conductual',
      InterviewType.technical => isEnglish ? 'technical' : 'técnica',
      InterviewType.mixed => isEnglish ? 'mixed' : 'mixta',
    };

    final systemInstruction = isEnglish
        ? 'You are an expert interviewer. Reply in English. '
              'When asked for JSON, return JSON only with no extra text.'
        : 'Eres un entrevistador experto. Respondes en $language. '
              'Cuando te pidan JSON, devuélvelo sin texto adicional.';

    final prompt = isEnglish
        ? '''
Generate $safeCount $typeLabel interview questions for the role: "$jobRole".
Return ONLY JSON with this exact schema:
{"questions":["...","..."]}
Requirements:
- Questions must be clear and specific
- No numbering in the question text
- No markdown
'''
        : '''
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
      final questions = questionsRaw
          .whereType<String>()
          .map((e) => e.trim())
          .toList();
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
    final isEnglish = language.toLowerCase().startsWith('en');
    final typeLabel = switch (type) {
      InterviewType.behavioral => isEnglish ? 'behavioral' : 'conductual',
      InterviewType.technical => isEnglish ? 'technical' : 'técnica',
      InterviewType.mixed => isEnglish ? 'mixed' : 'mixta',
    };

    final systemInstruction = isEnglish
        ? 'You are an expert interviewer. Reply in English. '
              'When asked for JSON, return JSON only with no extra text.'
        : 'Eres un entrevistador experto. Respondes en $language. '
              'Cuando te pidan JSON, devuélvelo sin texto adicional.';

    final prompt = isEnglish
        ? '''
Evaluate the user's answer for a $typeLabel interview for the "$jobRole" role.
Question: "$question"
User answer: "$userAnswer"

Return ONLY JSON with this exact schema:
{
  "overallScore": 0,
  "strengths": ["..."],
  "improvements": ["..."],
  "suggestedAnswer": "...",
  "followUpQuestions": ["..."]
}

Rules:
- overallScore must be an integer 0..100
- strengths/improvements: 2 to 5 items each
- suggestedAnswer: concise, improved, and results-oriented
- followUpQuestions: 0 to 3 questions
- No markdown
'''
        : '''
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
    final isEnglish = language.toLowerCase().startsWith('en');
    final systemInstruction = isEnglish
        ? 'You are an interview coach. Reply in English. '
              'When asked for JSON, return JSON only with no extra text.'
        : 'Eres un coach de entrevistas. Respondes en $language. '
              'Cuando te pidan JSON, devuélvelo sin texto adicional.';

    final prompt = isEnglish
        ? '''
Based on the question, the user's answer, and the evaluation, generate actionable feedback.
Question: "$question"
User answer: "$userAnswer"
Evaluation (JSON): ${jsonEncode(evaluation.toJson())}

Return ONLY JSON with this exact schema:
{
  "summary": "...",
  "actionItems": ["..."],
  "keyPhrasesToUse": ["..."]
}

Rules:
- summary: max 3 sentences
- actionItems: 3 to 6 actionable items
- keyPhrasesToUse: 3 to 8 short phrases the user can use
- No markdown
'''
        : '''
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

  Future<InterviewSession> analyzeInterviewSession({
    required InterviewConfig config,
    required InterviewSession session,
    String language = 'es',
  }) async {
    final isEnglish = language.toLowerCase().startsWith('en');
    final l10n = lookupAppLocalizations(Locale(isEnglish ? 'en' : 'es'));
    if (session.turns.isEmpty) {
      throw GeminiException(l10n.processingNotEnoughData);
    }

    final jobRole = config.jobRole == null ? '' : config.jobRole!.label(l10n);
    final type = _mapType(config.type ?? InterviewConfigType.mixed);
    final analyzedTurns = <InterviewTurn>[];

    for (final turn in session.turns) {
      final evaluation = await evaluateUserAnswer(
        question: turn.question,
        userAnswer: turn.answer,
        jobRole: jobRole,
        type: type,
        language: language,
      );

      final feedback = await generateFeedback(
        question: turn.question,
        userAnswer: turn.answer,
        evaluation: evaluation,
        language: language,
      );

      analyzedTurns.add(
        turn.copyWith(
          evaluation: evaluation,
          feedback: feedback,
        ),
      );
    }

    return session.copyWith(turns: analyzedTurns);
  }

  Future<InterviewResultsModel> generateInterviewResults({
    required InterviewConfig config,
    required InterviewSession session,
    String language = 'es',
  }) async {
    final isEnglish = language.toLowerCase().startsWith('en');
    final l10n = lookupAppLocalizations(Locale(isEnglish ? 'en' : 'es'));
    if (session.turns.isEmpty) {
      throw GeminiException(l10n.processingNotEnoughData);
    }

    final total = session.turns.fold<int>(
      0,
      (sum, t) => sum + t.evaluation.overallScore,
    );
    final overallScore = (total / session.turns.length).round().clamp(0, 100);
    final outcome = overallScore >= 70
        ? InterviewOutcome.approved
        : InterviewOutcome.improve;

    final history = _formatTurnsForResults(session.turns);

    final jobRole = config.jobRole == null ? '' : config.jobRole!.label(l10n);
    final type = config.type == null
        ? l10n.interviewTypeMixed
        : config.type!.label(l10n);
    final systemInstruction = isEnglish
        ? 'You are a senior interviewer. Reply in English. '
              'Return valid JSON only with no extra text.'
        : 'Eres un entrevistador senior. Respondes en $language. '
              'Devuelve JSON válido sin texto adicional.';

    final prompt = isEnglish
        ? '''
Generate an interview results report based on the real session history.
Role: "$jobRole"
Interview type: "$type"

OverallScore (calculated): $overallScore
Expected outcome (rule): ${outcome == InterviewOutcome.approved ? 'approved' : 'improve'}

History:
$history

Return ONLY JSON with this exact schema:
{
  "overallScore": $overallScore,
  "outcome": "${outcome == InterviewOutcome.approved ? 'approved' : 'improve'}",
  "breakdown": {
    "communication": 0,
    "technicalKnowledge": 0,
    "confidence": 0
  },
  "highlights": ["..."],
  "personalizedFeedback": "...",
  "recommendations": ["..."],
  "improvementTips": ["..."]
}

Rules:
- overallScore must be exactly $overallScore
- outcome must be exactly "${outcome == InterviewOutcome.approved ? 'approved' : 'improve'}"
- breakdown values: integers 0..100
- highlights: 3 to 5 points based on the real history (not generic)
- personalizedFeedback: 3 to 6 sentences specific to the user
- recommendations: 4 to 8 concrete actions
- improvementTips: 3 to 6 practical and measurable tips
- No markdown
'''
        : '''
Genera un reporte de resultados de entrevista basado en el historial real.
Rol: "$jobRole"
Tipo: "$type"

OverallScore (calculado): $overallScore
Outcome esperado (regla): ${outcome == InterviewOutcome.approved ? 'approved' : 'improve'}

Historial:
$history

Devuelve SOLO JSON con este esquema exacto:
{
  "overallScore": $overallScore,
  "outcome": "${outcome == InterviewOutcome.approved ? 'approved' : 'improve'}",
  "breakdown": {
    "communication": 0,
    "technicalKnowledge": 0,
    "confidence": 0
  },
  "highlights": ["..."],
  "personalizedFeedback": "...",
  "recommendations": ["..."],
  "improvementTips": ["..."]
}

Reglas:
- overallScore debe ser exactamente $overallScore
- outcome debe ser exactamente "${outcome == InterviewOutcome.approved ? 'approved' : 'improve'}"
- breakdown: enteros 0..100
- highlights: 3 a 5 puntos, basados en el historial (no genéricos)
- personalizedFeedback: 3 a 6 frases, específico para el usuario
- recommendations: 4 a 8 acciones concretas
- improvementTips: 3 a 6 consejos prácticos y medibles
- Sin markdown
''';

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.4,
      maxOutputTokens: 1600,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded == null) {
      throw GeminiException(
        l10n.processingInvalidResponse,
        details: raw,
      );
    }

    final parsed = InterviewResultsModel.fromJson(decoded);
    return InterviewResultsModel(
      overallScore: overallScore,
      outcome: outcome,
      breakdown: parsed.breakdown,
      highlights: parsed.highlights,
      personalizedFeedback: parsed.personalizedFeedback,
      recommendations: parsed.recommendations,
      improvementTips: parsed.improvementTips,
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

String _normalizeModelName(String model) {
  final trimmed = model.trim();
  if (trimmed.startsWith('models/')) return trimmed.substring('models/'.length);
  if (trimmed == 'gemini-1.5-flash') return 'gemini-1.5-flash-latest';
  if (trimmed == 'gemini-1.5-pro') return 'gemini-1.5-pro-latest';
  return trimmed;
}

Iterable<String> _modelsToTry(String model) sync* {
  final normalized = _normalizeModelName(model);
  if (normalized.isNotEmpty) yield normalized;
  if (!normalized.endsWith('-latest')) {
    yield '$normalized-latest';
  }
  yield 'gemini-1.5-flash-latest';
  yield 'gemini-flash-latest';
}

class _GeminiModelInfo {
  const _GeminiModelInfo({required this.name, required this.supportedMethods});

  final String name;
  final List<String> supportedMethods;
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

String _formatTurnsForResults(List<InterviewTurn> turns) {
  final buffer = StringBuffer();
  for (var i = 0; i < turns.length; i++) {
    final t = turns[i];
    buffer.writeln('Turno ${i + 1}:');
    buffer.writeln('Pregunta: ${t.question}');
    buffer.writeln('Respuesta: ${t.answer}');
    buffer.writeln('Score: ${t.evaluation.overallScore}');
    if (t.evaluation.strengths.isNotEmpty) {
      buffer.writeln('Fortalezas: ${t.evaluation.strengths.join(' | ')}');
    }
    if (t.evaluation.improvements.isNotEmpty) {
      buffer.writeln('Mejoras: ${t.evaluation.improvements.join(' | ')}');
    }
    if (t.feedback.summary.trim().isNotEmpty) {
      buffer.writeln('Feedback: ${t.feedback.summary.trim()}');
    }
    buffer.writeln('');
  }
  return buffer.toString().trim();
}

InterviewType _mapType(InterviewConfigType type) {
  return switch (type) {
    InterviewConfigType.technical => InterviewType.technical,
    InterviewConfigType.rrhh => InterviewType.behavioral,
    InterviewConfigType.mixed => InterviewType.mixed,
  };
}
