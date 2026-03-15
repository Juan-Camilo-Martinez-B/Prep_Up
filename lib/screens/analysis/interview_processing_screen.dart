import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class InterviewProcessingScreen extends StatefulWidget {
  const InterviewProcessingScreen({super.key});

  @override
  State<InterviewProcessingScreen> createState() =>
      _InterviewProcessingScreenState();
}

class _InterviewProcessingScreenState extends State<InterviewProcessingScreen> {
  Timer? _timer;
  var _progress = 0.12;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 380), (_) {
      if (!mounted) return;
      setState(() {
        _progress = (_progress + 0.07).clamp(0.0, 0.96);
      });
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

    return AppScreenScaffold(
      title: 'Analizando',
      background: const TechBackground(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analizando tu entrevista con IA...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Procesando audio, video y estructura de respuestas (simulado).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.memory_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modelo: InterviewSim-v0.1',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${(_progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Ver resultados',
            icon: Icons.insights_rounded,
            onPressed: () {
              // TODO: reemplazar por navegación automática tras finalizar análisis real.
              Navigator.of(context).pushNamed(AppRoutes.generalResults);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.dashboard,
              (r) => false,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Volver al Dashboard'),
          ),
        ],
      ),
    );
  }
}
