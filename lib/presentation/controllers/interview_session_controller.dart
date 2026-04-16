import 'package:flutter/foundation.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class InterviewSessionController extends ChangeNotifier {
  InterviewSessionController({
    required GeminiService geminiService,
    required InterviewConfig config,
  })  : _geminiService = geminiService,
        _config = config,
        _speech = SpeechToText(),
        _session = InterviewSession(
          startedAt: DateTime.now().toUtc(),
          turns: const [],
        );

  final GeminiService _geminiService;
  final InterviewConfig _config;
  final SpeechToText _speech;

  InterviewSession _session;
  String _currentQuestion = '';
  bool _isStarting = false;
  bool _isSubmitting = false;
  bool _isGeneratingNext = false;
  bool _isListening = false;
  String _voiceDraft = '';
  String? _error;

  InterviewSession get session => _session;
  String get currentQuestion => _currentQuestion;

  bool get isStarting => _isStarting;
  bool get isSubmitting => _isSubmitting;
  bool get isGeneratingNext => _isGeneratingNext;

  bool get isListening => _isListening;
  String get voiceDraft => _voiceDraft;

  String? get error => _error;

  InterviewTurn? get lastTurn =>
      _session.turns.isEmpty ? null : _session.turns.last;

  Future<void> start() async {
    if (_isStarting) return;
    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      final jobRole = _config.jobRole.trim();
      if (jobRole.isEmpty) {
        throw const GeminiException('Falta el cargo para iniciar la entrevista.');
      }
      if (_config.type == null) {
        throw const GeminiException('Falta el tipo de entrevista.');
      }

      final questions = await _geminiService.generateInterviewQuestions(
        type: _mapType(_config.type!),
        jobRole: jobRole,
        count: 1,
      );

      _currentQuestion = questions.isNotEmpty ? questions.first : '';
      if (_currentQuestion.trim().isEmpty) {
        throw const GeminiException('No se pudo generar la primera pregunta.');
      }
    } catch (e) {
      _error = e.toString();
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

    try {
      final evaluation = await _geminiService.evaluateUserAnswer(
        question: question,
        userAnswer: safeAnswer,
        jobRole: _config.jobRole.trim(),
        type: _mapType(_config.type ?? InterviewConfigType.mixed),
      );

      final feedback = await _geminiService.generateFeedback(
        question: question,
        userAnswer: safeAnswer,
        evaluation: evaluation,
      );

      final turn = InterviewTurn(
        question: question,
        answer: safeAnswer,
        evaluation: evaluation,
        feedback: feedback,
        createdAt: DateTime.now().toUtc(),
      );

      _session = _session.copyWith(turns: [..._session.turns, turn]);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }

    if (_error != null) return;
    await generateNextQuestion();
  }

  Future<void> generateNextQuestion() async {
    if (_isGeneratingNext) return;
    _isGeneratingNext = true;
    _error = null;
    notifyListeners();

    try {
      final jobRole = _config.jobRole.trim();
      final type = _config.type ?? InterviewConfigType.mixed;
      final history = _formatHistoryForPrompt(_session.turns);

      final prompt = '''
Actúa como entrevistador experto para el rol "$jobRole".
Tipo de entrevista: ${type.label}.

Historial (pregunta, respuesta, evaluación):
$history

Genera la siguiente pregunta en español:
- Debe ser una sola pregunta.
- Debe adaptarse a la última respuesta.
- Si el score fue bajo, pide aclaración o un ejemplo concreto.
- Si el score fue alto, incrementa dificultad o profundiza.
- Sin numeración.
- Sin markdown.
Devuelve SOLO el texto de la pregunta.
''';

      final next = await _geminiService.sendPrompt(
        prompt: prompt,
        systemInstruction: 'Eres un entrevistador humano. Sé natural y directo.',
        temperature: 0.8,
        maxOutputTokens: 256,
      );

      final cleaned = next.trim();
      if (cleaned.isEmpty) {
        throw const GeminiException('No se pudo generar la siguiente pregunta.');
      }
      _currentQuestion = cleaned;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGeneratingNext = false;
      notifyListeners();
    }
  }

  Future<void> initVoice() async {
    final available = await _speech.initialize();
    if (!available) {
      _error = 'El reconocimiento de voz no está disponible.';
      notifyListeners();
    }
  }

  Future<void> toggleListening() async {
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
      _error = 'El reconocimiento de voz no está disponible.';
      notifyListeners();
      return;
    }

    _voiceDraft = '';
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
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

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

InterviewType _mapType(InterviewConfigType type) {
  return switch (type) {
    InterviewConfigType.technical => InterviewType.technical,
    InterviewConfigType.rrhh => InterviewType.behavioral,
    InterviewConfigType.mixed => InterviewType.mixed,
  };
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
