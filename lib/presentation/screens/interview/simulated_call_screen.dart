import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/controllers/interview_voice_controller.dart';
import 'package:prep_up/presentation/controllers/media_device_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class SimulatedCallScreen extends StatefulWidget {
  const SimulatedCallScreen({super.key});

  @override
  State<SimulatedCallScreen> createState() => _SimulatedCallScreenState();
}

class _SimulatedCallScreenState extends State<SimulatedCallScreen> {
  late int _secondsLeft;
  Timer? _timer;

  late final InterviewConfig _config;
  late final InterviewVoiceController _voiceController;
  final _answerController = TextEditingController();
  String _syncedQuestion = '';
  var _isFinishingInterview = false;

  @override
  void initState() {
    super.initState();
    _config = context.read<InterviewConfigController>().config;
    final durationMinutes = _config.durationMinutes ?? 3;
    _secondsLeft = durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) return;
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        unawaited(_finishInterview());
      }
    });

    _voiceController = InterviewVoiceController(
      geminiService: GeminiService(),
      config: _config,
      languageCode: AppLocaleRuntime.languageCode,
    );

    _voiceController.addListener(() {
      if (!mounted) return;
      final question = _voiceController.currentQuestion.trim();
      if (question.isNotEmpty && question != _syncedQuestion) {
        _syncedQuestion = question;
        _answerController.clear();
      }

      if (_voiceController.isInterviewComplete) {
        unawaited(_finishInterview());
      }

      if (_voiceController.isListening) {
        final v = _voiceController.voiceDraft;
        if (v.isNotEmpty && _answerController.text != v) {
          _answerController.value = _answerController.value.copyWith(
            text: v,
            selection: TextSelection.collapsed(offset: v.length),
            composing: TextRange.empty,
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final media = context.read<MediaDeviceController>();
      await media.refreshPermissions();
      if (!media.isCameraPermissionGranted ||
          !media.isMicrophonePermissionGranted) {
        await media.requestPermissions();
      }
      await media.initCamera();
      if (!mounted) return;
      await _voiceController.start();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _finishInterview() async {
    if (_isFinishingInterview) return;
    _isFinishingInterview = true;
    await _voiceController.stopConversation();
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      AppRoutes.interviewProcessing,
      arguments: {'config': _config, 'session': _voiceController.session},
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final media = context.watch<MediaDeviceController>();
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return AppScreenScaffold(
      title: l10n.simulatedCallTitle,
      background: const TechBackground(),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _TimerChip(text: '$minutes:$seconds'),
          ),
        ),
      ],
      body: ListView(
        children: [
          Text(
            l10n.simulatedCallLiveHeadline,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  if (media.isCameraReady && media.cameraController != null)
                    CameraPreview(media.cameraController!)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.22),
                            scheme.secondary.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.videocam_off_rounded,
                          size: 56,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: _MiniPreview(scheme: scheme),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: AnimatedBuilder(
                      animation: _voiceController,
                      builder: (context, _) {
                        return _AiAvatar(
                          scheme: scheme,
                          isSpeaking: _voiceController.isSpeaking,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: AnimatedBuilder(
                      animation: _voiceController,
                      builder: (context, _) {
                        return _LiveStatusChip(
                          scheme: scheme,
                          cameraOk: media.isCameraReady,
                          micOk: media.isMicrophonePermissionGranted,
                          micActive: _voiceController.isListening,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: AnimatedBuilder(
                      animation: _voiceController,
                      builder: (context, _) {
                        return _ConversationBadge(
                          scheme: scheme,
                          state: _voiceController.state,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _voiceController,
            builder: (context, _) {
              final state = _voiceController.state;
              final isSpeaking = state == InterviewConversationState.speaking;
              final isListening = state == InterviewConversationState.listening;
              final isProcessing =
                  state == InterviewConversationState.processing;
              final currentQuestionNumber =
                  _voiceController.currentQuestionNumber;
              final totalQuestions = _voiceController.targetQuestionCount;

              return AppCard(
                title: l10n.callStatusTitle,
                subtitle: l10n.callStatusObjective(
                  _voiceController.targetQuestionCount,
                  _config.durationMinutes ?? 3,
                ),
                leading: Icon(Icons.graphic_eq_rounded, color: scheme.primary),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatePill(
                      label: isSpeaking
                          ? l10n.callStateAiSpeaking
                          : l10n.callStateAiWaiting,
                      active: isSpeaking,
                      scheme: scheme,
                      icon: Icons.volume_up_rounded,
                    ),
                    _StatePill(
                      label: isListening
                          ? l10n.callStateUserAnswering
                          : l10n.callStateMicWaiting,
                      active: isListening,
                      scheme: scheme,
                      icon: Icons.mic_rounded,
                    ),
                    _StatePill(
                      label: isProcessing
                          ? l10n.callStateProcessing
                          : l10n.callStateReady,
                      active: isProcessing,
                      scheme: scheme,
                      icon: Icons.auto_awesome_rounded,
                    ),
                    _StatePill(
                      label: l10n.callStateQuestionProgress(
                        currentQuestionNumber,
                        totalQuestions,
                      ),
                      active: true,
                      scheme: scheme,
                      icon: Icons.quiz_rounded,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _voiceController,
            builder: (context, _) {
              final question = _voiceController.currentQuestion.trim();
              final hasQuestion = question.isNotEmpty;
              final currentQuestionNumber =
                  _voiceController.currentQuestionNumber;
              final totalQuestions = _voiceController.targetQuestionCount;
              final isLoading = !hasQuestion && _voiceController.isStarting;

              return AppCard(
                title: l10n.callQuestionCardTitle(
                  currentQuestionNumber,
                  totalQuestions,
                ),
                subtitle: _voiceController.isSpeaking
                    ? l10n.callQuestionSubtitleSpeaking
                    : l10n.callQuestionSubtitleDefault,
                leading: Icon(Icons.smart_toy_outlined, color: scheme.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: totalQuestions <= 0
                            ? 0
                            : (currentQuestionNumber / totalQuestions).clamp(
                                0.0,
                                1.0,
                              ),
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.callQuestionProgressText(
                        currentQuestionNumber,
                        totalQuestions,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const SizedBox(
                        height: 44,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Text(
                        hasQuestion ? question : l10n.callQuestionNoneYet,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _voiceController,
            builder: (context, _) {
              final lastTurn = _voiceController.lastTurn;
              if (lastTurn == null) return const SizedBox.shrink();

              final eval = lastTurn.evaluation;
              final feedback = lastTurn.feedback;

              return AppCard(
                title: l10n.callEvaluationTitle,
                subtitle: l10n.callEvaluationSubtitle,
                leading: Icon(Icons.insights_rounded, color: scheme.secondary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.callScoreLabel(eval.overallScore)),
                    if (eval.strengths.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(l10n.callStrengthsLabel(eval.strengths.join(' • '))),
                    ],
                    if (eval.improvements.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.callImprovementsLabel(
                          eval.improvements.join(' • '),
                        ),
                      ),
                    ],
                    if (feedback.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(l10n.callSummaryLabel(feedback.summary.trim())),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _voiceController,
            builder: (context, _) {
              final isBusy = _voiceController.isProcessing;
              final isListening = _voiceController.isListening;
              final isComplete = _voiceController.isInterviewComplete;
              final questionReady = _voiceController.currentQuestion
                  .trim()
                  .isNotEmpty;
              final canInteract =
                  questionReady && _secondsLeft > 0 && !isBusy && !isComplete;
              final statusMessage = _voiceController.statusMessage.trim();

              return AppCard(
                title: l10n.callYourAnswerTitle,
                subtitle: isListening
                    ? l10n.callYourAnswerSubtitleListening
                    : l10n.callYourAnswerSubtitleFallback,
                leading: Icon(
                  Icons.record_voice_over_rounded,
                  color: scheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _answerController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: l10n.callAnswerFieldLabel,
                        alignLabelWithHint: true,
                        helperText: _voiceController.hasTextToSpeech
                            ? l10n.callAnswerHelperTts
                            : l10n.callAnswerHelperFallback,
                      ),
                      enabled: (canInteract || isListening) && !isComplete,
                    ),
                    if (statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        statusMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: canInteract || isListening
                              ? () async {
                                  await _voiceController.toggleListening();
                                }
                              : null,
                          icon: Icon(
                            isListening
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                          ),
                          label: Text(
                            isListening ? l10n.callMicStop : l10n.callMicTalk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                questionReady &&
                                    _secondsLeft > 0 &&
                                    !isBusy &&
                                    !isComplete
                                ? () async {
                                    await _voiceController
                                        .repeatCurrentQuestion();
                                  }
                                : null,
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(l10n.callRepeatQuestion),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _answerController,
                      builder: (context, value, _) {
                        final canSend =
                            canInteract && value.text.trim().isNotEmpty;

                        return AppPrimaryButton(
                          isExpanded: true,
                          label: l10n.callSendToGemini,
                          icon: Icons.send_rounded,
                          isLoading: isBusy,
                          onPressed: canSend
                              ? () async {
                                  await _voiceController.submitAnswer(
                                    value.text,
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                    if (_voiceController.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _voiceController.error!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: scheme.error),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _voiceController.clearError();
                          },
                          child: Text(l10n.genericClose),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              questionReady && _secondsLeft > 0 && !isComplete
                              ? () async {
                                  await _voiceController.retryListening();
                                }
                              : null,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.callRetryVoice),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _voiceController.isInterviewComplete
                      ? null
                      : () async {
                          await _voiceController.skipQuestion();
                          _answerController.clear();
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(l10n.callSkip),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _finishInterview,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.call_end_rounded),
                  label: Text(l10n.callHangUp),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.callTip,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.60),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Center(
        child: Icon(
          Icons.face_rounded,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({required this.scheme, required this.isSpeaking});

  final ColorScheme scheme;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isSpeaking ? scheme.primary : scheme.primaryContainer)
                  .withValues(alpha: 0.30),
            ),
            child: Icon(
              isSpeaking ? Icons.volume_up_rounded : Icons.smart_toy_outlined,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isSpeaking ? l10n.callBadgeSpeaking : l10n.callAiInterviewerLabel,
          ),
        ],
      ),
    );
  }
}

class _LiveStatusChip extends StatelessWidget {
  const _LiveStatusChip({
    required this.scheme,
    required this.cameraOk,
    required this.micOk,
    required this.micActive,
  });

  final ColorScheme scheme;
  final bool cameraOk;
  final bool micOk;
  final bool micActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.60),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            cameraOk ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            size: 18,
            color: cameraOk ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Icon(
            micOk ? Icons.mic_rounded : Icons.mic_off_rounded,
            size: 18,
            color: !micOk
                ? scheme.onSurfaceVariant
                : micActive
                ? scheme.secondary
                : scheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            micActive ? l10n.callMicActive : l10n.callMicReady,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ConversationBadge extends StatelessWidget {
  const _ConversationBadge({required this.scheme, required this.state});

  final ColorScheme scheme;
  final InterviewConversationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, text, color) = switch (state) {
      InterviewConversationState.speaking => (
        Icons.volume_up_rounded,
        l10n.callBadgeSpeaking,
        scheme.primary,
      ),
      InterviewConversationState.listening => (
        Icons.mic_rounded,
        l10n.callBadgeListening,
        scheme.secondary,
      ),
      InterviewConversationState.processing => (
        Icons.auto_awesome_rounded,
        l10n.callBadgeProcessing,
        scheme.tertiary,
      ),
      InterviewConversationState.idle => (
        Icons.pause_circle_outline_rounded,
        l10n.callBadgeIdle,
        scheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.70),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
    required this.active,
    required this.scheme,
    required this.icon,
  });

  final String label;
  final bool active;
  final ColorScheme scheme;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.60),
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
