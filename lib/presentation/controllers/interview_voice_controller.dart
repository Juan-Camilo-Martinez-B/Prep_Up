import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum InterviewConversationState { idle, listening, speaking, processing }

class InterviewVoiceController extends ChangeNotifier {
  InterviewVoiceController({
    required GeminiService geminiService,
    required InterviewConfig config,
    FlutterTts? flutterTts,
    SpeechToText? speech,
  }) : _geminiService = geminiService,
       _config = config,
       _tts = flutterTts ?? FlutterTts(),
       _speech = speech ?? SpeechToText(),
       _session = InterviewSession(
         startedAt: DateTime.now().toUtc(),
         turns: const [],
       ) {
    _configureTtsCallbacks();
  }

  final GeminiService _geminiService;
  final InterviewConfig _config;
  final FlutterTts _tts;
  final SpeechToText _speech;

  InterviewSession _session;
  InterviewConversationState _state = InterviewConversationState.idle;
  String _currentQuestion = '';
  String _voiceDraft = '';
  String _lastSubmittedAnswer = '';
  String _statusMessage = '';
  String? _error;
  bool _isSpeechAvailable = false;
  bool _isTtsAvailable = true;
  bool _isStarting = false;
  bool _isDisposed = false;
  bool _hasStarted = false;
  bool _isTtsConfigured = false;
  int _activeListeningCycle = 0;
  int _handledListeningCycle = 0;
  int _emptyVoiceRetries = 0;
  double _soundLevel = 0;
  String? _speechLocaleId;

  InterviewSession get session => _session;
  InterviewConversationState get state => _state;
  String get currentQuestion => _currentQuestion;
  String get voiceDraft => _voiceDraft;
  String get lastSubmittedAnswer => _lastSubmittedAnswer;
  String get statusMessage => _statusMessage;
  String? get error => _error;
  double get soundLevel => _soundLevel;

  bool get hasSpeechRecognition => _isSpeechAvailable;
  bool get hasTextToSpeech => _isTtsAvailable;
  bool get isListening => _state == InterviewConversationState.listening;
  bool get isSpeaking => _state == InterviewConversationState.speaking;
  bool get isProcessing => _state == InterviewConversationState.processing;
  bool get isIdle => _state == InterviewConversationState.idle;

  InterviewTurn? get lastTurn =>
      _session.turns.isEmpty ? null : _session.turns.last;

  Future<void> start() async {
    if (_isStarting || _hasStarted) return;
    _isStarting = true;
    _error = null;
    _statusMessage = 'Preparando la entrevista...';
    _notifySafely();

    try {
      await _initializeAudio();
      final openingQuestion = await _generateOpeningQuestion();
      _hasStarted = true;
      await _deliverQuestion(
        openingQuestion,
        introMessage: 'La entrevista ha comenzado.',
      );
    } catch (e) {
      _setIdle();
      _error = e.toString();
      _statusMessage = 'No se pudo iniciar la entrevista.';
      _notifySafely();
    } finally {
      _isStarting = false;
    }
  }

  Future<void> toggleListening() async {
    if (isProcessing || isSpeaking) return;
    if (isListening) {
      await _speech.stop();
      _state = InterviewConversationState.idle;
      _statusMessage = _voiceDraft.trim().isEmpty
          ? 'Escucha detenida. Puedes volver a intentarlo.'
          : 'Puedes revisar la transcripción o enviarla.';
      _notifySafely();
      return;
    }

    await _beginListening(clearDraft: true);
  }

  Future<void> submitAnswer(String answer) async {
    final question = _currentQuestion.trim();
    final safeAnswer = answer.trim();
    if (question.isEmpty || safeAnswer.isEmpty || isProcessing) return;

    _handledListeningCycle = _activeListeningCycle;
    _emptyVoiceRetries = 0;
    _voiceDraft = safeAnswer;
    _lastSubmittedAnswer = safeAnswer;
    _state = InterviewConversationState.processing;
    _statusMessage =
        'Analizando tu respuesta y preparando la siguiente pregunta...';
    _error = null;
    _notifySafely();

    try {
      await _speech.stop();

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
      _notifySafely();

      final nextQuestion = await _generateAdaptiveNextQuestion();
      await _deliverQuestion(nextQuestion);
    } catch (e) {
      _setIdle();
      _error = e.toString();
      _statusMessage =
          'No se pudo procesar la respuesta. Puedes intentarlo de nuevo.';
      _notifySafely();
    }
  }

  Future<void> skipQuestion() async {
    if (_currentQuestion.trim().isEmpty || isProcessing) return;

    _error = null;
    _state = InterviewConversationState.processing;
    _statusMessage = 'Pidiendo a Gemini una pregunta diferente...';
    _notifySafely();

    try {
      await _speech.stop();
      await _tts.stop();
      final nextQuestion = await _generateAlternativeQuestion();
      await _deliverQuestion(
        nextQuestion,
        introMessage: 'Vamos con una pregunta distinta.',
      );
    } catch (e) {
      _setIdle();
      _error = e.toString();
      _statusMessage = 'No se pudo omitir la pregunta actual.';
      _notifySafely();
    }
  }

  Future<void> repeatCurrentQuestion() async {
    final question = _currentQuestion.trim();
    if (question.isEmpty || isProcessing) return;

    await _speech.stop();
    _voiceDraft = '';
    _emptyVoiceRetries = 0;
    await _deliverQuestion(question, introMessage: 'Repito la pregunta.');
  }

  Future<void> retryListening() async {
    if (isProcessing || _currentQuestion.trim().isEmpty) return;
    await _beginListening(clearDraft: true);
  }

  Future<void> stopConversation() async {
    _hasStarted = false;
    _setIdle();
    _statusMessage = '';
    _voiceDraft = '';
    _soundLevel = 0;
    _notifySafely();
    await _speech.cancel();
    await _tts.stop();
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }

  Future<void> _initializeAudio() async {
    await _configureTts();
    await _initializeSpeech();
  }

  Future<void> _configureTts() async {
    if (_isTtsConfigured) return;
    _isTtsConfigured = true;

    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.42);

      final preferredLanguage = await _resolveTtsLanguage();
      if (preferredLanguage != null) {
        await _tts.setLanguage(preferredLanguage);
      }

      final preferredVoice = await _resolveSpanishVoice();
      if (preferredVoice != null) {
        await _tts.setVoice(preferredVoice);
      }
    } catch (_) {
      _isTtsAvailable = false;
      _statusMessage =
          'No se pudo activar la voz de la IA. La pregunta seguirá visible en pantalla.';
      _notifySafely();
    }
  }

  void _configureTtsCallbacks() {
    _tts.setStartHandler(() {
      _state = InterviewConversationState.speaking;
      _statusMessage = 'La IA está hablando...';
      _notifySafely();
    });

    _tts.setCompletionHandler(() {
      if (_state == InterviewConversationState.speaking) {
        _statusMessage = 'Esperando tu respuesta...';
        _notifySafely();
      }
    });

    _tts.setCancelHandler(() {
      if (_state == InterviewConversationState.speaking) {
        _setIdle();
        _notifySafely();
      }
    });

    _tts.setErrorHandler((message) {
      _isTtsAvailable = false;
      _error = 'Falló la reproducción de voz: $message';
      if (_state == InterviewConversationState.speaking) {
        _setIdle();
      }
      _statusMessage =
          'No se pudo reproducir el audio. La pregunta queda disponible en texto.';
      _notifySafely();
    });
  }

  Future<void> _initializeSpeech() async {
    _isSpeechAvailable = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
      debugLogging: false,
    );

    if (!_isSpeechAvailable) {
      _error =
          'El reconocimiento de voz no está disponible en este dispositivo.';
      _statusMessage =
          'Puedes continuar escribiendo tu respuesta mientras se mantiene la conversación.';
      _notifySafely();
      return;
    }

    final locales = await _speech.locales();
    _speechLocaleId = _pickPreferredSpeechLocale(locales);
  }

  Future<String> _generateOpeningQuestion() async {
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

    final question = questions.isNotEmpty ? questions.first.trim() : '';
    if (question.isEmpty) {
      throw const GeminiException('No se pudo generar la primera pregunta.');
    }
    return question;
  }

  Future<String> _generateAdaptiveNextQuestion() async {
    final jobRole = _config.jobRole.trim();
    final type = _config.type ?? InterviewConfigType.mixed;
    final history = _formatHistoryForPrompt(_session.turns);

    final prompt =
        '''
Actua como entrevistador experto para el rol "$jobRole".
Tipo de entrevista: ${type.label}.

Historial real:
$history

Genera la siguiente pregunta en espanol.
Reglas:
- Debe ser una sola pregunta.
- Debe adaptarse a la ultima respuesta.
- Si el score fue bajo, pide aclaracion o un ejemplo concreto.
- Si el score fue alto, incrementa la dificultad o profundiza.
- Debe sonar natural, como una videollamada real.
- Sin numeracion.
- Sin markdown.
Devuelve SOLO el texto de la pregunta.
''';

    final next = await _geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction: 'Eres un entrevistador humano. Se natural y directo.',
      temperature: 0.8,
      maxOutputTokens: 256,
    );

    final cleaned = next.trim();
    if (cleaned.isEmpty) {
      throw const GeminiException('No se pudo generar la siguiente pregunta.');
    }
    return cleaned;
  }

  Future<String> _generateAlternativeQuestion() async {
    final jobRole = _config.jobRole.trim();
    final type = _config.type ?? InterviewConfigType.mixed;
    final history = _formatHistoryForPrompt(_session.turns);

    final prompt =
        '''
Actua como entrevistador experto para el rol "$jobRole".
Tipo de entrevista: ${type.label}.

Pregunta actual:
"$_currentQuestion"

Historial real:
$history

Genera una nueva pregunta en espanol para reemplazar la actual.
Reglas:
- Debe ser diferente a la pregunta actual.
- Debe mantener continuidad con el historial.
- Debe sonar natural, breve y directa.
- Sin numeracion.
- Sin markdown.
Devuelve SOLO el texto de la pregunta.
''';

    final next = await _geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction:
          'Eres un entrevistador humano. Se natural y mantienes la entrevista fluida.',
      temperature: 0.85,
      maxOutputTokens: 256,
    );

    final cleaned = next.trim();
    if (cleaned.isEmpty) {
      throw const GeminiException('No se pudo generar una nueva pregunta.');
    }
    return cleaned;
  }

  Future<void> _deliverQuestion(String question, {String? introMessage}) async {
    _currentQuestion = question.trim();
    _voiceDraft = '';
    _error = null;
    _emptyVoiceRetries = 0;
    _statusMessage = introMessage ?? 'Nueva pregunta lista.';
    _notifySafely();

    if (_currentQuestion.isEmpty) {
      _setIdle();
      _error = 'Gemini devolvio una pregunta vacia.';
      _notifySafely();
      return;
    }

    if (_isTtsAvailable) {
      try {
        final speechText = introMessage == null
            ? _currentQuestion
            : '$introMessage $_currentQuestion';
        _state = InterviewConversationState.speaking;
        _statusMessage = 'La IA esta hablando...';
        _notifySafely();
        await _tts.speak(speechText);
      } catch (e) {
        _isTtsAvailable = false;
        _error = 'Falló TTS: $e';
        _statusMessage =
            'No se pudo reproducir la pregunta. Continuamos con la version en texto.';
        _setIdle();
        _notifySafely();
      }
    } else {
      _setIdle();
      _statusMessage =
          'La pregunta esta disponible en texto. Responde por voz o por escrito.';
      _notifySafely();
    }

    if (_isSpeechAvailable) {
      await _beginListening(clearDraft: true);
    } else {
      _setIdle();
      _statusMessage =
          'Escribe tu respuesta para que Gemini genere la siguiente pregunta.';
      _notifySafely();
    }
  }

  Future<void> _beginListening({required bool clearDraft}) async {
    if (!_isSpeechAvailable || _currentQuestion.trim().isEmpty) return;

    try {
      await _tts.stop();
      await _speech.stop();

      if (clearDraft) {
        _voiceDraft = '';
      }

      _activeListeningCycle += 1;
      _handledListeningCycle = 0;
      _soundLevel = 0;
      _state = InterviewConversationState.listening;
      _statusMessage = 'Escuchando tu respuesta...';
      _error = null;
      _notifySafely();

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 3),
        localeId: _speechLocaleId,
        onSoundLevelChange: _onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      _setIdle();
      _error = 'No se pudo activar el micrófono: $e';
      _statusMessage =
          'Puedes volver a intentar o responder por escrito para continuar.';
      _notifySafely();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords.trim();
    if (transcript != _voiceDraft) {
      _voiceDraft = transcript;
      _notifySafely();
    }

    if (result.finalResult) {
      unawaited(_finalizeListeningCycle(transcript: transcript));
    }
  }

  void _onSpeechStatus(String status) {
    if (!isListening) return;
    if (status == 'done' || status == 'notListening') {
      unawaited(_finalizeListeningCycle());
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!isListening) return;
    _setIdle();
    _error = 'Falló STT: ${error.errorMsg}';
    _statusMessage =
        'No se pudo transcribir tu respuesta. Puedes intentarlo otra vez.';
    _notifySafely();
  }

  void _onSoundLevelChange(double level) {
    if (!isListening) return;
    _soundLevel = level;
    _notifySafely();
  }

  Future<void> _finalizeListeningCycle({String? transcript}) async {
    final cycle = _activeListeningCycle;
    if (cycle == 0 || cycle == _handledListeningCycle) return;
    _handledListeningCycle = cycle;

    await _speech.stop();

    final finalTranscript = (transcript ?? _voiceDraft).trim();
    if (finalTranscript.isEmpty) {
      await _handleNoVoiceDetected();
      return;
    }

    await submitAnswer(finalTranscript);
  }

  Future<void> _handleNoVoiceDetected() async {
    _emptyVoiceRetries += 1;
    _setIdle();

    if (_emptyVoiceRetries > 1) {
      _error =
          'No se detectó voz. Puedes intentar otra vez o escribir la respuesta.';
      _statusMessage = 'Esperando tu respuesta.';
      _notifySafely();
      return;
    }

    _statusMessage = 'No detecte voz. Intentare escuchar de nuevo.';
    _error =
        'No se detectó una respuesta clara. Responde nuevamente por favor.';
    _notifySafely();

    if (_isTtsAvailable) {
      try {
        _state = InterviewConversationState.speaking;
        _notifySafely();
        await _tts.speak('No te escuche con claridad. Responde nuevamente.');
      } catch (_) {
        _isTtsAvailable = false;
      }
    }

    await _beginListening(clearDraft: true);
  }

  Future<String?> _resolveTtsLanguage() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is! List) return null;

      final normalized = languages.map((e) => '$e').toList();
      for (final candidate in const ['es-ES', 'es-MX', 'es-US', 'es']) {
        if (normalized.any(
          (lang) => lang.toLowerCase() == candidate.toLowerCase(),
        )) {
          return candidate;
        }
      }

      for (final language in normalized) {
        if (language.toLowerCase().startsWith('es')) {
          return language;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>?> _resolveSpanishVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return null;

      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = '${voice['locale'] ?? ''}'.toLowerCase();
        final name = '${voice['name'] ?? ''}';
        if (!locale.startsWith('es')) continue;
        if (name.isEmpty) continue;
        return <String, String>{
          'name': name,
          'locale': '${voice['locale'] ?? 'es-ES'}',
        };
      }
    } catch (_) {}
    return null;
  }

  String? _pickPreferredSpeechLocale(List<LocaleName> locales) {
    for (final locale in locales) {
      if (locale.localeId.toLowerCase() == 'es_es') return locale.localeId;
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('es_')) {
        return locale.localeId;
      }
    }
    return locales.isNotEmpty ? locales.first.localeId : null;
  }

  void _setIdle() {
    _state = InterviewConversationState.idle;
    _soundLevel = 0;
  }

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.cancel();
    _tts.stop();
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
    final turn = turns[i];
    buffer.writeln('Turno ${i + 1}:');
    buffer.writeln('P: ${turn.question}');
    buffer.writeln('R: ${turn.answer}');
    buffer.writeln('Score: ${turn.evaluation.overallScore}');
    if (turn.evaluation.strengths.isNotEmpty) {
      buffer.writeln('Fortalezas: ${turn.evaluation.strengths.join(' | ')}');
    }
    if (turn.evaluation.improvements.isNotEmpty) {
      buffer.writeln('Mejoras: ${turn.evaluation.improvements.join(' | ')}');
    }
    if (turn.feedback.summary.trim().isNotEmpty) {
      buffer.writeln('Feedback: ${turn.feedback.summary.trim()}');
    }
    buffer.writeln('');
  }
  return buffer.toString().trim();
}
