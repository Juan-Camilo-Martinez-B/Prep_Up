import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Estadísticas',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Tu progreso',
            subtitle: 'Gráficos simulados',
            leading: Icon(Icons.query_stats_rounded, color: scheme.primary),
            child: Column(
              children: [
                _ChartPlaceholder(
                  title: 'Score por sesión',
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.20),
                      scheme.secondary.withValues(alpha: 0.16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ChartPlaceholder(
                  title: 'Métricas (radar)',
                  gradient: LinearGradient(
                    colors: [
                      scheme.secondary.withValues(alpha: 0.18),
                      scheme.tertiary.withValues(alpha: 0.14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Streak',
            subtitle: 'Consistencia semanal',
            leading: Icon(Icons.bolt_rounded, color: scheme.secondary),
            child: Row(
              children: [
                _StreakDot(active: true),
                const SizedBox(width: 8),
                _StreakDot(active: true),
                const SizedBox(width: 8),
                _StreakDot(active: true),
                const SizedBox(width: 8),
                _StreakDot(active: false),
                const SizedBox(width: 8),
                _StreakDot(active: true),
                const SizedBox(width: 8),
                _StreakDot(active: false),
                const SizedBox(width: 8),
                _StreakDot(active: false),
              ],
            ),
          ),
          const SizedBox(height: 18),
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

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({
    required this.title,
    required this.gradient,
  });

  final String title;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: Center(
              child: Icon(
                Icons.show_chart_rounded,
                size: 44,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  const _StreakDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.outlineVariant;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: active ? 0.9 : 0.45),
      ),
    );
  }
}
