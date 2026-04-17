import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class SelectInterviewTypeScreen extends StatelessWidget {
  const SelectInterviewTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<InterviewConfigController>();
    final selected = controller.config.type;

    return AppScreenScaffold(
      title: 'Tipo de entrevista',
      background: const TechBackground(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          const SizedBox(height: 12),
          Text(
            'Elige tu modo\nde entrenamiento',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ajusta la simulación según el enfoque\nde tu próximo proceso de selección.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          for (final option in InterviewConfigType.values) ...[
            _TypeCard(
              option: option,
              selected: selected == option,
              onTap: () => controller.setType(option),
            ),
          ],
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (controller.config.type == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, selecciona un tipo de entrevista.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.of(context).pushNamed(AppRoutes.selectJobRole);
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Volver al inicio',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final InterviewConfigType option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (title, subtitle, icon, gradientColors) = switch (option) {
      InterviewConfigType.technical => (
          'Técnica',
          'Problemas, conceptos y debugging',
          Icons.terminal_rounded,
          [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
        ),
      InterviewConfigType.rrhh => (
          'Conductual',
          'Soft skills, historias y liderazgo',
          Icons.people_alt_rounded,
          [const Color(0xFFFDC830), const Color(0xFFF37335)],
        ),
      InterviewConfigType.mixed => (
          'Mixta',
          'El equilibrio perfecto de ambas',
          Icons.auto_awesome_rounded,
          [const Color(0xFF8A2387), const Color(0xFFE94057)],
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          bottom: selected ? 16 : 12,
          top: selected ? 4 : 0,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : scheme.surfaceBright,
          border: Border.all(
            color: selected ? Colors.transparent : scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: gradientColors[1].withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: selected ? Colors.white : scheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: selected ? 18 : 16,
                          color: selected ? Colors.white : scheme.onSurface,
                        ),
                    child: Text(title),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 13,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.85)
                              : scheme.onSurfaceVariant,
                        ),
                    child: Text(subtitle),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 28,
                      key: ValueKey('checked'),
                    )
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      size: 28,
                      key: const ValueKey('unchecked'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
