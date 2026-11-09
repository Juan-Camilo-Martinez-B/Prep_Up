import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:prep_up/core/config/app_config.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/features/interview/domain/ai_provider_exception.dart';
import 'package:prep_up/features/interview/domain/interview_ai_port.dart';
import 'package:prep_up/shared/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/shared/domain/entities/interview_config.dart';
import 'package:prep_up/shared/domain/entities/interview_feedback_model.dart';
import 'package:prep_up/shared/domain/entities/interview_results_model.dart';
import 'package:prep_up/shared/domain/entities/interview_session.dart';
import 'package:prep_up/shared/domain/entities/interview_tags.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:prep_up/core/utils/ai_utils.dart';

/// Adapter de [InterviewAiPort] sobre la API de Groq (compatible con OpenAI).
class GroqService implements InterviewAiPort {
  GroqService({
    http.Client? httpClient,
    String? apiKey,
    String? model,
    String? reasoningEffort,
  }) : this._resolved(
         httpClient: httpClient ?? http.Client(),
         apiKey: (apiKey ?? AppConfig.groqApiKey).trim(),
         model: (model ?? AppConfig.groqModel).trim(),
         reasoningEffort: reasoningEffort ?? AppConfig.groqReasoningEffort,
       );

  GroqService._resolved({
    required http.Client httpClient,
    required String apiKey,
    required String model,
    required String? reasoningEffort,
  }) : _httpClient = httpClient,
       _apiKey = apiKey,
       _model = model,
       // El valor por defecto depende del modelo efectivo, no del .env.
       _reasoningEffort =
           reasoningEffort ?? AppConfig.defaultReasoningEffortFor(model);

  /// Tokens extra para modelos de razonamiento: el razonamiento interno
  /// consume del mismo límite que la respuesta visible.
  static const int _reasoningTokenBudget = 1024;
  static const Duration _requestTimeout = Duration(seconds: 60);

  final http.Client _httpClient;
  final String _apiKey;
  final String _model;
  final String? _reasoningEffort;

  /// Obtiene una lista aleatoria de temas de enfoque localizados.
  @override
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

  @override
  Future<String> sendPrompt({
    required String prompt,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 1024,
  }) async {
    if (_apiKey.isEmpty) {
      throw const AiProviderException(
        'Falta GROQ_API_KEY. Configúrala en el archivo .env.',
      );
    }

    final messages = <Map<String, String>>[
      if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
        {'role': 'system', 'content': systemInstruction.trim()},
      {'role': 'user', 'content': prompt},
    ];

    final reasoningEffort = _reasoningEffort;
    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'temperature': temperature,
      'max_completion_tokens': reasoningEffort == null
          ? maxOutputTokens
          : maxOutputTokens + _reasoningTokenBudget,
      'reasoning_effort': ?reasoningEffort,
    };

    try {
      return await _postChatCompletion(body);
    } on http.ClientException catch (e) {
      throw AiProviderException(
        'No hay conexión a internet o no se pudo contactar a Groq.',
        details: e,
      );
    } on FormatException catch (e) {
      throw AiProviderException(
        'Error al interpretar la respuesta de Groq.',
        details: e,
      );
    }
  }

  Future<String> _postChatCompletion(Map<String, dynamic> body) async {
    final response = await _httpClient
        .post(
          AppConfig.groqChatCompletionsUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);
    final responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(
        _tryExtractApiErrorMessage(responseBody) ?? 'Error al llamar a Groq.',
        statusCode: response.statusCode,
        details: responseBody,
      );
    }

    final decoded = jsonDecode(responseBody);
    final choices = decoded is Map<String, dynamic> ? decoded['choices'] : null;
    final choice = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = choice is Map ? choice['message'] : null;
    final content = message is Map ? message['content'] : null;
    final text = content is String ? content.trim() : '';

    if (text.isEmpty) {
      final finishReason = choice is Map ? choice['finish_reason'] : null;
      throw AiProviderException(
        finishReason == 'length'
            ? 'Groq agotó el límite de tokens antes de responder.'
            : 'Groq devolvió una respuesta vacía.',
        statusCode: response.statusCode,
        details: decoded,
      );
    }

    return text;
  }

  @override
  Future<List<String>> generateInterviewQuestions({
    required InterviewType type,
    required JobRole? role,
    required String jobRoleLabel,
    required int count,
    required AppLocalizations l10n,
    List<String>? selectedFocus,
  }) async {
    final safeCount = count <= 0 ? 5 : count;
    final typeLabel = type.label(l10n);
    final roleContext = role?.roleContext(l10n) ?? '';

    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);

    final seed = DateTime.now().millisecondsSinceEpoch;
    final focus = selectedFocus ?? getRandomFocusAreas(l10n, 5);
    final varietyInstructions = getVarietyInstructions(l10n, focus);

    const jsonSchema = '{"questions":["...","..."]}';
    final prompt = l10n.aiPromptQuestionGen(
      safeCount,
      typeLabel,
      jobRoleLabel,
      roleContext,
      varietyInstructions,
      seed,
      jsonSchema,
    );

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.8,
      maxOutputTokens: 1536,
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

  @override
  Future<AnswerEvaluationModel> evaluateUserAnswer({
    required String question,
    required String userAnswer,
    required JobRole? role,
    required String jobRoleLabel,
    required AppLocalizations l10n,
    InterviewType type = InterviewType.mixed,
  }) async {
    final typeLabel = type.label(l10n);
    final roleContext = role?.roleContext(l10n) ?? '';
    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);

    final seed = DateTime.now().millisecondsSinceEpoch;
    const jsonSchema =
        '{"overallScore": 0, "subjectMastery": 0, "strengths": ["..."], "improvements": ["..."], "suggestedAnswer": "...", "followUpQuestions": ["..."]}';
    final prompt = l10n.aiPromptEvaluation(
      typeLabel,
      jobRoleLabel,
      roleContext,
      question,
      userAnswer,
      seed,
      jsonSchema,
    );

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.6,
      maxOutputTokens: 1536,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded != null) {
      final model = AnswerEvaluationModel.fromJson(decoded);
      // Asegurar que las listas no estén vacías si el score es bajo
      return model.copyWith(
        strengths: model.strengths.isEmpty
            ? const ['Respuesta procesada correctamente.']
            : model.strengths,
        improvements: model.improvements.isEmpty && model.overallScore < 80
            ? const [
                'Intenta profundizar un poco más en tus respuestas técnicas.',
              ]
            : model.improvements,
      );
    }

    return AnswerEvaluationModel(
      overallScore: 0,
      subjectMastery: 0,
      strengths: const ['Respuesta recibida.'],
      improvements: const [
        'No se pudo realizar un análisis detallado. Intenta ser más específico.',
      ],
      suggestedAnswer: raw.trim(),
      followUpQuestions: const [],
    );
  }

  @override
  Future<InterviewFeedbackModel> generateFeedback({
    required String question,
    required String userAnswer,
    required AnswerEvaluationModel evaluation,
    required JobRole? role,
    required String jobRoleLabel,
    required AppLocalizations l10n,
  }) async {
    final systemInstruction = l10n.aiPromptSystemCoach(l10n.localeName);
    final roleContext = role?.roleContext(l10n) ?? '';

    const jsonSchema =
        '{"summary": "...", "actionItems": ["..."], "keyPhrasesToUse": ["..."]}';
    final prompt = l10n.aiPromptFeedback(
      jobRoleLabel,
      roleContext,
      question,
      userAnswer,
      jsonEncode(evaluation.toJson()),
      jsonSchema,
    );

    final raw = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.5,
      maxOutputTokens: 1536,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));
    if (decoded != null) {
      final model = InterviewFeedbackModel.fromJson(decoded);
      return model.copyWith(
        actionItems: model.actionItems.isEmpty
            ? const [
                'Repasa los puntos clave de esta pregunta.',
                'Practica tu explicación en voz alta.',
              ]
            : model.actionItems,
        keyPhrasesToUse: model.keyPhrasesToUse.isEmpty
            ? const [
                'En mi experiencia...',
                'Un ejemplo concreto es...',
                'Lo más importante en este caso es...',
              ]
            : model.keyPhrasesToUse,
      );
    }

    return InterviewFeedbackModel(
      summary: AiUtils.sanitizeAIText(raw, l10n),
      actionItems: const [
        'Repasa los fundamentos técnicos de esta área.',
        'Intenta estructurar mejor tu respuesta la próxima vez.',
        'Usa ejemplos de tus proyectos anteriores.',
      ],
      keyPhrasesToUse: const [
        'He trabajado con...',
        'Una de las mejores prácticas es...',
        'En un escenario similar...',
      ],
    );
  }

  @override
  Future<InterviewSession> analyzeInterviewSession({
    required InterviewConfig config,
    required InterviewSession session,
    required AppLocalizations l10n,
  }) async {
    if (session.turns.isEmpty) {
      throw AiProviderException(l10n.processingNotEnoughData);
    }

    final jobRoleLabel = config.jobRole == null
        ? ''
        : config.jobRole!.label(l10n);
    final jobRole = config.jobRole;
    final type = config.type ?? InterviewType.mixed;

    final analyzedTurns = await Future.wait(
      session.turns.map((turn) async {
        final evaluation = await evaluateUserAnswer(
          question: turn.question,
          userAnswer: turn.answer,
          role: jobRole,
          jobRoleLabel: jobRoleLabel,
          type: type,
          l10n: l10n,
        );

        final feedback = await generateFeedback(
          question: turn.question,
          userAnswer: turn.answer,
          evaluation: evaluation,
          role: jobRole,
          jobRoleLabel: jobRoleLabel,
          l10n: l10n,
        );

        return turn.copyWith(evaluation: evaluation, feedback: feedback);
      }),
    );

    return session.copyWith(turns: analyzedTurns);
  }

  @override
  Future<String> generateNextQuestion({
    required JobRole? role,
    required String jobRoleLabel,
    required InterviewType type,
    required List<InterviewTurn> turns,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  }) async {
    final typeLabel = type.label(l10n);
    final history = formatTurnsForHistory(turns, l10n);
    final varietyInstructions = getVarietyInstructions(l10n, selectedFocus);
    final roleContext = role?.roleContext(l10n) ?? '';

    final prompt = l10n.aiPromptNextQuestion(
      jobRoleLabel,
      roleContext,
      typeLabel,
      history,
      varietyInstructions,
    );

    final next = await sendPrompt(
      prompt: prompt,
      systemInstruction: l10n.aiPromptSystemInterviewer(l10n.localeName),
      temperature: 0.8,
      maxOutputTokens: 1536,
    );

    return next.trim();
  }

  @override
  Future<String> generateClosingMessage({
    required JobRole? role,
    required String jobRoleLabel,
    required AppLocalizations l10n,
  }) async {
    final roleContext = role?.roleContext(l10n) ?? '';
    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);
    final prompt = l10n.aiPromptClosing(jobRoleLabel, roleContext);

    final closing = await sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.7,
      maxOutputTokens: 512,
    );

    return closing.trim();
  }

  @override
  Future<String> generateOpeningQuestion({
    required JobRole? role,
    required String jobRoleLabel,
    required InterviewType type,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  }) async {
    final typeLabel = type.label(l10n);
    final varietyInstructions = getVarietyInstructions(l10n, selectedFocus);
    final roleContext = role?.roleContext(l10n) ?? '';

    final prompt = l10n.aiPromptOpening(
      jobRoleLabel,
      roleContext,
      typeLabel,
      varietyInstructions,
    );

    final response = await sendPrompt(
      prompt: prompt,
      systemInstruction: l10n.aiPromptSystemInterviewer(l10n.localeName),
      temperature: 0.7,
      maxOutputTokens: 1536,
    );

    return response.trim();
  }

  @override
  Future<String> generateConversationalNextQuestion({
    required JobRole? role,
    required String jobRoleLabel,
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
    final roleContext = role?.roleContext(l10n) ?? '';

    final prompt = l10n.aiPromptConversationalNext(
      jobRoleLabel,
      roleContext,
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
      maxOutputTokens: 1536,
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

  @override
  Future<InterviewResultsModel> generateInterviewResults({
    required InterviewConfig config,
    required InterviewSession session,
    required AppLocalizations l10n,
  }) async {
    if (session.turns.isEmpty) {
      throw AiProviderException(l10n.processingNotEnoughData);
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

    final jobRoleLabel = config.jobRole == null
        ? ''
        : config.jobRole!.label(l10n);
    final roleContext = config.jobRole?.roleContext(l10n) ?? '';
    final typeLabel = config.type == null
        ? l10n.interviewTypeMixed
        : config.type!.label(l10n);

    final systemInstruction = l10n.aiPromptSystemInterviewer(l10n.localeName);

    const jsonSchema =
        '{"overallScore": 0, "outcome": "...", "breakdown": {"communication": 75, "technicalKnowledge": 70, "confidence": 72}, "highlights": ["..."], "personalizedFeedback": "...", "recommendations": ["..."], "improvementTips": ["..."]}';
    final prompt = l10n.aiPromptResultsAnalysis(
      jobRoleLabel,
      roleContext,
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
      maxOutputTokens: 2048,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw));

    // Graceful fallback: build results from locally-computed data if Groq
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

      // Fallback dinámico para recomendaciones basado en el score
      final fallbackRecs = overallScore < 70
          ? [
              'Revisa los conceptos técnicos donde obtuviste menor puntaje.',
              'Practica la claridad y estructura de tus respuestas.',
              'Intenta proporcionar ejemplos más concretos en tus respuestas.',
            ]
          : [
              'Sigue practicando para mantener este nivel de confianza.',
              'Explora escenarios más avanzados y casos de borde.',
              'Refina tu capacidad de síntesis en temas complejos.',
            ];

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
        recommendations: fallbackRecs,
        improvementTips: const [
          'Utiliza el método STAR para estructurar tus respuestas.',
          'Mantén contacto visual (si es por video) y cuida tu lenguaje corporal.',
          'No dudes en pedir aclaraciones si una pregunta no es clara.',
        ],
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

    // Fallback dinámico para recomendaciones si vienen vacías
    final recommendations = parsed.recommendations.isNotEmpty
        ? parsed.recommendations
        : (overallScore < 70
              ? [
                  'Revisa los conceptos técnicos clave para este rol.',
                  'Practica respuestas estructuradas usando el método STAR.',
                  'Enfócate en mejorar la claridad de tus explicaciones.',
                ]
              : [
                  'Continúa profundizando en temas avanzados de tu especialidad.',
                  'Practica escenarios de resolución de problemas complejos.',
                  'Mantén tu nivel de comunicación y confianza.',
                ]);

    final improvementTips = parsed.improvementTips.isNotEmpty
        ? parsed.improvementTips
        : [
            'Investiga más sobre las tendencias actuales en ${jobRoleLabel.isNotEmpty ? jobRoleLabel : "tu área"}.',
            'Prepara ejemplos reales de desafíos que hayas superado.',
            'Practica frente al espejo para mejorar tu lenguaje corporal.',
          ];

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
      recommendations: recommendations,
      improvementTips: improvementTips,
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
  if (text.isEmpty) return null;
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    try {
      // Intentar una reparación simple: eliminar comas finales antes de cerrar llaves o corchetes
      var repaired = text
          .replaceAll(RegExp(r',\s*\}'), '}')
          .replaceAll(RegExp(r',\s*\]'), ']');
      return jsonDecode(repaired) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
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
