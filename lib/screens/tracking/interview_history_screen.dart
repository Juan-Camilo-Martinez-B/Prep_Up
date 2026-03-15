import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class InterviewHistoryScreen extends StatelessWidget {
  const InterviewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _HistoryItem('Frontend Developer', 'Mixta', '76', 'Hace 2 días'),
      _HistoryItem('Mobile Developer', 'Conductual', '81', 'Hace 5 días'),
      _HistoryItem('Data Analyst', 'Técnica', '69', 'Hace 1 semana'),
      _HistoryItem('UI/UX Designer', 'Conductual', '74', 'Hace 2 semanas'),
    ];

    return AppScreenScaffold(
      title: 'Historial',
      background: const TechBackground(),
      body: ListView(
        children: [
          for (final item in items) ...[
            AppCard(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.generalResults),
              title: item.role,
              subtitle: '${item.type} • ${item.when}',
              leading: _ScoreBadge(score: item.score),
              trailing: const Icon(Icons.arrow_forward_rounded),
            ),
            const SizedBox(height: 12),
          ],
          AppPrimaryButton(
            label: 'Volver al Dashboard',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.dashboard,
              (r) => false,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem {
  const _HistoryItem(this.role, this.type, this.score, this.when);

  final String role;
  final String type;
  final String score;
  final String when;
}

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
