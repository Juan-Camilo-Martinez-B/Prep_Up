import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class GeneralResultsScreen extends StatelessWidget {
  const GeneralResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const score = 76;
    const probability = 0.72;

    return AppScreenScaffold(
      title: 'Resultados',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Resultados generales',
            subtitle: 'Resumen rápido (simulado)',
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
                        'Score',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Muy buen ritmo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Probabilidad de éxito',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(probability * 100).round()}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: scheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Highlights',
            subtitle: 'Lo mejor de tu sesión',
            leading: Icon(Icons.star_rounded, color: scheme.secondary),
            child: Column(
              children: const [
                _Highlight(text: 'Buena estructura al presentar experiencias.'),
                SizedBox(height: 8),
                _Highlight(text: 'Tono seguro y consistente.'),
                SizedBox(height: 8),
                _Highlight(text: 'Respuestas claras en el 70% del tiempo.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Ver análisis detallado',
            icon: Icons.analytics_rounded,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.detailedAnalysis),
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
