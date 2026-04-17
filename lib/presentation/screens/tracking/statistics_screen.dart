import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
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
    final l10n = context.l10n;
    final results = this.results;

    if (results == null) {
      return AppScreenScaffold(
        title: l10n.statsScreenTitle,
        background: const TechBackground(),
        body: ListView(
          children: [
            AppCard(
              title: l10n.statsNoDataTitle,
              subtitle: l10n.statsNoDataSubtitle,
              leading: const Icon(Icons.info_outline_rounded),
              child: Text(l10n.statsNoDataBody),
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
      title: l10n.statsScreenTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: l10n.statsMainCardTitle,
            subtitle: l10n.statsMainCardSubtitle,
            leading: Icon(Icons.query_stats_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatsSummaryChips(analytics: analytics),
                const SizedBox(height: 14),
                InterviewPieChartCard(
                  title: l10n.statsPieTitle,
                  subtitle: l10n.statsPieSubtitle,
                  slices: analytics.breakdownSlices,
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: l10n.statsBarScoreTitle,
                  subtitle: l10n.statsBarScoreSubtitle,
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.primary,
                  valueSuffix: '',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: l10n.statsBarQualityTitle,
                  subtitle: l10n.statsBarQualitySubtitle,
                  bars: analytics.turns,
                  maxValue: 100,
                  barColor: scheme.secondary,
                  valueSuffix: '/100',
                ),
                const SizedBox(height: 14),
                InterviewBarChartCard(
                  title: l10n.statsBarTimeTitle,
                  subtitle: l10n.statsBarTimeSubtitle,
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
            title: l10n.statsQuickReadTitle,
            subtitle: l10n.statsQuickReadSubtitle,
            leading: Icon(Icons.bolt_rounded, color: scheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.statsQuickReadOverallScore(analytics.overallScore)),
                const SizedBox(height: 8),
                Text(
                  l10n.statsQuickReadAvgQuality(analytics.averageQuality),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.statsQuickReadAvgTime(analytics.averageResponseSeconds),
                ),
                const SizedBox(height: 8),
                Text(
                  analytics.averageResponseSeconds > 60
                      ? l10n.statsQuickReadSlow
                      : l10n.statsQuickReadFast,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: l10n.backToDashboard,
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
