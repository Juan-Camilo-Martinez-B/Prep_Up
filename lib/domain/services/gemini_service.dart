import 'dart:convert';
import 'dart:math' as math;

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
import 'package:prep_up/core/utils/ai_utils.dart';

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

  /// Obtiene una lista aleatoria de temas de enfoque localizados.
  List<String> getRandomFocusAreas(AppLocalizations l10n, [int count = 5]) {
    final focusAreas = [
      l10n.aiFocusArea_edgeCases,
      l10n.aiFocusArea_performance,
      l10n.aiFocusArea_security,
      l10n.aiFocusArea_dbDesign,
      l10n.aiFocusArea_designPatterns,
      l10n.aiFocusArea_errorHandling,
      l10n.aiFocusArea_legacyCode,
      l10n.aiFocusArea_eventDriven,
      l10n.aiFocusArea_testing,
      l10n.aiFocusArea_troubleshooting,
      l10n.aiFocusArea_apiDesign,
      l10n.aiFocusArea_stateManagement,
      l10n.aiFocusArea_iac,
      l10n.aiFocusArea_observability,
      l10n.aiFocusArea_dataPrivacy,
      l10n.aiFocusArea_network,
      l10n.aiFocusArea_algorithms,
      l10n.aiFocusArea_memory,
      l10n.aiFocusArea_caching,
      l10n.aiFocusArea_messaging,
      l10n.aiFocusArea_auth,
      l10n.aiFocusArea_sqlOpt,
      l10n.aiFocusArea_consistency,
      l10n.aiFocusArea_serverless,
      l10n.aiFocusArea_containers,
      l10n.aiFocusArea_websockets,
      l10n.aiFocusArea_apiComparison,
      l10n.aiFocusArea_idempotency,
      l10n.aiFocusArea_zeroDowntime,
      l10n.aiFocusArea_bigData,
      l10n.aiFocusArea_tls,
      l10n.aiFocusArea_distributed,
      l10n.aiFocusArea_cleanArch,
      l10n.aiFocusArea_packaging,
      l10n.aiFocusArea_maintenance,
    ];
    final random = math.Random();
    final list = List<String>.from(focusAreas)..shuffle(random);
    return list.take(count).toList();
  }

  /// Genera las instrucciones de variedad para el prompt basándose en los temas seleccionados.
  String getVarietyInstructions(
    AppLocalizations l10n,
    List<String> selectedFocus,
  ) {
    final focusText = selectedFocus.join(', ');
    return l10n.aiPromptVarietyInstructions(focusText);
  }

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
    required AppLocalizations l10n,
    List<String>? selectedFocus,
  }) async {
    final safeCount = count <= 0 ? 5 : count;
    final typeLabel = type.label(l10n);

    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);

    final seed = DateTime.now().millisecondsSinceEpoch;
    final focus = selectedFocus ?? getRandomFocusAreas(l10n, 5);
    final varietyInstructions = getVarietyInstructions(l10n, focus);

    const jsonSchema = '{"questions":["...","..."]}';
    final prompt = l10n.aiPromptQuestionGen(
      safeCount,
      typeLabel,
      jobRole,
      varietyInstructions,
      seed,
      jsonSchema,
    );

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
    required AppLocalizations l10n,
    InterviewType type = InterviewType.mixed,
  }) async {
    final typeLabel = type.label(l10n);
    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);

    final seed = DateTime.now().millisecondsSinceEpoch;
    const jsonSchema =
        '{"overallScore": 0, "subjectMastery": 0, "strengths": ["..."], "improvements": ["..."], "suggestedAnswer": "...", "followUpQuestions": ["..."]}';
    final prompt = l10n.aiPromptEvaluation(
      typeLabel,
      jobRole,
      question,
      userAnswer,
      seed,
      jsonSchema,
    );

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.6,
      maxOutputTokens: 1200,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded != null) return AnswerEvaluationModel.fromJson(decoded);

    return AnswerEvaluationModel(
      overallScore: 0,
      subjectMastery: 0,
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
    required AppLocalizations l10n,
  }) async {
    final systemInstruction = l10n.aiPromptSystemCoach(l10n.localeName);

    const jsonSchema =
        '{"summary": "...", "actionItems": ["..."], "keyPhrasesToUse": ["..."]}';
    final prompt = l10n.aiPromptFeedback(
      question,
      userAnswer,
      jsonEncode(evaluation.toJson()),
      jsonSchema,
    );

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.5,
      maxOutputTokens: 1200,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded != null) return InterviewFeedbackModel.fromJson(decoded);

    return InterviewFeedbackModel(
      summary: AiUtils.sanitizeAIText(raw, l10n),
      actionItems: const [],
      keyPhrasesToUse: const [],
    );
  }

  Future<InterviewSession> analyzeInterviewSession({
    required InterviewConfig config,
    required InterviewSession session,
    required AppLocalizations l10n,
  }) async {
    if (session.turns.isEmpty) {
      throw GeminiException(l10n.processingNotEnoughData);
    }

    final jobRole = config.jobRole == null ? '' : config.jobRole!.label(l10n);
    final type = config.type ?? InterviewType.mixed;

    final analyzedTurns = await Future.wait(
      session.turns.map((turn) async {
        final evaluation = await evaluateUserAnswer(
          question: turn.question,
          userAnswer: turn.answer,
          jobRole: jobRole,
          type: type,
          l10n: l10n,
        );

        final feedback = await generateFeedback(
          question: turn.question,
          userAnswer: turn.answer,
          evaluation: evaluation,
          l10n: l10n,
        );

        return turn.copyWith(evaluation: evaluation, feedback: feedback);
      }),
    );

    return session.copyWith(turns: analyzedTurns);
  }

  Future<String> generateNextQuestion({
    required String jobRole,
    required InterviewType type,
    required List<InterviewTurn> turns,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  }) async {
    final typeLabel = type.label(l10n);
    final history = formatTurnsForHistory(turns, l10n);
    final varietyInstructions = getVarietyInstructions(l10n, selectedFocus);

    final prompt = l10n.aiPromptNextQuestion(
      jobRole,
      typeLabel,
      history,
      varietyInstructions,
    );

    final next = await sendPrompt(
      prompt: prompt,
      systemInstruction: l10n.aiPromptSystemInterviewer(l10n.localeName),
      temperature: 0.8,
      maxOutputTokens: 1025,
    );

    return next.trim();
  }

  Future<String> generateClosingMessage({
    required String jobRole,
    required AppLocalizations l10n,
  }) async {
    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);
    final prompt = l10n.aiPromptClosing(jobRole);

    final closing = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.7,
      maxOutputTokens: 512,
    );

    return closing.trim();
  }

  Future<String> generateOpeningQuestion({
    required String jobRole,
    required InterviewType type,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  }) async {
    final typeLabel = type.label(l10n);
    final varietyInstructions = getVarietyInstructions(l10n, selectedFocus);

    final prompt = l10n.aiPromptOpening(
      jobRole,
      typeLabel,
      varietyInstructions,
    );

    final response = await sendPrompt(
      prompt: prompt,
      systemInstruction: l10n.aiPromptSystemInterviewer(l10n.localeName),
      temperature: 0.7,
      maxOutputTokens: 1024,
    );

    return response.trim();
  }

  Future<String> generateConversationalNextQuestion({
    required String jobRole,
    required InterviewType type,
    required String lastQuestion,
    required String lastAnswer,
    required List<InterviewTurn> turns,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  }) async {
    final typeLabel = type.label(l10n);
    final history = formatTurnsForHistory(turns, l10n);
    final varietyInstructions = getVarietyInstructions(l10n, selectedFocus);

    final prompt = l10n.aiPromptConversationalNext(
      jobRole,
      typeLabel,
      lastQuestion,
      lastAnswer,
      varietyInstructions,
      history,
    );

    final next = await sendPrompt(
      prompt: prompt,
      systemInstruction: l10n.aiPromptSystemInterviewer(l10n.localeName),
      temperature: 0.65,
      maxOutputTokens: 1024,
    );

    return next.trim();
  }

  Future<String> generateAlternativeQuestion({
    required String jobRole,
    required InterviewType type,
    required String currentQuestion,
    required List<InterviewTurn> turns,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  }) async {
    final typeLabel = type.label(l10n);
    final history = formatTurnsForHistory(turns, l10n);
    final varietyInstructions = getVarietyInstructions(l10n, selectedFocus);

    final prompt = l10n.aiPromptAlternative(
      jobRole,
      typeLabel,
      currentQuestion,
      history,
      varietyInstructions,
    );

    final next = await sendPrompt(
      prompt: prompt,
      systemInstruction: l10n.aiPromptSystemInterviewer(l10n.localeName),
      temperature: 0.85,
      maxOutputTokens: 512,
    );

    return next.trim();
  }

  String formatTurnsForHistory(
    List<InterviewTurn> turns,
    AppLocalizations l10n,
  ) {
    if (turns.isEmpty) return '- (no history)';
    final buffer = StringBuffer();
    for (var i = 0; i < turns.length; i++) {
      final t = turns[i];
      buffer.writeln('${l10n.statsBarScoreTitle} ${i + 1}:');
      buffer.writeln('Q: ${t.question}');
      buffer.writeln('A: ${t.answer}');
      buffer.writeln('Score: ${t.evaluation.overallScore}');
      if (t.evaluation.improvements.isNotEmpty) {
        buffer.writeln(
          'Improvements: ${t.evaluation.improvements.join(' | ')}',
        );
      }
      buffer.writeln('');
    }
    return buffer.toString().trim();
  }

  Future<InterviewResultsModel> generateInterviewResults({
    required InterviewConfig config,
    required InterviewSession session,
    required AppLocalizations l10n,
  }) async {
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

    final history = formatTurnsForHistory(session.turns, l10n);

    final jobRole = config.jobRole == null ? '' : config.jobRole!.label(l10n);
    final typeLabel = config.type == null
        ? l10n.interviewTypeMixed
        : config.type!.label(l10n);

    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);

    const jsonSchema =
        '{"overallScore": 0, "outcome": "...", "breakdown": {"communication": 75, "technicalKnowledge": 70, "confidence": 72}, "highlights": ["..."], "personalizedFeedback": "...", "recommendations": ["..."], "improvementTips": ["..."]}';
    final prompt = l10n.aiPromptResultsAnalysis(
      jobRole,
      typeLabel,
      overallScore,
      outcome == InterviewOutcome.approved ? 'approved' : 'improve',
      history,
      jsonSchema,
    );

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.2,
      maxOutputTokens: 1200,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));

    // Graceful fallback: build results from locally-computed data if Gemini
    // doesn't return parseable JSON (network hiccup, model refusal, etc.).
    if (decoded == null) {
      final avgScore = session.turns.isEmpty
          ? overallScore
          : (session.turns.fold<int>(
                      0,
                      (s, t) => s + t.evaluation.overallScore,
                    ) /
                    session.turns.length)
                .round();
      return InterviewResultsModel(
        id: '',
        sessionId: '',
        userId: '',
        analyzedAt: DateTime.now().toUtc(),
        overallScore: overallScore,
        outcome: outcome,
        breakdown: InterviewResultsBreakdownModel(
          communication: avgScore,
          technicalKnowledge: avgScore,
          confidence: avgScore,
          subjectMastery: avgScore,
        ),
        highlights: const [],
        personalizedFeedback: AiUtils.sanitizeAIText(raw, l10n),
        recommendations: const [],
        improvementTips: const [],
        averageResponseSeconds: 0,
        totalResponseSeconds: 0,
        validAnswersCount: session.turns.length,
      );
    }

    final totalResponseSeconds = session.turns.fold<int>(
      0,
      (sum, t) => sum + t.responseDurationSeconds,
    );
    final averageResponseSeconds = session.turns.isEmpty
        ? 0
        : (totalResponseSeconds / session.turns.length).round();

    final validAnswersCount = session.turns.where((t) {
      final text = t.answer.trim().toLowerCase();
      if (text.isEmpty) return false;
      if (text == 'no sé' || text == 'no se' || text == 'i don\'t know')
        return false;
      if (text.length < 5) return false; // Basic heuristic
      return true;
    }).length;

    final totalSubjectMastery = session.turns.fold<int>(
      0,
      (sum, t) => sum + t.evaluation.subjectMastery,
    );
    final avgSubjectMastery = session.turns.isEmpty
        ? 0
        : (totalSubjectMastery / session.turns.length).round();

    final parsed = InterviewResultsModel.fromJson(decoded);
    return InterviewResultsModel(
      id: '',
      sessionId: '',
      userId: '',
      analyzedAt: DateTime.now().toUtc(),
      overallScore: overallScore,
      outcome: outcome,
      breakdown: parsed.breakdown.copyWith(
        technicalKnowledge: avgSubjectMastery,
        subjectMastery: avgSubjectMastery,
      ),
      highlights: (decoded['highlights'] as List?)?.cast<String>() ?? const [],
      personalizedFeedback: AiUtils.sanitizeAIText(
        (decoded['personalizedFeedback'] as String?) ?? raw,
        l10n,
      ),
      recommendations: parsed.recommendations,
      improvementTips: parsed.improvementTips,
      averageResponseSeconds: averageResponseSeconds,
      totalResponseSeconds: totalResponseSeconds,
      validAnswersCount: validAnswersCount,
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
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String _extractJsonText(String raw) {
  var trimmed = raw.trim();

  // Try to find markdown code block first
  final fenceStart = trimmed.indexOf('```');
  if (fenceStart != -1) {
    final fenceEnd = trimmed.lastIndexOf('```');
    if (fenceEnd != -1 && fenceEnd > fenceStart) {
      final inside = trimmed.substring(fenceStart + 3, fenceEnd).trim();
      final firstNewline = inside.indexOf('\n');
      if (firstNewline != -1) {
        final firstLine = inside
            .substring(0, firstNewline)
            .trim()
            .toLowerCase();
        if (firstLine == 'json') {
          trimmed = inside.substring(firstNewline + 1).trim();
        } else {
          trimmed = inside.trim();
        }
      } else {
        trimmed = inside.trim();
      }
    }
  }

  // Find the first '{' and last '}' to isolate the JSON object
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return trimmed.substring(start, end + 1);
  }

  return trimmed;
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
    final wordCount = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (wordCount < 3) continue;
    final value = normalized.trim();
    if (value.isNotEmpty) cleaned.add(value);
  }
  return cleaned;
}
