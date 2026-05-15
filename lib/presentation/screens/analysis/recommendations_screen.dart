import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/presentation/widgets/feedback_content_widget.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, required this.results});

  final InterviewResultsModel? results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final results = this.results;
    if (results == null) {
      return AppScreenScaffold(
        title: l10n.recommendationsTitle,
        background: const TechBackground(),
        body: ListView(
          children: [
            AppCard(
              title: l10n.statsNoDataTitle,
              subtitle: l10n.recommendationsNoDataSubtitle,
              leading: const Icon(Icons.info_outline_rounded),
              child: Text(l10n.recommendationsNoDataBody),
            ),
          ],
        ),
      );
    }

    return AppScreenScaffold(
      title: l10n.recommendationsTitle,
      background: const TechBackground(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppCard(
            title: l10n.recommendationsSuggestionsTitle,
            subtitle: l10n.recommendationsSuggestionsSubtitle,
            leading: Icon(Icons.lightbulb_rounded, color: scheme.primary),
            child: SectionFeedbackCard(
              title: l10n.feedbackKeyPhrasesTitle,
              items: results.recommendations,
              icon: Icons.auto_awesome_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          if (results.improvementTips.isNotEmpty) ...[
            AppCard(
              title: l10n.recommendationsTipsTitle,
              subtitle: l10n.recommendationsTipsSubtitle,
              leading:
                  Icon(Icons.tips_and_updates_rounded, color: scheme.secondary),
              child: SectionFeedbackCard(
                title: l10n.feedbackActionItemsTitle,
                items: results.improvementTips,
                icon: Icons.check_circle_rounded,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          AppCard(
            title: l10n.recommendationsNextSessionTitle,
            subtitle: l10n.recommendationsNextSessionSubtitle,
            leading: Icon(Icons.replay_rounded, color: scheme.secondary),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.selectInterviewType),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.repeatButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: l10n.dashboardButton,
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
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
