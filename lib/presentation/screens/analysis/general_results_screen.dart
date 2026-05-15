import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/presentation/widgets/interview_statistics_widgets.dart';

class GeneralResultsScreen extends StatelessWidget {
  const GeneralResultsScreen({super.key, required this.results, this.session});

  final InterviewResultsModel? results;
  final InterviewSession? session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final results = this.results;
    if (results == null) {
      return AppScreenScaffold(
        title: l10n.generalResultsTitle,
        background: const TechBackground(),
        body: ListView(
          children: [
            AppCard(
              title: l10n.generalResultsCardTitle,
              subtitle: l10n.generalResultsNoDataSubtitle,
              leading: const Icon(Icons.info_outline_rounded),
              child: Text(l10n.generalResultsNoDataBody),
            ),
          ],
        ),
      );
    }

    final score = results.overallScore;
    final outcomeLabel = switch (results.outcome) {
      InterviewOutcome.approved => l10n.outcomeApproved,
      InterviewOutcome.improve => l10n.outcomeImprove,
    };
    final outcomeColor = results.outcome == InterviewOutcome.approved
        ? scheme.primary
        : scheme.secondary;
    final analytics = buildInterviewAnalytics(
      theme: Theme.of(context),
      l10n: l10n,
      results: results,
      session: session,
    );

    return AppScreenScaffold(
      title: l10n.generalResultsTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: l10n.generalResultsCardTitle,
            subtitle: l10n.generalResultsSummarySubtitle,
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
                        l10n.generalResultsScoreLabel,
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
                        l10n.generalResultsStatusLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        outcomeLabel,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: outcomeColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: l10n.generalResultsStatsTitle,
            subtitle: l10n.generalResultsStatsSubtitle,
            leading: Icon(Icons.query_stats_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatsSummaryChips(analytics: analytics),
                const SizedBox(height: 14),
                InterviewPieChartCard(
                  title: l10n.generalResultsDistributionTitle,
                  subtitle: l10n.generalResultsDistributionSubtitle,
                  slices: analytics.breakdownSlices,
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: l10n.generalResultsAnswerQualityTitle,
                  subtitle: l10n.generalResultsAnswerQualitySubtitle,
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.primary,
                  valueSuffix: '/100',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: l10n.generalResultsTimePerAnswerTitle,
                  subtitle: l10n.generalResultsTimePerAnswerSubtitle,
                  bars: analytics.turns,
                  maxValue: analytics.turns.isEmpty
                      ? 1
                      : analytics.turns
                            .map((turn) => turn.responseSeconds)
                            .reduce((a, b) => a > b ? a : b),
                  barColor: scheme.secondary,
                  valueSuffix: 's',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: l10n.generalResultsHighlightsTitle,
            subtitle: l10n.generalResultsHighlightsSubtitle,
            leading: Icon(Icons.star_rounded, color: scheme.secondary),
            child: Column(
              children: results.highlights.isEmpty
                  ? [
                      Text(
                        l10n.generalResultsNoHighlights,
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
            label: l10n.generalResultsViewDetailedAnalysis,
            icon: Icons.analytics_rounded,
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.detailedAnalysis,
              arguments: {'results': results, 'session': session},
            ),
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
