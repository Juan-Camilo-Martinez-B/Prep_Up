import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class DetailedAnalysisScreen extends StatelessWidget {
  const DetailedAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Análisis detallado',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Métricas principales',
            subtitle: 'Indicadores simulados',
            leading: Icon(Icons.analytics_outlined, color: scheme.primary),
            child: const Column(
              children: [
                _MetricBar(
                  label: 'Lenguaje corporal',
                  value: 0.74,
                  icon: Icons.self_improvement_rounded,
                ),
                SizedBox(height: 12),
                _MetricBar(
                  label: 'Claridad',
                  value: 0.70,
                  icon: Icons.record_voice_over_rounded,
                ),
                SizedBox(height: 12),
                _MetricBar(
                  label: 'Seguridad',
                  value: 0.77,
                  icon: Icons.shield_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Micro-señales',
            subtitle: 'Lectura de video (placeholder)',
            leading: Icon(Icons.face_retouching_natural_rounded, color: scheme.secondary),
            child: Column(
              children: [
                _ChipRow(
                  chips: const ['Contacto visual', 'Postura', 'Gestos', 'Sonrisa'],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pendiente de integración de análisis gestual.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Ver recomendaciones',
            icon: Icons.lightbulb_rounded,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.recommendations),
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
            child: const Text('Volver al Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text('$percent%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final c in chips) Chip(label: Text(c))],
    );
  }
}
