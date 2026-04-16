import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class SelectJobRoleScreen extends StatefulWidget {
  const SelectJobRoleScreen({super.key});

  @override
  State<SelectJobRoleScreen> createState() => _SelectJobRoleScreenState();
}

class _SelectJobRoleScreenState extends State<SelectJobRoleScreen> {
  final _searchController = TextEditingController();
  String _selected = '';

  final _roles = const [
    'Frontend Developer',
    'Backend Developer',
    'Mobile Developer',
    'UI/UX Designer',
    'Data Analyst',
    'Data Scientist',
    'QA Tester',
    'DevOps',
    'Product Manager',
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.read<InterviewConfigController>().config.jobRole;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _roles
        .where((r) => query.isEmpty || r.toLowerCase().contains(query))
        .toList();

    return AppScreenScaffold(
      title: 'Puesto / área',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: '¿Para qué rol entrenas?',
            subtitle: 'Selecciona uno y afina la simulación',
            leading: Icon(Icons.work_outline_rounded, color: scheme.primary),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar rol',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final role in filtered)
                ChoiceChip(
                  label: Text(role),
                  selected: _selected == role,
                  onSelected: (_) => setState(() => _selected = role),
                ),
            ],
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (_selected.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona un cargo para continuar.'),
                  ),
                );
                return;
              }
              context.read<InterviewConfigController>().setJobRole(_selected);
              Navigator.of(context).pushNamed(AppRoutes.interviewConfiguration);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Atrás'),
          ),
        ],
      ),
    );
  }
}
