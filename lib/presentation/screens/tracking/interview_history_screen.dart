import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class InterviewHistoryScreen extends StatelessWidget {
  const InterviewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = const [
      _HistoryItem(
        JobRole.frontendDeveloper,
        InterviewConfigType.mixed,
        '76',
        _HistoryWhen.daysAgo,
        2,
      ),
      _HistoryItem(
        JobRole.mobileDeveloper,
        InterviewConfigType.rrhh,
        '81',
        _HistoryWhen.daysAgo,
        5,
      ),
      _HistoryItem(
        JobRole.dataAnalyst,
        InterviewConfigType.technical,
        '69',
        _HistoryWhen.weeksAgo,
        1,
      ),
      _HistoryItem(
        JobRole.uiUxDesigner,
        InterviewConfigType.rrhh,
        '74',
        _HistoryWhen.weeksAgo,
        2,
      ),
    ];

    return AppScreenScaffold(
      title: l10n.historyTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          for (final item in items) ...[
            AppCard(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.generalResults),
              title: item.role.label(l10n),
              subtitle:
                  '${item.type.label(l10n)} • ${item.when == _HistoryWhen.daysAgo ? l10n.historyWhenDaysAgo(item.amount) : l10n.historyWhenWeeksAgo(item.amount)}',
              leading: _ScoreBadge(score: item.score),
              trailing: const Icon(Icons.arrow_forward_rounded),
            ),
            const SizedBox(height: 12),
          ],
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

class _HistoryItem {
  const _HistoryItem(this.role, this.type, this.score, this.when, this.amount);

  final JobRole role;
  final InterviewConfigType type;
  final String score;
  final _HistoryWhen when;
  final int amount;
}

enum _HistoryWhen { daysAgo, weeksAgo }

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = int.tryParse(score) ?? 0;
    final color = value >= 80
        ? scheme.primary
        : value >= 70
        ? scheme.secondary
        : scheme.error;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Text(
          score,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
