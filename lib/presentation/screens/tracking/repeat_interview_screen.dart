import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class RepeatInterviewScreen extends StatelessWidget {
  const RepeatInterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AppScreenScaffold(
      title: l10n.repeatInterviewTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: l10n.repeatInterviewCardTitle,
            subtitle: l10n.repeatInterviewCardSubtitle,
            leading: Icon(Icons.replay_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.repeatInterviewQuickSuggestionTitle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.repeatInterviewQuickSuggestionBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: l10n.repeatInterviewStartNewSimulation,
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.selectInterviewType),
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
            child: Text(l10n.backToDashboard),
          ),
        ],
      ),
    );
  }
}
