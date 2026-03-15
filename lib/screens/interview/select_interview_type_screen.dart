import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class SelectInterviewTypeScreen extends StatefulWidget {
  const SelectInterviewTypeScreen({super.key});

  @override
  State<SelectInterviewTypeScreen> createState() =>
      _SelectInterviewTypeScreenState();
}

class _SelectInterviewTypeScreenState extends State<SelectInterviewTypeScreen> {
  _TypeOption _selected = _TypeOption.behavioral;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          for (final option in _TypeOption.values) ...[
            _TypeCard(
              option: option,
              selected: _selected == option,
              onTap: () => setState(() => _selected = option),
            ),
            const SizedBox(height: 12),
          ],
          AppPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              // TODO: guardar preferencia de tipo en sesión de entrevista.
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

enum _TypeOption {
  behavioral,
  technical,
  mixed,
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _TypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (title, subtitle, icon) = switch (option) {
      _TypeOption.behavioral => (
          'Conductual',
          'Comunicación, historias, soft skills',
          Icons.chat_bubble_outline_rounded
        ),
      _TypeOption.technical => (
          'Técnica',
          'Problemas, conceptos, debugging',
          Icons.code_rounded
        ),
      _TypeOption.mixed => (
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
