import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:prep_up/core/utils/ai_utils.dart';
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
       _selectedFocusAreas = geminiService.getRandomFocusAreas(
         lookupAppLocalizations(Locale(languageCode)),
         5,
       ),
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
  String _previousVoiceText = '';
  String _lastSubmittedAnswer = '';
  String _statusMessage = '';
  String? _error;
  bool _isSpeechAvailable = false;
  bool _isTtsAvailable = true;
  bool _isStarting = false;
  bool _isDisposed = false;
  bool _hasStarted = false;
  bool _isTtsConfigured = false;
  bool _isAiSpeaking = false;
  double _soundLevel = 0;
  String? _speechLocaleId;
  DateTime? _currentQuestionAskedAt;
  bool _isInterviewComplete = false;
  bool _isFinishing = false;
  String? _completionReason;
  bool _isSessionCancelled = false;
  Timer? _silenceTimer;

  InterviewSession get session => _session;
  InterviewConversationState get state => _state;
  String get currentQuestion => _currentQuestion;
  String get voiceDraft => _voiceDraft;
  String get lastSubmittedAnswer => _lastSubmittedAnswer;
  String get statusMessage => _statusMessage;
  String? get error => _error;
  double get soundLevel => _soundLevel;
  bool get isInterviewComplete => _isInterviewComplete;
  bool get isFinishing => _isFinishing;
  String? get completionReason => _completionReason;
  int get targetQuestionCount =>
      _estimateQuestionCount(_config.durationMinutes ?? 3);
  int get answeredQuestionCount => _session.turns.length;
  int get currentQuestionNumber {
    if (_isInterviewComplete || _isFinishing) {
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
        _error = userFriendlyErrorMessage(e, _l10n);
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

    await _beginListening(clearDraft: false, stopTts: true);
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

    _cancelSilenceTimer();
    _voiceDraft = safeAnswer;
    _previousVoiceText = '';
    _lastSubmittedAnswer = safeAnswer;
    _state = InterviewConversationState.processing;
    _statusMessage = _l10n.interviewAnswerSavedAndNext;
    _error = null;
    _notifySafely();

    try {
      // Detener cualquier audio o escucha antes de procesar
      await _tts.stop();
      await _speech.stop();

      final evaluation = await _geminiService.evaluateUserAnswer(
        question: question,
        userAnswer: safeAnswer,
        role: _config.jobRole,
        jobRoleLabel: _config.jobRole?.label(_l10n) ?? '',
        l10n: _l10n,
        type: _config.type ?? InterviewType.mixed,
      );

      final feedback = await _geminiService.generateFeedback(
        question: question,
        userAnswer: safeAnswer,
        evaluation: evaluation,
        role: _config.jobRole,
        jobRoleLabel: _config.jobRole?.label(_l10n) ?? '',
        l10n: _l10n,
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
        await _completeInterview(reason: _buildCompletionReason());
        return;
      }

      final nextQuestion = await _generateAdaptiveNextQuestion(turn);
      if (_isSessionCancelled) return;

      await _deliverQuestion(nextQuestion);
    } catch (e) {
      if (!_isSessionCancelled) {
        _setIdle();
        _error = userFriendlyErrorMessage(e, _l10n);
        _statusMessage = _l10n.interviewCouldNotProcess;
        _notifySafely();
      }
    }
  }

  Future<void> repeatCurrentQuestion() async {
    final question = _currentQuestion.trim();
    if (question.isEmpty || isProcessing || _isInterviewComplete) return;

    await _speech.stop();
    _voiceDraft = '';
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
    await _beginListening(clearDraft: true, stopTts: true);
  }

  Future<void> finishInterviewGracefully() async {
    if (_isFinishing || _isInterviewComplete) return;
    await _completeInterview(reason: _buildCompletionReason());
  }

  Future<void> stopConversation() async {
    _isSessionCancelled = true;
    _hasStarted = false;
    _isInterviewComplete = false;
    _isAiSpeaking = false;
    _setIdle();
    _statusMessage = '';
    _voiceDraft = '';
    _soundLevel = 0;
    _notifySafely();

    // Detener motores de audio inmediatamente
    try {
      // Primero cancelamos el reconocimiento de voz para liberar el micro lo antes posible
      if (_speech.isListening || _speech.isAvailable) {
        await _speech.stop();
        await _speech.cancel();
      }

      // Detenemos el TTS
      await _tts.stop();

      // Pequeña pausa para asegurar que los drivers de audio se liberen
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error stopping conversation: $e');
    }
  }

  /// Pauses TTS and STT immediately when the user starts interacting manually (e.g. typing).
  void onUserInteractionStarted() {
    if (isSpeaking || isListening) {
      unawaited(_tts.stop());
      unawaited(_speech.stop());
      _setIdle();
      _statusMessage = _l10n.interviewWaitingAnswer;
      _notifySafely();
    }
  }

  void updateVoiceDraft(String text) {
    if (_voiceDraft != text) {
      _voiceDraft = text;
      _previousVoiceText = text;
      _notifySafely();
    }
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

      _configureTtsCallbacks();
    } catch (_) {
      _isTtsAvailable = false;
      _statusMessage = _l10n.interviewCouldNotEnableAiVoice;
      _notifySafely();
    }
  }

  void _configureTtsCallbacks() {
    _tts.setStartHandler(() {
      _isAiSpeaking = true;
      _state = InterviewConversationState.speaking;
      _statusMessage = _l10n.interviewAiSpeaking;
      _notifySafely();
    });

    _tts.setCompletionHandler(() {
      _isAiSpeaking = false;
      if (_state == InterviewConversationState.speaking) {
        _statusMessage = _l10n.interviewWaitingAnswer;
        _notifySafely();
      }
    });

    _tts.setCancelHandler(() {
      _isAiSpeaking = false;
      if (_state == InterviewConversationState.speaking) {
        _setIdle();
        _notifySafely();
      }
    });

    _tts.setErrorHandler((message) {
      _isAiSpeaking = false;
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
    final jobRoleLabel = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
    if (jobRoleLabel.isEmpty) {
      throw GeminiException(_l10n.interviewMissingJobRole);
    }
    if (_config.type == null) {
      throw GeminiException(_l10n.interviewMissingType);
    }

    final response = await _geminiService.generateOpeningQuestion(
      role: _config.jobRole,
      jobRoleLabel: jobRoleLabel,
      type: _config.type!,
      selectedFocus: _selectedFocusAreas,
      l10n: _l10n,
    );

    final parsedFromJson = _tryExtractNextQuestion(response);
    final question = _sanitizeQuestion(parsedFromJson ?? response);
    if (question.isEmpty) {
      throw GeminiException(_l10n.interviewCouldNotGenerateFirstQuestion);
    }
    return question;
  }

  Future<String> _generateAdaptiveNextQuestion(InterviewTurn lastTurn) async {
    final jobRoleLabel = _config.jobRole == null
        ? ''
        : _config.jobRole!.label(_l10n);
    final type = _config.type ?? InterviewType.mixed;
    // Optimize tokens by taking only last 4 turns
    final limitedTurns = _session.turns.length > 4
        ? _session.turns.sublist(_session.turns.length - 4)
        : _session.turns;

    final next = await _geminiService.generateConversationalNextQuestion(
      role: _config.jobRole,
      jobRoleLabel: jobRoleLabel,
      type: type,
      lastQuestion: lastTurn.question,
      lastAnswer: lastTurn.answer,
      turns: limitedTurns,
      selectedFocus: _selectedFocusAreas,
      l10n: _l10n,
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

  Future<void> _deliverQuestion(String question, {String? introMessage}) async {
    if (_isInterviewComplete || _isSessionCancelled) return;
    _currentQuestion = question.trim();
    _currentQuestionAskedAt = DateTime.now().toUtc();
    _voiceDraft = '';
    _previousVoiceText = '';
    _error = null;
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

        // Esperar a que el TTS termine realmente antes de seguir
        await _tts.speak(speechText);

        // Loop de espera activa hasta que el TTS termine de hablar o se cancele la sesión
        // Esto previene que comience el STT mientras el TTS sigue activo
        while (_isAiSpeaking &&
            !_isSessionCancelled &&
            _state == InterviewConversationState.speaking) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Pequeño delay de seguridad adicional para el post-procesamiento de audio del sistema
        if (!_isSessionCancelled &&
            _state == InterviewConversationState.speaking) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      } catch (e) {
        _isTtsAvailable = false;
        _error = _l10n.interviewCouldNotPlayQuestionTextMode;
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
      // Pasamos false para que no intente detener un TTS que ya debería haber terminado
      await _beginListening(clearDraft: true, stopTts: false);
    } else {
      _setIdle();
      _statusMessage = _l10n.interviewTypeAnswerContinue;
      _notifySafely();
    }
  }

  Future<void> _beginListening({
    required bool clearDraft,
    bool stopTts = true,
  }) async {
    if (!_isSpeechAvailable ||
        _currentQuestion.trim().isEmpty ||
        _isInterviewComplete) {
      return;
    }

    try {
      if (stopTts) {
        await _tts.stop();
      }
      await _speech.stop();

      if (clearDraft) {
        _voiceDraft = '';
        _previousVoiceText = '';
      } else {
        _previousVoiceText = _voiceDraft.trim();
      }

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
      _resetSilenceTimer();
    } catch (e) {
      _setIdle();
      _error = _l10n.interviewCouldNotActivateMic;
      _statusMessage = _l10n.interviewContinueTypingFallback;
      _notifySafely();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (_isSessionCancelled) return;
    final transcript = result.recognizedWords.trim();
    final currentFullText = _previousVoiceText.isEmpty
        ? transcript
        : '$_previousVoiceText $transcript'.trim();

    if (currentFullText != _voiceDraft) {
      _voiceDraft = currentFullText;
      _notifySafely();
      _resetSilenceTimer();
    }
  }

  void _onSpeechStatus(String status) {
    if (!isListening || _isSessionCancelled) return;
    if (status == 'done' || status == 'notListening') {
      unawaited(_restartListeningIfNeeded());
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!isListening || _isSessionCancelled) return;
    debugPrint('Speech recognition error: ${error.errorMsg}');
    unawaited(_restartListeningIfNeeded());
  }

  Future<void> _restartListeningIfNeeded() async {
    if (!isListening || _isSessionCancelled) return;

    _previousVoiceText = _voiceDraft.trim();
    
    // Esperar un momento (200ms) para que el motor nativo libere recursos de audio por completo
    await Future.delayed(const Duration(milliseconds: 200));
    if (!isListening || _isSessionCancelled) return;

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 180),
        pauseFor: const Duration(seconds: 6),
        localeId: _speechLocaleId,
        onSoundLevelChange: _onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          autoPunctuation: true,
        ),
      );
      _resetSilenceTimer();
    } catch (e) {
      debugPrint('Error restarting speech recognition: $e');
      _setIdle();
      _notifySafely();
    }
  }

  void _onSoundLevelChange(double level) {
    if (!isListening) return;
    _soundLevel = level;
    _notifySafely();
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
    _cancelSilenceTimer();
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
    if (remaining <= 0) {
      return true;
    }

    return false;
  }

  Future<void> _completeInterview({required String reason}) async {
    if (_isFinishing || _isInterviewComplete) return;

    _isFinishing = true;
    _completionReason = reason;
    _voiceDraft = '';
    _statusMessage = reason;
    _notifySafely();

    String finalMessage = reason;

    // Generar un cierre natural con IA si es posible
    try {
      if (_isSessionCancelled) return;
      final jobRoleLabel = _config.jobRole?.label(_l10n) ?? '';
      final closingMsg = await _geminiService.generateClosingMessage(
        role: _config.jobRole,
        jobRoleLabel: jobRoleLabel,
        l10n: _l10n,
      );
      if (_isSessionCancelled) return;
      if (closingMsg.isNotEmpty) {
        finalMessage = closingMsg;
      }
    } catch (e) {
      debugPrint('Error generating closing message: $e');
    }

    if (_isSessionCancelled) return;
    _currentQuestion = finalMessage;
    _currentQuestionAskedAt = null;
    _notifySafely();

    // Entregar el mensaje final por TTS si está disponible
    if (_isTtsAvailable && !_isSessionCancelled) {
      try {
        _state = InterviewConversationState.speaking;
        _statusMessage = _l10n.interviewAiSpeaking;
        _isAiSpeaking = true;
        _notifySafely();

        await _tts.speak(finalMessage);

        // Esperamos a que termine de hablar o se cancele
        while (_isAiSpeaking && !_isSessionCancelled) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (_) {
        _isTtsAvailable = false;
      }
    } else if (!_isSessionCancelled) {
      // Si no hay voz, esperamos un tiempo razonable para que el usuario lea el mensaje
      await Future.delayed(const Duration(seconds: 3));
    }

    if (_isSessionCancelled) return;
    _setIdle();
    _isInterviewComplete = true;
    _isFinishing = false;
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

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (!isListening || _isSessionCancelled) return;

    _silenceTimer = Timer(const Duration(seconds: 4), () {
      if (!isListening || _isSessionCancelled) return;
      final finalAnswer = _voiceDraft.trim();
      if (finalAnswer.isNotEmpty) {
        unawaited(submitAnswer(finalAnswer));
      }
    });
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  @override
  void dispose() {
    _isSessionCancelled = true;
    _isDisposed = true;
    _cancelSilenceTimer();
    _speech.cancel();
    _tts.stop();
    super.dispose();
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
      if (decoded is Map && decoded['nextQuestion'] != null) {
        return '${decoded['nextQuestion']}';
      }
      if (decoded is Map && decoded['question'] != null) {
        return '${decoded['question']}';
      }
    } catch (_) {}

    return null;
  }

  String _sanitizeQuestion(String raw) {
    // Use the centralized AI utility for robust cleaning
    var value = AiUtils.sanitizeAIText(raw, _l10n);

    if (value.isEmpty) return value;

    // Remove technical prefixes that might leak
    value = value.replaceFirst(
      RegExp(r'^(Pregunta|Question|AI)\s*:\s*', caseSensitive: false),
      '',
    );

    // Ensure it ends with a question mark if it looks like a question
    if (!value.endsWith('?') &&
        (value.contains('¿') ||
            value.toLowerCase().contains('qué') ||
            value.toLowerCase().contains('cómo') ||
            value.toLowerCase().contains('cuál') ||
            value.toLowerCase().contains('donde') ||
            value.toLowerCase().contains('quién') ||
            value.toLowerCase().contains('por qué'))) {
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

    return normalized.contains('?');
  }

  Future<String> _rewriteAsStrongerQuestion({
    required String weakQuestion,
    required InterviewTurn lastTurn,
    required bool isEnglish,
    required GeminiService geminiService,
  }) async {
    final prompt = _l10n.aiPromptRewriteQuestion(
      weakQuestion,
      lastTurn.question,
      lastTurn.answer,
    );

    final rewritten = await geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction: _l10n.aiPromptSystemInterviewerSpoken,
      temperature: 0.55,
      maxOutputTokens: 512,
    );

    return _sanitizeQuestion(rewritten);
  }
}
