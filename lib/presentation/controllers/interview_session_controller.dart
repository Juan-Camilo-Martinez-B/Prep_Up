import 'package:flutter/foundation.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart';

class InterviewSessionController extends ChangeNotifier {
  InterviewSessionController({
    required GeminiService geminiService,
    required InterviewConfig config,
  }) : _geminiService = geminiService,
       _config = config,
       _speech = SpeechToText(),
       _selectedFocusAreas = geminiService.getRandomFocusAreas(5),
       _session = InterviewSession(
         startedAt: DateTime.now().toUtc(),
         turns: const [],
       );

  final GeminiService _geminiService;
  final InterviewConfig _config;
  final SpeechToText _speech;
  final List<String> _selectedFocusAreas;
  bool get _isEnglish =>
      AppLocaleRuntime.languageCode.toLowerCase().startsWith('en');

  InterviewSession _session;
  String _currentQuestion = '';
  bool _isStarting = false;
  bool _isSubmitting = false;
  bool _isGeneratingNext = false;
  bool _isListening = false;
  String _voiceDraft = '';
  String? _error;
  DateTime? _currentQuestionAskedAt;
  bool _isInterviewComplete = false;

  InterviewSession get session => _session;
  String get currentQuestion => _currentQuestion;

  bool get isStarting => _isStarting;
  bool get isSubmitting => _isSubmitting;
  bool get isGeneratingNext => _isGeneratingNext;

  bool get isListening => _isListening;
  String get voiceDraft => _voiceDraft;

  String? get error => _error;
  bool get isInterviewComplete => _isInterviewComplete;
  int get targetQuestionCount =>
      _estimateQuestionCount(_config.durationMinutes ?? 3);

  InterviewTurn? get lastTurn =>
      _session.turns.isEmpty ? null : _session.turns.last;

  Future<void> start() async {
    if (_isStarting) return;
    _isStarting = true;
    _error = null;
    notifyListeners();

    final l10n = lookupAppLocalizations(AppLocaleRuntime.locale);
    try {
      if (_config.jobRole == null) {
        throw const GeminiException(
          'Falta el cargo para iniciar la entrevista.',
        );
      }
      final jobRole = _config.jobRole!.label(l10n);
      if (_config.type == null) {
        throw const GeminiException('Falta el tipo de entrevista.');
      }

      final questions = await _geminiService.generateInterviewQuestions(
        type: _config.type!,
        jobRole: jobRole,
        count: 1,
        language: _isEnglish ? 'en' : 'es',
        selectedFocus: _selectedFocusAreas,
      );

      _currentQuestion = questions.isNotEmpty ? questions.first : '';
      if (_currentQuestion.trim().isEmpty) {
        throw const GeminiException('No se pudo generar la primera pregunta.');
      }
      _currentQuestionAskedAt = DateTime.now().toUtc();
    } catch (e) {
      _error = userFriendlyErrorMessage(e, l10n);
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> submitAnswer(String answer) async {
    if (_isSubmitting || _isGeneratingNext) return;
    final question = _currentQuestion.trim();
    final safeAnswer = answer.trim();
    if (question.isEmpty || safeAnswer.isEmpty) return;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final l10n = lookupAppLocalizations(AppLocaleRuntime.locale);
    try {
      final evaluation = await _geminiService.evaluateUserAnswer(
        question: question,
        userAnswer: safeAnswer,
        jobRole: _config.jobRole == null ? '' : _config.jobRole!.label(l10n),
        type: _config.type ?? InterviewType.mixed,
        language: _isEnglish ? 'en' : 'es',
      );

      final feedback = await _geminiService.generateFeedback(
        question: question,
        userAnswer: safeAnswer,
        evaluation: evaluation,
        language: _isEnglish ? 'en' : 'es',
      );

      final turn = InterviewTurn(
        question: question,
        answer: safeAnswer,
        evaluation: evaluation,
        feedback: feedback,
        createdAt: DateTime.now().toUtc(),
        responseDurationSeconds: _calculateResponseDurationSeconds(
          _currentQuestionAskedAt,
        ),
      );

      _session = _session.copyWith(turns: [..._session.turns, turn]);
      notifyListeners();
    } catch (e) {
      _error = userFriendlyErrorMessage(e, l10n);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }

    if (_error != null) return;
    if (_shouldFinishAfterTurn()) {
      _isInterviewComplete = true;
      _currentQuestion = '';
      notifyListeners();
      return;
    }
    await generateNextQuestion();
  }

  Future<void> generateNextQuestion() async {
    if (_isGeneratingNext) return;
    _isGeneratingNext = true;
    _error = null;
    notifyListeners();

    final l10n = lookupAppLocalizations(AppLocaleRuntime.locale);
    try {
      final jobRole = _config.jobRole == null
          ? ''
          : _config.jobRole!.label(l10n);
      final type = _config.type ?? InterviewType.mixed;
      final history = _formatHistoryForPrompt(_session.turns);
      final varietyInstructions = _geminiService.getVarietyInstructions(
        _selectedFocusAreas,
        _isEnglish,
      );

      final prompt = _isEnglish
          ? '''
Act as an expert interviewer for the "$jobRole" role.
Interview type: ${type.label(l10n)}.

History (question, answer, evaluation):
$history

Generate the next question in English:
- It must be a single question.
- It must adapt to the last answer.
- If score was low, ask for clarification or a concrete example.
- If score was high, increase difficulty or go deeper.
$varietyInstructions
- AVOID generic or overused topics (e.g., "microservices vs monoliths", "SQL vs NoSQL") unless directly related to the previous answer.
- Ensure the topic is different from previous questions in the history to maintain variety.
- No numbering.
- No markdown.
Return ONLY the question text.
'''
          : '''
Actúa como entrevistador experto para el rol "$jobRole".
Tipo de entrevista: ${type.label(l10n)}.

Historial (pregunta, respuesta, evaluación):
$history

Genera la siguiente pregunta en español:
- Debe ser una sola pregunta.
- Debe adaptarse a la última respuesta.
- Si el score fue bajo, pide aclaración o un ejemplo concreto.
- Si el score fue alto, incrementa dificultad o profundiza.
$varietyInstructions
- EVITA temas trillados o genéricos (ej. "microservicios vs monolitos", "SQL vs NoSQL") a menos que estén directamente relacionados con la respuesta anterior.
- Asegúrate de variar el tema respecto a las preguntas anteriores en el historial.
- Sin numeración.
- Sin markdown.
Devuelve SOLO el texto de la pregunta.
''';

      final next = await _geminiService.sendPrompt(
        prompt: prompt,
        systemInstruction: _isEnglish
            ? 'You are a human interviewer. Be natural and direct.'
            : 'Eres un entrevistador humano. Sé natural y directo.',
        temperature: 0.8,
        maxOutputTokens: 256,
      );

      final cleaned = next.trim();
      if (cleaned.isEmpty) {
        throw const GeminiException(
          'No se pudo generar la siguiente pregunta.',
        );
      }
      _currentQuestion = cleaned;
      _currentQuestionAskedAt = DateTime.now().toUtc();
    } catch (e) {
      _error = userFriendlyErrorMessage(e, l10n);
    } finally {
      _isGeneratingNext = false;
      notifyListeners();
    }
  }

  Future<void> initVoice() async {
    final l10n = lookupAppLocalizations(AppLocaleRuntime.locale);
    final available = await _speech.initialize();
    if (!available) {
      _error = l10n.interviewSpeechRecognitionUnavailable;
      notifyListeners();
    }
  }

  Future<void> toggleListening() async {
    final l10n = lookupAppLocalizations(AppLocaleRuntime.locale);
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      return;
    }

    _error = null;
    notifyListeners();

    final available = await _speech.initialize();
    if (!available) {
      _error = l10n.interviewSpeechRecognitionUnavailable;
      notifyListeners();
      return;
    }

    _voiceDraft = '';
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
      onResult: (result) {
        _voiceDraft = result.recognizedWords;
        notifyListeners();
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool _shouldFinishAfterTurn() {
    final answered = _session.turns.length;
    if (answered >= targetQuestionCount) {
      return true;
    }

    final totalInterviewSeconds = (_config.durationMinutes ?? 3) * 60;
    final elapsed = DateTime.now()
        .toUtc()
        .difference(_session.startedAt)
        .inSeconds;
    final remaining = totalInterviewSeconds - elapsed;
    final averageBudgetPerQuestion =
        (totalInterviewSeconds / targetQuestionCount).round().clamp(45, 180);
    return remaining < averageBudgetPerQuestion;
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

int _calculateResponseDurationSeconds(DateTime? askedAt) {
  if (askedAt == null) return 0;
  final elapsed = DateTime.now().toUtc().difference(askedAt).inSeconds;
  return elapsed < 0 ? 0 : elapsed;
}

int _estimateQuestionCount(int durationMinutes) {
  final safeMinutes = durationMinutes <= 0 ? 3 : durationMinutes;
  final estimated = (safeMinutes * 60 / 95).round();
  return estimated.clamp(1, 12).toInt();
}

String _formatHistoryForPrompt(List<InterviewTurn> turns) {
  if (turns.isEmpty) return '- (sin historial)';
  final buffer = StringBuffer();
  for (var i = 0; i < turns.length; i++) {
    final t = turns[i];
    buffer.writeln('Turno ${i + 1}:');
    buffer.writeln('P: ${t.question}');
    buffer.writeln('R: ${t.answer}');
    buffer.writeln('Score: ${t.evaluation.overallScore}');
    if (t.evaluation.improvements.isNotEmpty) {
      buffer.writeln('Mejoras: ${t.evaluation.improvements.join(' | ')}');
    }
    buffer.writeln('');
  }
  return buffer.toString().trim();
}
