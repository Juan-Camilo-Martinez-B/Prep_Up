import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const recommendations = [
      'Responde con estructura: situación → acción → resultado.',
      'Reduce muletillas: respira y pausa 1 segundo antes de responder.',
      'Cierra con impacto: métricas, aprendizajes y siguiente paso.',
      'Sonríe al iniciar, mejora la percepción de seguridad.',
    ];

    return AppScreenScaffold(
      title: 'Recomendaciones',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Sugerencias',
            subtitle: 'Entrena en 10 minutos al día',
            leading: Icon(Icons.lightbulb_rounded, color: scheme.primary),
            child: Column(
              children: [
                for (final r in recommendations) ...[
                  _RecommendationRow(text: r),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Siguiente sesión',
            subtitle: 'Repite y sube tu score',
            leading: Icon(Icons.replay_rounded, color: scheme.secondary),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.repeatInterview),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Repetir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Dashboard',
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.dashboard,
                      (r) => false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
