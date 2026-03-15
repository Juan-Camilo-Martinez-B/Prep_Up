import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class SimulatedCallScreen extends StatefulWidget {
  const SimulatedCallScreen({super.key});

  @override
  State<SimulatedCallScreen> createState() => _SimulatedCallScreenState();
}

class _SimulatedCallScreenState extends State<SimulatedCallScreen> {
  static const _initialSeconds = 180;
  late int _secondsLeft;
  Timer? _timer;

  final _questions = const [
    'Cuéntame sobre ti en 60 segundos.',
    '¿Qué proyecto te entusiasma y por qué?',
    'Describe un reto y cómo lo resolviste.',
  ];
  var _questionIndex = 0;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _initialSeconds;
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
                        Icons.videocam_outlined,
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
                    // TODO: conectar con servicio de IA para generar preguntas de entrevista.
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
                    // TODO: finalizar captura y guardar referencia de video.
                    Navigator.of(context).pushNamed(AppRoutes.interviewProcessing);
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
