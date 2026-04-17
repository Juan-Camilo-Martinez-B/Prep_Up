import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum InterviewConversationState { idle, listening, speaking, processing }

class InterviewVoiceController extends ChangeNotifier {
  InterviewVoiceController({
    required GeminiService geminiService,
    required InterviewConfig config,
    String languageCode = 'es',
    FlutterTts? flutterTts,
    SpeechToText? speech,
  }) : _geminiService = geminiService,
       _config = config,
       _languageCode = languageCode,
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
  final String _languageCode;
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
  DateTime? _currentQuestionAskedAt;
  bool _isInterviewComplete = false;
  String? _completionReason;

  InterviewSession get session => _session;
  InterviewConversationState get state => _state;
  String get currentQuestion => _currentQuestion;
  String get voiceDraft => _voiceDraft;
  String get lastSubmittedAnswer => _lastSubmittedAnswer;
  String get statusMessage => _statusMessage;
  String? get error => _error;
  double get soundLevel => _soundLevel;
  bool get isInterviewComplete => _isInterviewComplete;
  String? get completionReason => _completionReason;
  int get targetQuestionCount =>
      _estimateQuestionCount(_config.durationMinutes ?? 3);
  int get answeredQuestionCount => _session.turns.length;
  int get currentQuestionNumber {
    if (_isInterviewComplete) {
      return answeredQuestionCount == 0 ? 1 : answeredQuestionCount;
    }
    return math.min(targetQuestionCount, answeredQuestionCount + 1);
  }

  int get remainingQuestionCount =>
      math.max(0, targetQuestionCount - answeredQuestionCount);
  int get totalInterviewSeconds => (_config.durationMinutes ?? 3) * 60;
  int get remainingInterviewSeconds {
    final elapsed = DateTime.now()
        .toUtc()
        .difference(_session.startedAt)
        .inSeconds;
    final remaining = totalInterviewSeconds - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get hasSpeechRecognition => _isSpeechAvailable;
  bool get hasTextToSpeech => _isTtsAvailable;
  bool get isListening => _state == InterviewConversationState.listening;
  bool get isSpeaking => _state == InterviewConversationState.speaking;
  bool get isProcessing => _state == InterviewConversationState.processing;
  bool get isIdle => _state == InterviewConversationState.idle;
  bool get _isEnglish => _languageCode.toLowerCase().startsWith('en');
  String get _aiLanguage => _isEnglish ? 'en' : 'es';
  AppLocalizations get _l10n => lookupAppLocalizations(Locale(_aiLanguage));

  InterviewTurn? get lastTurn =>
      _session.turns.isEmpty ? null : _session.turns.last;

  Future<void> start() async {
    if (_isStarting || _hasStarted) return;
    _isStarting = true;
    _isInterviewComplete = false;
    _completionReason = null;
    _error = null;
    _statusMessage = _isEnglish
        ? 'Preparing interview...'
        : 'Preparando la entrevista...';
    _notifySafely();

    try {
      await _initializeAudio();
      final openingQuestion = await _generateOpeningQuestion();
      _hasStarted = true;
      await _deliverQuestion(
        openingQuestion,
        introMessage: _isEnglish
            ? 'The interview has started.'
            : 'La entrevista ha comenzado.',
      );
    } catch (e) {
      _setIdle();
      _error = e.toString();
      _statusMessage = _isEnglish
          ? 'Could not start the interview.'
          : 'No se pudo iniciar la entrevista.';
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
          ? (_isEnglish
                ? 'Listening stopped. You can try again.'
                : 'Escucha detenida. Puedes volver a intentarlo.')
          : (_isEnglish
                ? 'You can review the transcript or submit it.'
                : 'Puedes revisar la transcripción o enviarla.');
      _notifySafely();
      return;
    }

    await _beginListening(clearDraft: true);
  }

  Future<void> submitAnswer(String answer) async {
    final question = _currentQuestion.trim();
    final safeAnswer = answer.trim();
    if (question.isEmpty ||
        safeAnswer.isEmpty ||
        isProcessing ||
        _isInterviewComplete) {
      return;
    }

    _handledListeningCycle = _activeListeningCycle;
    _emptyVoiceRetries = 0;
    _voiceDraft = safeAnswer;
    _lastSubmittedAnswer = safeAnswer;
    _state = InterviewConversationState.processing;
    _statusMessage = _isEnglish
        ? 'Analyzing your answer and preparing the next question...'
        : 'Analizando tu respuesta y preparando la siguiente pregunta...';
    _error = null;
    _notifySafely();

    try {
      await _speech.stop();

      final evaluation = await _geminiService.evaluateUserAnswer(
        question: question,
        userAnswer: safeAnswer,
        jobRole: _config.jobRole == null ? '' : _config.jobRole!.label(_l10n),
        type: _mapType(_config.type ?? InterviewConfigType.mixed),
        language: _aiLanguage,
      );

      final feedback = await _geminiService.generateFeedback(
        question: question,
        userAnswer: safeAnswer,
        evaluation: evaluation,
        language: _aiLanguage,
      );

      final turn = InterviewTurn(
        question: question,
        answer: safeAnswer,
        evaluation: evaluation,
        feedback: feedback,
        createdAt: DateTime.now().toUtc(),
        responseDurationSeconds: _calculateCurrentResponseDurationSeconds(),
      );

      _session = _session.copyWith(turns: [..._session.turns, turn]);
      _notifySafely();

      if (_shouldFinishAfterTurn()) {
        _completeInterview(reason: _buildCompletionReason());
        return;
      }

      final nextQuestion = await _generateAdaptiveNextQuestion(turn);
      await _deliverQuestion(nextQuestion);
    } catch (e) {
      _setIdle();
      _error = e.toString();
      _statusMessage = _isEnglish
          ? 'Could not process the answer. You can try again.'
          : 'No se pudo procesar la respuesta. Puedes intentarlo de nuevo.';
      _notifySafely();
    }
  }

  Future<void> skipQuestion() async {
    if (_currentQuestion.trim().isEmpty ||
        isProcessing ||
        _isInterviewComplete) {
      return;
    }

    _error = null;
    _state = InterviewConversationState.processing;
    _statusMessage = _isEnglish
        ? 'Asking Gemini for a different question...'
        : 'Pidiendo a Gemini una pregunta diferente...';
    _notifySafely();

    try {
      await _speech.stop();
      await _tts.stop();
      final nextQuestion = await _generateAlternativeQuestion();
      await _deliverQuestion(
        nextQuestion,
        introMessage: _isEnglish
            ? "Let's go with a different question."
            : 'Vamos con una pregunta distinta.',
      );
    } catch (e) {
      _setIdle();
      _error = e.toString();
      _statusMessage = _isEnglish
          ? 'Could not skip the current question.'
          : 'No se pudo omitir la pregunta actual.';
      _notifySafely();
    }
  }

  Future<void> repeatCurrentQuestion() async {
    final question = _currentQuestion.trim();
    if (question.isEmpty || isProcessing || _isInterviewComplete) return;

    await _speech.stop();
    _voiceDraft = '';
    _emptyVoiceRetries = 0;
    await _deliverQuestion(
      question,
      introMessage: _isEnglish
          ? 'Repeating the question.'
          : 'Repito la pregunta.',
    );
  }

  Future<void> retryListening() async {
    if (isProcessing ||
        _currentQuestion.trim().isEmpty ||
        _isInterviewComplete) {
      return;
    }
    await _beginListening(clearDraft: true);
  }

  Future<void> stopConversation() async {
    _hasStarted = false;
    _isInterviewComplete = false;
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
      _statusMessage = _isEnglish
          ? 'Could not enable AI voice. The question remains visible on screen.'
          : 'No se pudo activar la voz de la IA. La pregunta seguirá visible en pantalla.';
      _notifySafely();
    }
  }

  void _configureTtsCallbacks() {
    _tts.setStartHandler(() {
      _state = InterviewConversationState.speaking;
      _statusMessage = _isEnglish
          ? 'AI is speaking...'
          : 'La IA está hablando...';
      _notifySafely();
    });

    _tts.setCompletionHandler(() {
      if (_state == InterviewConversationState.speaking) {
        _statusMessage = 'Esperando tu respuesta...';
        if (_isEnglish) {
          _statusMessage = 'Waiting for your answer...';
        }
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
      _statusMessage = _isEnglish
          ? 'Could not play audio. The question remains available in text.'
          : 'No se pudo reproducir el audio. La pregunta queda disponible en texto.';
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
      _error = _isEnglish
          ? 'Speech recognition is not available on this device.'
          : 'El reconocimiento de voz no está disponible en este dispositivo.';
      _statusMessage = _isEnglish
          ? 'You can continue by typing your answer while the interview continues.'
          : 'Puedes continuar escribiendo tu respuesta mientras se mantiene la conversación.';
      _notifySafely();
      return;
    }

    final locales = await _speech.locales();
    _speechLocaleId = _pickPreferredSpeechLocale(locales);
  }

  Future<String> _generateOpeningQuestion() async {
    final jobRole = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
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
      language: _aiLanguage,
    );

    final question = questions.isNotEmpty ? questions.first.trim() : '';
    if (question.isEmpty) {
      throw const GeminiException('No se pudo generar la primera pregunta.');
    }
    return question;
  }

  Future<String> _generateAdaptiveNextQuestion(InterviewTurn lastTurn) async {
    final jobRole = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
    final type = _config.type ?? InterviewConfigType.mixed;
    final history = _formatHistoryForPrompt(_session.turns);
    final followUps = lastTurn.evaluation.followUpQuestions
        .map(_sanitizeQuestion)
        .where((q) => q.isNotEmpty)
        .toList();
    final lastSummary = lastTurn.feedback.summary.trim();
    final lastStrengths = lastTurn.evaluation.strengths.join(' | ');
    final lastImprovements = lastTurn.evaluation.improvements.join(' | ');
    final followUpSeed = followUps.isEmpty
        ? '- (sin sugerencias)'
        : followUps.join('\n- ');

    final prompt = _isEnglish
        ? '''
Act as a senior interviewer for the "$jobRole" role.
Interview type: ${type.label(_l10n)}.

Your goal is to formulate the next question in an intelligent, complete, and conversational way.

Last question:
"${lastTurn.question}"

Last candidate answer:
"${lastTurn.answer}"

Evaluation of the last answer:
- Score: ${lastTurn.evaluation.overallScore}/100
- Strengths: ${lastStrengths.isEmpty ? 'none relevant' : lastStrengths}
- Improvements: ${lastImprovements.isEmpty ? 'none relevant' : lastImprovements}
- Feedback summary: ${lastSummary.isEmpty ? 'no additional summary' : lastSummary}

Follow-up suggestions already proposed by Gemini:
- $followUpSeed

Real history:
$history

Return ONLY JSON with this exact schema:
{"nextQuestion":"..."}

Mandatory rules for nextQuestion:
- It must be a single question in English.
- It must sound like a real interview question.
- It must have enough context to be spoken out loud.
- It must refer to something concrete from the last answer or ask for an example, decision, metric, trade-off, or result.
- If the score was low, ask for precision, evidence, or a concrete case.
- If the score was high, go deeper with more difficulty or impact.
- Do not repeat the previous question.
- Avoid vague questions like "can you elaborate?" without context.
- No markdown.
'''
        : '''
Actua como entrevistador senior para el rol "$jobRole".
Tipo de entrevista: ${type.label(_l10n)}.

Tu objetivo es formular la siguiente pregunta de forma inteligente, completa y conversacional.

Ultima pregunta:
"${lastTurn.question}"

Ultima respuesta del candidato:
"${lastTurn.answer}"

Evaluacion de la ultima respuesta:
- Score: ${lastTurn.evaluation.overallScore}/100
- Fortalezas: ${lastStrengths.isEmpty ? 'ninguna relevante' : lastStrengths}
- Mejoras: ${lastImprovements.isEmpty ? 'ninguna relevante' : lastImprovements}
- Resumen de feedback: ${lastSummary.isEmpty ? 'sin resumen adicional' : lastSummary}

Sugerencias de follow-up ya propuestas por Gemini:
- $followUpSeed

Historial real:
$history

Devuelve SOLO JSON con este esquema exacto:
{"nextQuestion":"..."}

Reglas obligatorias para nextQuestion:
- Debe ser una sola pregunta en espanol.
- Debe sonar como una pregunta real de entrevista, no como una frase incompleta.
- Debe tener contexto suficiente por si se escucha en voz alta.
- Debe referirse a algo concreto de la ultima respuesta o pedir un ejemplo, decision, metrica, trade-off o resultado.
- Si el score fue bajo, pide precision, evidencia o un caso puntual.
- Si el score fue alto, profundiza con mas dificultad o impacto.
- No repitas la pregunta anterior.
- Evita preguntas vagas como "puedes profundizar?" o "me cuentas mas?" sin contexto.
- Sin markdown.
''';

    final next = await _geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction: _isEnglish
          ? 'You are a human interviewer. Be natural and direct.'
          : 'Eres un entrevistador humano. Se natural y directo.',
      temperature: 0.65,
      maxOutputTokens: 320,
    );

    final parsedFromJson = _tryExtractNextQuestion(next);
    final cleaned = _sanitizeQuestion(parsedFromJson ?? next);
    if (_isSmartInterviewQuestion(
      cleaned,
      previousQuestion: lastTurn.question,
    )) {
      return cleaned;
    }

    for (final candidate in followUps) {
      if (_isSmartInterviewQuestion(
        candidate,
        previousQuestion: lastTurn.question,
      )) {
        return candidate;
      }
    }

    final rewritten = await _rewriteAsStrongerQuestion(
      weakQuestion: cleaned.isEmpty
          ? (followUps.isEmpty ? lastTurn.question : followUps.first)
          : cleaned,
      lastTurn: lastTurn,
      isEnglish: _isEnglish,
      geminiService: _geminiService,
    );
    if (_isSmartInterviewQuestion(
      rewritten,
      previousQuestion: lastTurn.question,
    )) {
      return rewritten;
    }

    throw const GeminiException(
      'No se pudo generar una siguiente pregunta de calidad.',
    );
  }

  Future<String> _generateAlternativeQuestion() async {
    final jobRole = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
    final type = _config.type ?? InterviewConfigType.mixed;
    final history = _formatHistoryForPrompt(_session.turns);

    final prompt = _isEnglish
        ? '''
Act as an expert interviewer for the "$jobRole" role.
Interview type: ${type.label(_l10n)}.

Current question:
"$_currentQuestion"

Real history:
$history

Generate a new question in English to replace the current one.
Rules:
- It must be different from the current question.
- It must keep continuity with the history.
- It must sound natural, concise, and direct.
- No numbering.
- No markdown.
Return ONLY the question text.
'''
        : '''
Actua como entrevistador experto para el rol "$jobRole".
Tipo de entrevista: ${type.label(_l10n)}.

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
      systemInstruction: _isEnglish
          ? 'You are a human interviewer. Be natural and keep the interview flowing.'
          : 'Eres un entrevistador humano. Se natural y mantienes la entrevista fluida.',
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
    if (_isInterviewComplete) return;
    _currentQuestion = question.trim();
    _currentQuestionAskedAt = DateTime.now().toUtc();
    _voiceDraft = '';
    _error = null;
    _emptyVoiceRetries = 0;
    _statusMessage =
        introMessage ??
        (_isEnglish ? 'New question ready.' : 'Nueva pregunta lista.');
    _notifySafely();

    if (_currentQuestion.isEmpty) {
      _setIdle();
      _error = _isEnglish
          ? 'Gemini returned an empty question.'
          : 'Gemini devolvio una pregunta vacia.';
      _notifySafely();
      return;
    }

    if (_isTtsAvailable) {
      try {
        final speechText = introMessage == null
            ? _currentQuestion
            : '$introMessage $_currentQuestion';
        _state = InterviewConversationState.speaking;
        _statusMessage = _isEnglish
            ? 'AI is speaking...'
            : 'La IA esta hablando...';
        _notifySafely();
        await _tts.speak(speechText);
      } catch (e) {
        _isTtsAvailable = false;
        _error = 'Falló TTS: $e';
        _statusMessage = _isEnglish
            ? 'Could not play the question. Continuing with text mode.'
            : 'No se pudo reproducir la pregunta. Continuamos con la version en texto.';
        _setIdle();
        _notifySafely();
      }
    } else {
      _setIdle();
      _statusMessage = _isEnglish
          ? 'The question is available in text. Reply by voice or typing.'
          : 'La pregunta esta disponible en texto. Responde por voz o por escrito.';
      _notifySafely();
    }

    if (_isSpeechAvailable) {
      await _beginListening(clearDraft: true);
    } else {
      _setIdle();
      _statusMessage = _isEnglish
          ? 'Type your answer so Gemini can generate the next question.'
          : 'Escribe tu respuesta para que Gemini genere la siguiente pregunta.';
      _notifySafely();
    }
  }

  Future<void> _beginListening({required bool clearDraft}) async {
    if (!_isSpeechAvailable ||
        _currentQuestion.trim().isEmpty ||
        _isInterviewComplete) {
      return;
    }

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
      _statusMessage = _isEnglish
          ? 'Listening to your answer...'
          : 'Escuchando tu respuesta...';
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
      _statusMessage = _isEnglish
          ? 'You can try again or answer by typing to continue.'
          : 'Puedes volver a intentar o responder por escrito para continuar.';
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
    _statusMessage = _isEnglish
        ? 'Could not transcribe your answer. You can try again.'
        : 'No se pudo transcribir tu respuesta. Puedes intentarlo otra vez.';
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
      _statusMessage = _isEnglish
          ? 'Waiting for your answer.'
          : 'Esperando tu respuesta.';
      _notifySafely();
      return;
    }

    _statusMessage = _isEnglish
        ? 'No voice detected. I will listen again.'
        : 'No detecte voz. Intentare escuchar de nuevo.';
    _error = _isEnglish
        ? 'No clear response detected. Please answer again.'
        : 'No se detectó una respuesta clara. Responde nuevamente por favor.';
    _notifySafely();

    if (_isTtsAvailable) {
      try {
        _state = InterviewConversationState.speaking;
        _notifySafely();
        await _tts.speak(
          _isEnglish
              ? "I couldn't hear you clearly. Please answer again."
              : 'No te escuche con claridad. Responde nuevamente.',
        );
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
      final preferredCandidates = _isEnglish
          ? const ['en-US', 'en-GB', 'en', 'es-ES', 'es-MX', 'es']
          : const ['es-ES', 'es-MX', 'es-US', 'es', 'en-US', 'en'];
      for (final candidate in preferredCandidates) {
        if (normalized.any(
          (lang) => lang.toLowerCase() == candidate.toLowerCase(),
        )) {
          return candidate;
        }
      }

      for (final language in normalized) {
        final prefix = _isEnglish ? 'en' : 'es';
        if (language.toLowerCase().startsWith(prefix)) {
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
        final prefix = _isEnglish ? 'en' : 'es';
        if (!locale.startsWith(prefix)) continue;
        if (name.isEmpty) continue;
        return <String, String>{
          'name': name,
          'locale': '${voice['locale'] ?? (_isEnglish ? 'en-US' : 'es-ES')}',
        };
      }
    } catch (_) {}
    return null;
  }

  String? _pickPreferredSpeechLocale(List<LocaleName> locales) {
    for (final locale in locales) {
      final primary = _isEnglish ? 'en_us' : 'es_es';
      if (locale.localeId.toLowerCase() == primary) return locale.localeId;
    }
    for (final locale in locales) {
      final prefix = _isEnglish ? 'en_' : 'es_';
      if (locale.localeId.toLowerCase().startsWith(prefix)) {
        return locale.localeId;
      }
    }
    return locales.isNotEmpty ? locales.first.localeId : null;
  }

  void _setIdle() {
    _state = InterviewConversationState.idle;
    _soundLevel = 0;
  }

  int _calculateCurrentResponseDurationSeconds() {
    return _calculateResponseDurationSeconds(_currentQuestionAskedAt);
  }

  bool _shouldFinishAfterTurn() {
    final answered = _session.turns.length;
    if (answered >= targetQuestionCount) {
      return true;
    }

    final remaining = remainingInterviewSeconds;
    final averageBudgetPerQuestion =
        (totalInterviewSeconds / targetQuestionCount).round().clamp(45, 180);
    final measuredAverage = answered == 0
        ? averageBudgetPerQuestion
        : (_session.turns.fold<int>(
                    0,
                    (sum, turn) => sum + turn.responseDurationSeconds,
                  ) /
                  answered)
              .round()
              .clamp(30, 180);
    final minimumNeededForAnotherQuestion = math.max(
      40,
      math.min(averageBudgetPerQuestion, measuredAverage + 15),
    );

    return remaining < minimumNeededForAnotherQuestion;
  }

  void _completeInterview({required String reason}) {
    _isInterviewComplete = true;
    _completionReason = reason;
    _currentQuestion = '';
    _currentQuestionAskedAt = null;
    _voiceDraft = '';
    _setIdle();
    _statusMessage = reason;
    _notifySafely();
  }

  String _buildCompletionReason() {
    if (answeredQuestionCount >= targetQuestionCount) {
      return _isEnglish
          ? 'Interview completed: reached $targetQuestionCount questions for ${_config.durationMinutes ?? 3} minutes.'
          : 'Entrevista completada: se alcanzaron $targetQuestionCount preguntas para ${_config.durationMinutes ?? 3} minutos.';
    }
    return _isEnglish
        ? 'Interview completed: not enough remaining time for a quality new question.'
        : 'Entrevista completada: el tiempo restante ya no alcanza para una nueva pregunta con buena calidad.';
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

String? _tryExtractNextQuestion(String raw) {
  final trimmed = raw.trim();
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      final value = decoded['nextQuestion'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  } catch (_) {}

  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    try {
      final decoded = jsonDecode(trimmed.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) {
        final value = decoded['nextQuestion'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (_) {}
  }

  return null;
}

String _sanitizeQuestion(String raw) {
  var value = raw.trim();
  value = value.replaceAll(RegExp("^[\"'`]+|[\"'`]+\$"), '');
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  value = value.replaceFirst(
    RegExp(r'^(Pregunta|Question)\s*:\s*', caseSensitive: false),
    '',
  );
  if (value.isEmpty) return value;
  if (!value.endsWith('?')) {
    value = '$value?';
  }
  return value;
}

bool _isSmartInterviewQuestion(
  String question, {
  required String previousQuestion,
}) {
  final normalized = question.trim().toLowerCase();
  final previous = previousQuestion.trim().toLowerCase();
  if (normalized.isEmpty || normalized == previous) return false;

  final wordCount = normalized
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;
  if (wordCount < 8) return false;

  const vaguePatterns = <String>[
    'puedes profundizar',
    'me cuentas mas',
    'cuentame mas',
    'podrias ampliar',
    'explica mas',
    'por que',
  ];

  if (vaguePatterns.any((pattern) => normalized == '$pattern?')) {
    return false;
  }

  return normalized.contains('?');
}

Future<String> _rewriteAsStrongerQuestion({
  required String weakQuestion,
  required InterviewTurn lastTurn,
  required bool isEnglish,
  required GeminiService geminiService,
}) async {
  final prompt = isEnglish
      ? '''
Rewrite this interview question so it is more complete, specific, and natural.

Weak question:
"$weakQuestion"

Previous question:
"${lastTurn.question}"

Last candidate answer:
"${lastTurn.answer}"

Answer score: ${lastTurn.evaluation.overallScore}/100
Detected improvements: ${lastTurn.evaluation.improvements.join(' | ')}

Return ONLY one question in English.
Rules:
- Exactly one question.
- It must ask for concrete context, example, decision, impact, or result.
- It must not repeat the previous question.
- It should not be vague or too short.
- No markdown.
'''
      : '''
Reescribe esta pregunta de entrevista para que sea mas completa, especifica y natural.

Pregunta debil:
"$weakQuestion"

Pregunta anterior:
"${lastTurn.question}"

Ultima respuesta del candidato:
"${lastTurn.answer}"

Score de la respuesta: ${lastTurn.evaluation.overallScore}/100
Mejoras detectadas: ${lastTurn.evaluation.improvements.join(' | ')}

Devuelve SOLO una pregunta en espanol.
Reglas:
- Una sola pregunta.
- Debe pedir contexto concreto, ejemplo, decision, impacto o resultado.
- No puede repetir la pregunta anterior.
- No debe ser vaga ni demasiado corta.
- Sin markdown.
''';

  final rewritten = await geminiService.sendPrompt(
    prompt: prompt,
    systemInstruction: isEnglish
        ? 'You are a human interviewer. Create clear and specific spoken questions.'
        : 'Eres un entrevistador humano. Formula preguntas orales claras y especificas.',
    temperature: 0.55,
    maxOutputTokens: 180,
  );

  return _sanitizeQuestion(rewritten);
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
