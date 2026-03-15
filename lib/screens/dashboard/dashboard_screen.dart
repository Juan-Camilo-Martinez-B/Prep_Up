import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Dashboard',
      background: const TechBackground(),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Configuración',
        ),
      ],
      body: ListView(
        children: [
          AppCard(
            title: 'Modo entrenamiento',
            subtitle: 'Simula entrevistas y mejora con feedback',
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: scheme.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listo para una sesión rápida?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'Empezar entrevista',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.selectInterviewType),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Accesos rápidos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _QuickActionsGrid(
            items: [
              _QuickAction(
                title: 'Perfil',
                subtitle: 'Tu info',
                icon: Icons.person_rounded,
                route: AppRoutes.profile,
              ),
              _QuickAction(
                title: 'Historial',
                subtitle: 'Sesiones',
                icon: Icons.history_rounded,
                route: AppRoutes.interviewHistory,
              ),
              _QuickAction(
                title: 'Estadísticas',
                subtitle: 'Progreso',
                icon: Icons.query_stats_rounded,
                route: AppRoutes.statistics,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.items});

  final List<_QuickAction> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final isNarrow = constraints.maxWidth < 360;
        final crossAxisCount = isWide ? 4 : (isNarrow ? 1 : 2);
        final tileWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 12)) /
            crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: _QuickActionTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item});

  final _QuickAction item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: () => Navigator.of(context).pushNamed(item.route),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.secondary.withValues(alpha: 0.14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(item.icon, color: scheme.secondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                item.title,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
