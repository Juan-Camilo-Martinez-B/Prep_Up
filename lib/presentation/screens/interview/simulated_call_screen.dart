import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
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

  late final List<String> _questions;
  var _questionIndex = 0;
  late final InterviewConfig _config;

  @override
  void initState() {
    super.initState();
    _config = context.read<InterviewConfigController>().config;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaDeviceController>().start();
    });
    final durationMinutes = _config.durationMinutes ?? 3;
    _secondsLeft = durationMinutes * 60;
    _questions = _buildQuestions(_config);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) return;
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = context.watch<MediaDeviceController>();
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final question = _questions[_questionIndex % _questions.length];

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
          AppCard(
            title: 'Pregunta',
            subtitle: 'Entrevistador IA (simulado)',
            leading: Icon(Icons.smart_toy_outlined, color: scheme.primary),
            child: Text(
              question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _questionIndex += 1);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Siguiente'),
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
                      arguments: _config,
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

List<String> _buildQuestions(InterviewConfig config) {
  return switch (config.type) {
    InterviewConfigType.technical => const [
        'Explícame una decisión técnica clave que tomaste recientemente.',
        '¿Cómo diagnosticarías un bug intermitente en producción?',
        '¿Qué trade-offs evaluas al diseñar una API?',
      ],
    InterviewConfigType.rrhh => const [
        'Cuéntame sobre ti en 60 segundos.',
        'Describe un conflicto en equipo y cómo lo resolviste.',
        '¿Cuál es tu mayor fortaleza profesional y por qué?',
      ],
    InterviewConfigType.mixed || null => const [
        'Cuéntame sobre ti en 60 segundos.',
        '¿Qué proyecto te entusiasma y por qué?',
        'Describe un reto técnico y cómo lo resolviste.',
      ],
  };
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
