import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, required this.results});

  final InterviewResultsModel? results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = this.results;
    if (results == null) {
      return AppScreenScaffold(
        title: 'Recomendaciones',
        background: const TechBackground(),
        body: ListView(
          children: const [
            AppCard(
              title: 'Sin datos',
              subtitle: 'No se recibieron resultados',
              leading: Icon(Icons.info_outline_rounded),
              child: Text('Vuelve a finalizar una entrevista para ver recomendaciones.'),
            ),
          ],
        ),
      );
    }

    return AppScreenScaffold(
      title: 'Recomendaciones',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Sugerencias',
            subtitle: 'Generadas por IA a partir de tu entrevista',
            leading: Icon(Icons.lightbulb_rounded, color: scheme.primary),
            child: Column(
              children: [
                if (results.recommendations.isEmpty)
                  Text(
                    'Sin recomendaciones disponibles.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  )
                else
                  for (final r in results.recommendations) ...[
                    _RecommendationRow(text: r),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (results.improvementTips.isNotEmpty) ...[
            AppCard(
              title: 'Consejos de mejora',
              subtitle: 'Acciones rápidas para tu próxima sesión',
              leading: Icon(Icons.tips_and_updates_rounded, color: scheme.secondary),
              child: Column(
                children: [
                  for (final tip in results.improvementTips) ...[
                    _RecommendationRow(text: tip),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
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
