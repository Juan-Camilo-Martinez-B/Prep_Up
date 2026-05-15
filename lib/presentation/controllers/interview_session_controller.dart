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
       _selectedFocusAreas = geminiService.getRandomFocusAreas(
         lookupAppLocalizations(AppLocaleRuntime.locale),
         5,
       ),
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
        throw GeminiException(
          l10n.interviewMissingJobRole,
        );
      }
      final jobRole = _config.jobRole!.label(l10n);
      if (_config.type == null) {
        throw GeminiException(l10n.interviewMissingType);
      }

      final questions = await _geminiService.generateInterviewQuestions(
        type: _config.type!,
        jobRole: jobRole,
        count: 1,
        l10n: l10n,
        selectedFocus: _selectedFocusAreas,
      );

      _currentQuestion = questions.isNotEmpty ? questions.first : '';
      if (_currentQuestion.trim().isEmpty) {
        throw GeminiException(l10n.interviewCouldNotGenerateFirstQuestion);
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
        l10n: l10n,
      );

      final feedback = await _geminiService.generateFeedback(
        question: question,
        userAnswer: safeAnswer,
        evaluation: evaluation,
        l10n: l10n,
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

      final next = await _geminiService.generateNextQuestion(
        jobRole: jobRole,
        type: type,
        turns: _session.turns,
        selectedFocus: _selectedFocusAreas,
        l10n: l10n,
      );

      final cleaned = next.trim();
      if (cleaned.isEmpty) {
        throw GeminiException(
          l10n.interviewCouldNotGenerateQualityQuestion,
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
