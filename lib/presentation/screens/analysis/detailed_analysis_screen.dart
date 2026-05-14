import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
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
    final l10n = context.l10n;
    final results = this.results;
    if (results == null) {
      return AppScreenScaffold(
        title: l10n.detailedAnalysisTitle,
        background: const TechBackground(),
        body: ListView(
          children: [
            AppCard(
              title: l10n.statsNoDataTitle,
              subtitle: l10n.detailedAnalysisNoDataSubtitle,
              leading: const Icon(Icons.info_outline_rounded),
              child: Text(l10n.detailedAnalysisNoDataBody),
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
      title: l10n.detailedAnalysisTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: l10n.detailedAnalysisMainMetricsTitle,
            subtitle: l10n.detailedAnalysisMainMetricsSubtitle,
            leading: Icon(Icons.analytics_outlined, color: scheme.primary),
            child: Column(
              children: [
                MetricProgressBar(
                  label: l10n.metricCommunication,
                  value: results.breakdown.communication / 100,
                  icon: Icons.record_voice_over_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                MetricProgressBar(
                  label: l10n.metricSubjectMastery,
                  value: results.breakdown.subjectMastery / 100,
                  icon: Icons.psychology_rounded,
                  color: scheme.secondary,
                ),
                const SizedBox(height: 16),
                MetricProgressBar(
                  label: l10n.metricConfidence,
                  value: results.breakdown.confidence / 100,
                  icon: Icons.shield_rounded,
                  color: scheme.tertiary,
                ),
                const SizedBox(height: 16),
                MetricProgressBar(
                  label: l10n.metricTechnicalKnowledge,
                  value: results.breakdown.technicalKnowledge / 100,
                  icon: Icons.code_rounded,
                  color: scheme.outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: l10n.detailedAnalysisChartsTitle,
            subtitle: l10n.detailedAnalysisChartsSubtitle,
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
                  title: l10n.detailedAnalysisScorePerAnswerTitle,
                  subtitle: l10n.detailedAnalysisScorePerAnswerSubtitle,
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.primary,
                  valueSuffix: '',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: l10n.detailedAnalysisTimePerAnswerTitle,
                  subtitle: l10n.detailedAnalysisTimePerAnswerSubtitle,
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
            title: l10n.detailedAnalysisPersonalizedFeedbackTitle,
            subtitle: l10n.detailedAnalysisPersonalizedFeedbackSubtitle,
            leading: Icon(Icons.auto_awesome_rounded, color: scheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  results.personalizedFeedback.trim().isEmpty
                      ? l10n.detailedAnalysisNoFeedback
                      : results.personalizedFeedback.trim(),
                ),
                if (results.improvementTips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.detailedAnalysisImprovementTipsTitle,
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
            label: l10n.detailedAnalysisViewRecommendations,
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
            label: Text(l10n.generalResultsViewFullStats),
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
            child: Text(l10n.backToDashboard),
          ),
        ],
      ),
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
