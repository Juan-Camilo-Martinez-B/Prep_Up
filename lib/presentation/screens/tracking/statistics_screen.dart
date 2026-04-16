import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/presentation/widgets/interview_statistics_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, this.results, this.session});

  final InterviewResultsModel? results;
  final InterviewSession? session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = this.results;

    if (results == null) {
      return AppScreenScaffold(
        title: 'Estadísticas',
        background: const TechBackground(),
        body: ListView(
          children: const [
            AppCard(
              title: 'Sin datos',
              subtitle: 'No hay una entrevista analizada seleccionada',
              leading: Icon(Icons.info_outline_rounded),
              child: Text(
                'Finaliza una entrevista para ver gráficos reales de score, calidad y tiempo por respuesta.',
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
      title: 'Estadísticas',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Tu desempeño',
            subtitle: 'Gráficos reales de la entrevista',
            leading: Icon(Icons.query_stats_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatsSummaryChips(analytics: analytics),
                const SizedBox(height: 14),
                InterviewPieChartCard(
                  title: 'Evaluación global',
                  subtitle: 'Peso relativo de las principales dimensiones',
                  slices: analytics.breakdownSlices,
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: 'Score por respuesta',
                  subtitle: 'Comparativa de puntaje en cada turno',
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.primary,
                  valueSuffix: '',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: 'Calidad por respuesta',
                  subtitle: 'Estimación basada en score y riqueza de contenido',
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.secondary,
                  valueSuffix: '/100',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: 'Tiempo por respuesta',
                  subtitle: 'Segundos utilizados en cada pregunta',
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
            title: 'Lectura rápida',
            subtitle: 'Interpretación del rendimiento',
            leading: Icon(Icons.bolt_rounded, color: scheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score general: ${analytics.overallScore}/100'),
                const SizedBox(height: 8),
                Text(
                  'Calidad promedio de respuesta: ${analytics.averageQuality}/100',
                ),
                const SizedBox(height: 8),
                Text(
                  'Tiempo promedio por respuesta: ${analytics.averageResponseSeconds} segundos',
                ),
                const SizedBox(height: 8),
                Text(
                  analytics.averageResponseSeconds > 60
                      ? 'Tu ritmo fue reflexivo; intenta sintetizar un poco mas tus respuestas.'
                      : 'Tu ritmo fue agil; cuida mantener suficiente profundidad en cada ejemplo.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Volver al Dashboard',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
          ),
        ],
      ),
    );
  }
}
