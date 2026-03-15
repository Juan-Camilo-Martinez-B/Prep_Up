import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class InterviewConfigurationScreen extends StatefulWidget {
  const InterviewConfigurationScreen({super.key});

  @override
  State<InterviewConfigurationScreen> createState() =>
      _InterviewConfigurationScreenState();
}

class _InterviewConfigurationScreenState
    extends State<InterviewConfigurationScreen> {
  double _questionCount = 6;
  double _timeLimitMinutes = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final questionCount = _questionCount.round();
    final timeLimitSeconds = (_timeLimitMinutes.round()) * 60;

    return AppScreenScaffold(
      title: 'Configurar entrevista',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Ajustes rápidos',
            subtitle: 'Define el ritmo de la simulación',
            leading: Icon(Icons.tune_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cantidad de preguntas: $questionCount'),
                Slider(
                  value: _questionCount,
                  min: 3,
                  max: 12,
                  divisions: 9,
                  label: '$questionCount',
                  onChanged: (v) => setState(() => _questionCount = v),
                ),
                const SizedBox(height: 12),
                Text('Tiempo límite: ${_timeLimitMinutes.round()} min'),
                Slider(
                  value: _timeLimitMinutes,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: '${_timeLimitMinutes.round()} min',
                  onChanged: (v) => setState(() => _timeLimitMinutes = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Vista previa',
            subtitle: 'Lo que vas a entrenar',
            leading: Icon(Icons.preview_rounded, color: scheme.secondary),
            child: Column(
              children: [
                _PreviewTile(
                  icon: Icons.quiz_rounded,
                  title: 'Preguntas',
                  value: '$questionCount',
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.timer_rounded,
                  title: 'Tiempo',
                  value: '${timeLimitSeconds ~/ 60} min',
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'Entrevistador',
                  value: 'IA (simulada)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              // TODO: guardar configuración en sesión de entrevista.
              Navigator.of(context).pushNamed(AppRoutes.deviceCheck);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Atrás'),
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.primary.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}
