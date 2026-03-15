import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Perfil',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Alex',
            subtitle: 'Frontend Jr • en modo crecimiento',
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.35),
                    scheme.secondary.withValues(alpha: 0.30),
                  ],
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            trailing: Icon(Icons.verified_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  leftLabel: 'Entrevistas',
                  leftValue: '12',
                  rightLabel: 'Score prom.',
                  rightValue: '76',
                ),
                const SizedBox(height: 10),
                _StatRow(
                  leftLabel: 'Racha',
                  leftValue: '4 días',
                  rightLabel: 'Nivel',
                  rightValue: 'Rookie+',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Logros',
            subtitle: 'Streaks y progreso',
            leading: Icon(Icons.emoji_events_rounded, color: scheme.secondary),
            child: Column(
              children: [
                _AchievementTile(
                  icon: Icons.bolt_rounded,
                  title: 'Primera semana',
                  subtitle: '7 días practicando',
                ),
                const SizedBox(height: 10),
                _AchievementTile(
                  icon: Icons.psychology_alt_rounded,
                  title: 'Modo IA',
                  subtitle: '10 entrevistas simuladas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: 'Volver al Dashboard',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.dashboard,
              (route) => false,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _MiniStat(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(label: rightLabel, value: rightValue),
        ),
        const SizedBox(width: 0),
        Icon(Icons.auto_awesome_rounded, color: scheme.primary.withValues(alpha: 0.6)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.primary.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
