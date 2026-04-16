import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
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
        children: [
          Text(
            'Elige tu modo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta el entrenamiento según lo que te pidan en tu próximo proceso.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          for (final option in InterviewConfigType.values) ...[
            _TypeCard(
              option: option,
              selected: selected == option,
              onTap: () => controller.setType(option),
            ),
            const SizedBox(height: 12),
          ],
          AppPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (controller.config.type == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona el tipo de entrevista para continuar.'),
                  ),
                );
                return;
              }
              Navigator.of(context).pushNamed(AppRoutes.selectJobRole);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
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

    final (title, subtitle, icon) = switch (option) {
      InterviewConfigType.technical => (
          'Técnica',
          'Problemas, conceptos, debugging',
          Icons.code_rounded
        ),
      InterviewConfigType.rrhh => (
          'RRHH',
          'Comunicación, historias, soft skills',
          Icons.chat_bubble_outline_rounded
        ),
      InterviewConfigType.mixed => (
          'Mixta',
          'Combinación equilibrada',
          Icons.auto_awesome_rounded
        ),
    };

    return AppCard(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: (selected ? scheme.primary : scheme.secondary)
              .withValues(alpha: 0.14),
        ),
        child: Icon(icon, color: selected ? scheme.primary : scheme.secondary),
      ),
      title: title,
      subtitle: subtitle,
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : Icon(Icons.radio_button_unchecked_rounded, color: scheme.onSurfaceVariant),
    );
  }
}
