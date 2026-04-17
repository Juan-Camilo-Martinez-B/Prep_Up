import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class InterviewConfigurationScreen extends StatefulWidget {
  const InterviewConfigurationScreen({super.key});

  @override
  State<InterviewConfigurationScreen> createState() =>
      _InterviewConfigurationScreenState();
}

class _InterviewConfigurationScreenState
    extends State<InterviewConfigurationScreen> {
  double _timeLimitMinutes = 8;

  @override
  void initState() {
    super.initState();
    final controller = context.read<InterviewConfigController>();
    final initialDuration = controller.config.durationMinutes ?? 8;
    _timeLimitMinutes = initialDuration.toDouble();
    if (controller.config.durationMinutes == null) {
      controller.setDurationMinutes(initialDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<InterviewConfigController>();
    final config = controller.config;
    final timeLimitSeconds = (_timeLimitMinutes.round()) * 60;

    return AppScreenScaffold(
      title: 'Configurar entrevista',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Ajustes rápidos',
            subtitle: 'Define duración y modalidad',
            leading: Icon(Icons.tune_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiempo límite: ${_timeLimitMinutes.round()} min'),
                Slider(
                  value: _timeLimitMinutes,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: '${_timeLimitMinutes.round()} min',
                  onChanged: (v) {
                    setState(() => _timeLimitMinutes = v);
                    controller.setDurationMinutes(v.round());
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Modalidad',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final mode in InterviewMode.values)
                      ChoiceChip(
                        label: Text(mode.label),
                        selected: config.mode == mode,
                        onSelected: (_) => controller.setMode(mode),
                      ),
                  ],
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
                  icon: Icons.record_voice_over_rounded,
                  title: 'Tipo',
                  value: config.type?.label ?? '-',
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.timer_rounded,
                  title: 'Tiempo',
                  value: '${timeLimitSeconds ~/ 60} min',
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.work_outline_rounded,
                  title: 'Cargo',
                  value: config.jobRole == null ? '-' : config.jobRole!.label,
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'Modalidad',
                  value: config.mode?.label ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (!controller.isComplete) {
                final missing = controller.config.missingFields.join(', ');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Completa estos campos: $missing'),
                  ),
                );
                return;
              }
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
