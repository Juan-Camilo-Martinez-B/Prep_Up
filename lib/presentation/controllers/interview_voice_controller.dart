import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_feedback_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
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
       _selectedFocusAreas = geminiService.getRandomFocusAreas(5),
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
  final List<String> _selectedFocusAreas;

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
  bool _isSessionCancelled = false;

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
  bool get isStarting => _isStarting;
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
    if (_isStarting || _hasStarted || _isSessionCancelled) return;
    _isStarting = true;
    _isInterviewComplete = false;
    _completionReason = null;
    _error = null;
    _statusMessage = _l10n.interviewPreparing;
    _notifySafely();

    try {
      await _initializeAudio();
      if (_isSessionCancelled) return;

      final openingQuestion = await _generateOpeningQuestion();
      if (_isSessionCancelled) return;

      _hasStarted = true;
      await _deliverQuestion(
        openingQuestion,
        introMessage: _l10n.interviewStarted,
      );
    } catch (e) {
      if (!_isSessionCancelled) {
        _setIdle();
        _error = e.toString();
        _statusMessage = _l10n.interviewCouldNotStart;
        _notifySafely();
      }
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
          ? _l10n.interviewStoppedListeningTryAgain
          : _l10n.interviewReviewTranscriptOrSubmit;
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
    _statusMessage = _l10n.interviewAnswerSavedAndNext;
    _error = null;
    _notifySafely();

    try {
      await _speech.stop();

      final turn = InterviewTurn(
        question: question,
        answer: safeAnswer,
        evaluation: AnswerEvaluationModel.empty,
        feedback: InterviewFeedbackModel.empty,
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
      if (_isSessionCancelled) return;

      await _deliverQuestion(nextQuestion);
    } catch (e) {
      if (!_isSessionCancelled) {
        _setIdle();
        _error = e.toString();
        _statusMessage = _l10n.interviewCouldNotProcess;
        _notifySafely();
      }
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
    _statusMessage = _l10n.interviewAskDifferentQuestion;
    _notifySafely();

    try {
      await _speech.stop();
      await _tts.stop();
      final nextQuestion = await _generateAlternativeQuestion();
      if (_isSessionCancelled) return;

      await _deliverQuestion(
        nextQuestion,
        introMessage: _l10n.interviewDifferentQuestionIntro,
      );
    } catch (e) {
      if (!_isSessionCancelled) {
        _setIdle();
        _error = e.toString();
        _statusMessage = _l10n.interviewCouldNotSkipCurrentQuestion;
        _notifySafely();
      }
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
      introMessage: _l10n.interviewRepeatQuestionIntro,
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
    _isSessionCancelled = true;
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
      _statusMessage = _l10n.interviewCouldNotEnableAiVoice;
      _notifySafely();
    }
  }

  void _configureTtsCallbacks() {
    _tts.setStartHandler(() {
      _state = InterviewConversationState.speaking;
      _statusMessage = _l10n.interviewAiSpeaking;
      _notifySafely();
    });

    _tts.setCompletionHandler(() {
      if (_state == InterviewConversationState.speaking) {
        _statusMessage = _l10n.interviewWaitingAnswer;
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
      _error = '${_l10n.interviewCouldNotPlayAudio} ($message)';
      if (_state == InterviewConversationState.speaking) {
        _setIdle();
      }
      _statusMessage = _l10n.interviewCouldNotPlayAudio;
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
      _error = _l10n.interviewSpeechRecognitionUnavailable;
      _statusMessage = _l10n.interviewContinueTypingFallback;
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
      throw GeminiException(_l10n.interviewMissingJobRole);
    }
    if (_config.type == null) {
      throw GeminiException(_l10n.interviewMissingType);
    }

    final varietyInstructions = _geminiService.getVarietyInstructions(
      _selectedFocusAreas,
      _isEnglish,
    );

    final prompt = _isEnglish
        ? '''
You are a professional and friendly interviewer for the role: "$jobRole".
Introduce yourself briefly and ask the first question for a ${_config.type?.label(_l10n)} interview.
$varietyInstructions
Rules:
- Return ONLY the text of the greeting and the question.
- DO NOT use JSON, markdown, or any other formatting.
- Be natural and professional.
'''
        : '''
Eres un entrevistador profesional y amable para el rol: "$jobRole".
Preséntate brevemente y haz la primera pregunta para una entrevista de tipo ${_config.type?.label(_l10n)}.
$varietyInstructions
Reglas:
- Devuelve SOLO el texto del saludo y la pregunta.
- NO uses JSON, markdown o cualquier otro formato.
- Sé natural y profesional.
''';

    final response = await _geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction: _isEnglish
          ? 'You are a human interviewer. Start with a greeting. Do not use markdown. Be concise but complete.'
          : 'Eres un entrevistador humano. Empieza con un saludo. No uses markdown. Sé conciso pero completa la pregunta.',
      temperature: 0.7,
      maxOutputTokens: 1024,
    );

    final parsedFromJson = _tryExtractNextQuestion(response);
    final question = _sanitizeQuestion(parsedFromJson ?? response);
    if (question.isEmpty) {
      throw GeminiException(_l10n.interviewCouldNotGenerateFirstQuestion);
    }
    return question;
  }

  Future<String> _generateAdaptiveNextQuestion(InterviewTurn lastTurn) async {
    final jobRole = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
    final type = _config.type ?? InterviewType.mixed;
    // Optimize tokens by taking only last 4 turns
    final limitedTurns = _session.turns.length > 4
        ? _session.turns.sublist(_session.turns.length - 4)
        : _session.turns;
    final history = _formatHistoryForPrompt(limitedTurns);
    final varietyInstructions = _geminiService.getVarietyInstructions(
      _selectedFocusAreas,
      _isEnglish,
    );

    final prompt = _isEnglish
        ? '''
Interviewer for "$jobRole" (${type.label(_l10n)}).
Last Q: "${lastTurn.question}"
Candidate A: "${lastTurn.answer}"

Goal: Ask the next question. 
1. Briefly acknowledge or react to the candidate's last answer.
2. Ask a follow-up or a new relevant question.
$varietyInstructions
3. Keep it natural and professional.
4. Return ONLY the text of the reaction and the question. No JSON.

History context:
$history
'''
        : '''
Entrevistador para "$jobRole" (${type.label(_l10n)}).
Ultima Q: "${lastTurn.question}"
Respuesta: "${lastTurn.answer}"

Objetivo: Haz la siguiente pregunta.
1. Reconoce brevemente o reacciona a la última respuesta del candidato.
2. Haz una pregunta de seguimiento o una nueva pregunta relevante.
$varietyInstructions
3. Sé natural y profesional.
4. Devuelve SOLO el texto de la reacción y la pregunta. Sin JSON.

Contexto historial:
$history
''';

    final next = await _geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction: _isEnglish
          ? 'You are a human interviewer. Be natural and direct. Do not use markdown. Ensure the question is finished.'
          : 'Eres un entrevistador humano. Se natural y directo. No uses markdown. Asegúrate de terminar la pregunta.',
      temperature: 0.65,
      maxOutputTokens: 1024,
    );

    final parsedFromJson = _tryExtractNextQuestion(next);
    final cleaned = _sanitizeQuestion(parsedFromJson ?? next);
    if (_isSmartInterviewQuestion(
      cleaned,
      previousQuestion: lastTurn.question,
    )) {
      return cleaned;
    }

    final rewritten = await _rewriteAsStrongerQuestion(
      weakQuestion: cleaned.isEmpty ? lastTurn.question : cleaned,
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

    throw GeminiException(_l10n.interviewCouldNotGenerateQualityQuestion);
  }

  Future<String> _generateAlternativeQuestion() async {
    final jobRole = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
    final type = _config.type ?? InterviewType.mixed;
    final history = _formatHistoryForPrompt(_session.turns);
    final varietyInstructions = _geminiService.getVarietyInstructions(
      _selectedFocusAreas,
      _isEnglish,
    );

    final prompt = _isEnglish
        ? '''
Act as an expert interviewer for the "$jobRole" role.
Interview type: ${type.label(_l10n)}.

Current question:
"$_currentQuestion"

Real history:
$history

Generate a new question in English to replace the current one.
$varietyInstructions
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
$varietyInstructions
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
      throw GeminiException(_l10n.interviewCouldNotGenerateAlternativeQuestion);
    }
    return cleaned;
  }

  Future<void> _deliverQuestion(String question, {String? introMessage}) async {
    if (_isInterviewComplete || _isSessionCancelled) return;
    _currentQuestion = question.trim();
    _currentQuestionAskedAt = DateTime.now().toUtc();
    _voiceDraft = '';
    _error = null;
    _emptyVoiceRetries = 0;
    _statusMessage = introMessage ?? _l10n.interviewQuestionReady;
    _notifySafely();

    if (_currentQuestion.isEmpty) {
      _setIdle();
      _error = _l10n.interviewEmptyQuestion;
      _notifySafely();
      return;
    }

    if (_isTtsAvailable) {
      try {
        final speechText = introMessage == null
            ? _currentQuestion
            : '$introMessage $_currentQuestion';
        _state = InterviewConversationState.speaking;
        _statusMessage = _l10n.interviewAiSpeaking;
        _notifySafely();
        await _tts.speak(speechText);
      } catch (e) {
        _isTtsAvailable = false;
        _error = '${_l10n.interviewCouldNotPlayQuestionTextMode} ($e)';
        _statusMessage = _l10n.interviewCouldNotPlayQuestionTextMode;
        _setIdle();
        _notifySafely();
      }
    } else {
      _setIdle();
      _statusMessage = _l10n.interviewQuestionAvailableInText;
      _notifySafely();
    }

    if (_isSpeechAvailable) {
      await _beginListening(clearDraft: true);
    } else {
      _setIdle();
      _statusMessage = _l10n.interviewTypeAnswerContinue;
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
      _statusMessage = _l10n.interviewListening;
      _error = null;
      _notifySafely();

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(
          seconds: 180,
        ), // Aumentado a 3 minutos máximo por respuesta
        pauseFor: const Duration(
          seconds: 6,
        ), // Aumentado a 6 segundos de silencio antes de cortar
        localeId: _speechLocaleId,
        onSoundLevelChange: _onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false, // Evita que errores menores detengan la escucha
          partialResults: true,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      _setIdle();
      _error = '${_l10n.interviewCouldNotActivateMic} ($e)';
      _statusMessage = _l10n.interviewContinueTypingFallback;
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
    _error = '${_l10n.interviewCouldNotTranscribe} (${error.errorMsg})';
    _statusMessage = _l10n.interviewCouldNotTranscribe;
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
      _error = _l10n.interviewNoVoiceDetectedWrite;
      _statusMessage = _l10n.interviewWaitingAnswer;
      _notifySafely();
      return;
    }

    _statusMessage = _l10n.interviewNoVoiceDetectedRetrying;
    _error = _l10n.interviewNoClearVoice;
    _notifySafely();

    if (_isTtsAvailable) {
      try {
        _state = InterviewConversationState.speaking;
        _notifySafely();
        await _tts.speak(_l10n.interviewCouldNotHearClearly);
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
      return _l10n.interviewQuestionGoalCompleted(
        targetQuestionCount,
        _config.durationMinutes ?? 3,
      );
    }
    return _l10n.interviewTimeCompleted;
  }

  void _notifySafely() {
    if (!_isDisposed && !_isSessionCancelled) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isSessionCancelled = true;
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
  var trimmed = raw.trim();

  // Remove markdown code blocks if present
  if (trimmed.startsWith('```')) {
    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      trimmed = trimmed.substring(firstBrace, lastBrace + 1);
    }
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      final value = decoded['nextQuestion'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  } catch (_) {}

  // Fallback to manual extraction
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

  // Try to extract from JSON if the AI ignored the "no JSON" rule
  final fromJson = _tryExtractNextQuestion(value);
  if (fromJson != null) {
    value = fromJson;
  }

  // Remove markdown code blocks
  value = value.replaceAll(RegExp(r'```(?:json)?|```'), '');

  // Remove common JSON artifacts if they leaked into the string
  value = value.replaceAll(RegExp(r'''\{"nextQuestion":\s*["']?'''), '');
  value = value.replaceAll(RegExp(r'''["']?\}$'''), '');

  // Remove surrounding quotes and excessive whitespace
  value = value.replaceAll(RegExp("^[\"'`]+|[\"'`]+\$"), '');
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Remove technical prefixes
  value = value.replaceFirst(
    RegExp(r'^(Pregunta|Question)\s*:\s*', caseSensitive: false),
    '',
  );

  if (value.isEmpty) return value;

  // Ensure it ends with a question mark if it looks like a question
  if (!value.endsWith('?') &&
      (value.contains('¿') ||
          value.toLowerCase().contains('qué') ||
          value.toLowerCase().contains('cómo'))) {
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
  if (wordCount < 3) return false;

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
    maxOutputTokens: 512,
  );

  return _sanitizeQuestion(rewritten);
}

String _formatHistoryForPrompt(List<InterviewTurn> turns) {
  if (turns.isEmpty) return '- (sin historial)';
  final buffer = StringBuffer();
  for (var i = 0; i < turns.length; i++) {
    final turn = turns[i];
    buffer.writeln('Turno ${i + 1}:');
    buffer.writeln('P: ${turn.question}');
    buffer.writeln('R: ${turn.answer}');
    buffer.writeln('Tiempo de respuesta: ${turn.responseDurationSeconds}s');
    buffer.writeln('');
  }
  return buffer.toString().trim();
}
