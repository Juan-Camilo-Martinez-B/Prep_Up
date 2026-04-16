import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class GeneralResultsScreen extends StatelessWidget {
  const GeneralResultsScreen({super.key, required this.results});

  final InterviewResultsModel? results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = this.results;
    if (results == null) {
      return AppScreenScaffold(
        title: 'Resultados',
        background: const TechBackground(),
        body: ListView(
          children: const [
            AppCard(
              title: 'Resultados generales',
              subtitle: 'No se recibieron datos',
              leading: Icon(Icons.info_outline_rounded),
              child: Text('Vuelve a finalizar una entrevista para ver resultados.'),
            ),
          ],
        ),
      );
    }

    final score = results.overallScore;
    final outcomeLabel = switch (results.outcome) {
      InterviewOutcome.approved => 'Aprobado',
      InterviewOutcome.improve => 'Mejorar',
    };
    final outcomeColor = results.outcome == InterviewOutcome.approved
        ? scheme.primary
        : scheme.secondary;

    return AppScreenScaffold(
      title: 'Resultados',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Resultados generales',
            subtitle: 'Resumen de tu entrevista',
            leading: Icon(Icons.insights_rounded, color: scheme.primary),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 10,
                        ),
                      ),
                      Center(
                        child: Text(
                          '$score',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        outcomeLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estado',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        outcomeLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: outcomeColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Highlights',
            subtitle: 'Lo más destacado',
            leading: Icon(Icons.star_rounded, color: scheme.secondary),
            child: Column(
              children: results.highlights.isEmpty
                  ? [
                      Text(
                        'Sin highlights disponibles.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ]
                  : [
                      for (final h in results.highlights) ...[
                        _Highlight(text: h),
                        const SizedBox(height: 8),
                      ],
                    ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Ver análisis detallado',
            icon: Icons.analytics_rounded,
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.detailedAnalysis,
              arguments: results,
            ),
          ),
          const SizedBox(height: 10),
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

class _Highlight extends StatelessWidget {
  const _Highlight({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: scheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
