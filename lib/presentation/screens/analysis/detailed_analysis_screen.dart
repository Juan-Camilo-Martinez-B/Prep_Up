import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/presentation/widgets/interview_statistics_widgets.dart';

class DetailedAnalysisScreen extends StatelessWidget {
  const DetailedAnalysisScreen({
    super.key,
    required this.results,
    this.session,
  });

  final InterviewResultsModel? results;
  final InterviewSession? session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = this.results;
    if (results == null) {
      return AppScreenScaffold(
        title: 'Análisis detallado',
        background: const TechBackground(),
        body: ListView(
          children: const [
            AppCard(
              title: 'Sin datos',
              subtitle: 'No se recibieron resultados',
              leading: Icon(Icons.info_outline_rounded),
              child: Text(
                'Vuelve a finalizar una entrevista para ver el análisis.',
              ),
            ),
          ],
        ),
      );
    }
    final analytics = buildInterviewAnalytics(
      theme: Theme.of(context),
      results: results,
      session: session,
    );

    return AppScreenScaffold(
      title: 'Análisis detallado',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Métricas principales',
            subtitle: 'Análisis por categoría',
            leading: Icon(Icons.analytics_outlined, color: scheme.primary),
            child: Column(
              children: [
                _MetricBar(
                  label: 'Comunicación',
                  value: results.breakdown.communication / 100,
                  icon: Icons.record_voice_over_rounded,
                ),
                const SizedBox(height: 12),
                _MetricBar(
                  label: 'Conocimiento técnico',
                  value: results.breakdown.technicalKnowledge / 100,
                  icon: Icons.code_rounded,
                ),
                const SizedBox(height: 12),
                _MetricBar(
                  label: 'Seguridad',
                  value: results.breakdown.confidence / 100,
                  icon: Icons.shield_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Gráficos por respuesta',
            subtitle: 'Evolución de score, calidad y tiempo',
            leading: Icon(
              Icons.stacked_bar_chart_rounded,
              color: scheme.secondary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatsSummaryChips(analytics: analytics),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: 'Score por respuesta',
                  subtitle: 'Puntuación obtenida en cada turno',
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.primary,
                  valueSuffix: '',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: 'Tiempo por respuesta',
                  subtitle: 'Comparativa del tiempo invertido por turno',
                  bars: analytics.turns,
                  maxValue: analytics.turns.isEmpty
                      ? 1
                      : analytics.turns
                            .map((turn) => turn.responseSeconds)
                            .reduce((a, b) => a > b ? a : b),
                  barColor: scheme.tertiary,
                  valueSuffix: 's',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Feedback personalizado',
            subtitle: 'Generado por IA',
            leading: Icon(Icons.auto_awesome_rounded, color: scheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  results.personalizedFeedback.trim().isEmpty
                      ? 'Sin feedback disponible.'
                      : results.personalizedFeedback.trim(),
                ),
                if (results.improvementTips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Consejos de mejora',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final tip in results.improvementTips) ...[
                    _TipRow(text: tip),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Ver recomendaciones',
            icon: Icons.lightbulb_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.recommendations, arguments: results),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.statistics,
              arguments: {'results': results, 'session': session},
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.pie_chart_rounded),
            label: const Text('Ver estadísticas completas'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
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

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text('$percent%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: value, minHeight: 10),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
