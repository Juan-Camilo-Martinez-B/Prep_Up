import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/controllers/interview_session_controller.dart';
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
  late final InterviewSessionController _sessionController;
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _config = context.read<InterviewConfigController>().config;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaDeviceController>().start();
    });
    final durationMinutes = _config.durationMinutes ?? 3;
    _secondsLeft = durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) return;
      setState(() => _secondsLeft -= 1);
    });

    _sessionController = InterviewSessionController(
      geminiService: GeminiService(),
      config: _config,
    );

    _sessionController.addListener(() {
      if (!mounted) return;
      if (_sessionController.isListening) {
        final v = _sessionController.voiceDraft;
        if (v.isNotEmpty && _answerController.text != v) {
          _answerController.value = _answerController.value.copyWith(
            text: v,
            selection: TextSelection.collapsed(offset: v.length),
            composing: TextRange.empty,
          );
        }
      }
    });

    _sessionController.start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = context.watch<MediaDeviceController>();
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return AppScreenScaffold(
      title: 'Videollamada',
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
            'Simulación en vivo',
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
                    child: _AiAvatar(scheme: scheme),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: _LiveStatusChip(
                      scheme: scheme,
                      cameraOk: media.isCameraReady,
                      micOk: media.isMicrophoneReady,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _sessionController,
            builder: (context, _) {
              final question = _sessionController.currentQuestion.trim();
              final hasQuestion = question.isNotEmpty;
              final isLoading = _sessionController.isStarting && !hasQuestion;

              return AppCard(
                title: 'Pregunta',
                subtitle: 'Entrevistador IA',
                leading: Icon(Icons.smart_toy_outlined, color: scheme.primary),
                child: isLoading
                    ? const SizedBox(
                        height: 44,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Text(
                        hasQuestion ? question : 'No hay pregunta aún.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              );
            },
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _sessionController,
            builder: (context, _) {
              final lastTurn = _sessionController.lastTurn;
              if (lastTurn == null) return const SizedBox.shrink();

              final eval = lastTurn.evaluation;
              final feedback = lastTurn.feedback;

              return AppCard(
                title: 'Evaluación',
                subtitle: 'Feedback en tiempo real',
                leading: Icon(Icons.insights_rounded, color: scheme.secondary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${eval.overallScore}/100'),
                    if (eval.strengths.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Fortalezas: ${eval.strengths.join(' • ')}'),
                    ],
                    if (eval.improvements.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Mejoras: ${eval.improvements.join(' • ')}'),
                    ],
                    if (feedback.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Resumen: ${feedback.summary.trim()}'),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _sessionController,
            builder: (context, _) {
              final isBusy =
                  _sessionController.isSubmitting || _sessionController.isGeneratingNext;
              final isListening = _sessionController.isListening;
              final questionReady =
                  _sessionController.currentQuestion.trim().isNotEmpty;

              return AppCard(
                title: 'Tu respuesta',
                subtitle: isListening ? 'Escuchando...' : 'Texto o voz',
                leading: Icon(Icons.record_voice_over_rounded, color: scheme.primary),
                child: Column(
                  children: [
                    TextField(
                      controller: _answerController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Escribe tu respuesta',
                        alignLabelWithHint: true,
                      ),
                      enabled: questionReady && _secondsLeft > 0 && !isBusy,
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _answerController,
                      builder: (context, value, _) {
                        final canSend = questionReady &&
                            _secondsLeft > 0 &&
                            !isBusy &&
                            value.text.trim().isNotEmpty;

                        return Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  (!questionReady || _secondsLeft <= 0 || isBusy)
                                      ? null
                                      : () async {
                                          await _sessionController
                                              .toggleListening();
                                        },
                              icon: Icon(
                                isListening
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                              ),
                              label: Text(isListening ? 'Detener' : 'Hablar'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppPrimaryButton(
                                isExpanded: true,
                                label: 'Enviar',
                                icon: Icons.send_rounded,
                                isLoading: isBusy,
                                onPressed: canSend
                                    ? () async {
                                        final text = value.text;
                                        await _sessionController
                                            .submitAnswer(text);
                                        if (_sessionController.error == null) {
                                          _answerController.clear();
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_sessionController.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _sessionController.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _sessionController.clearError();
                          },
                          child: const Text('Cerrar'),
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
                  onPressed: () async {
                    await _sessionController.generateNextQuestion();
                    _answerController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Omitir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  isExpanded: true,
                  label: 'Finalizar',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.interviewProcessing,
                      arguments: {
                        'config': _config,
                        'session': _sessionController.session,
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tip: mira a cámara, responde con estructura y mantén un ritmo natural.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge,
          ),
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
  const _AiAvatar({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
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
              color: scheme.primary.withValues(alpha: 0.20),
            ),
            child: Icon(Icons.smart_toy_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          const Text('Entrevistador IA'),
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
  });

  final ColorScheme scheme;
  final bool cameraOk;
  final bool micOk;

  @override
  Widget build(BuildContext context) {
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
            color: micOk ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
