import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class InterviewConfigurationScreen extends StatefulWidget {
  const InterviewConfigurationScreen({super.key});

  @override
  State<InterviewConfigurationScreen> createState() =>
      _InterviewConfigurationScreenState();
}

class _InterviewConfigurationScreenState
    extends State<InterviewConfigurationScreen> {
  double _timeLimitMinutes = 8;

  @override
  void initState() {
    super.initState();
    final controller = context.read<InterviewConfigController>();
    final initialDuration = controller.config.durationMinutes ?? 8;
    _timeLimitMinutes = initialDuration.toDouble();
    if (controller.config.durationMinutes == null) {
      controller.setDurationMinutes(initialDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final controller = context.watch<InterviewConfigController>();
    final config = controller.config;
    final timeLimitSeconds = (_timeLimitMinutes.round()) * 60;

    return AppScreenScaffold(
      title: l10n.interviewConfigTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: l10n.interviewQuickSettingsTitle,
            subtitle: l10n.interviewQuickSettingsSubtitle,
            leading: Icon(Icons.tune_rounded, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.interviewTimeLimitMinutes(
                    _timeLimitMinutes.round(),
                    l10n.minutesShort,
                  ),
                ),
                Slider(
                  value: _timeLimitMinutes,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: l10n.interviewTimeLimitMinutes(
                    _timeLimitMinutes.round(),
                    l10n.minutesShort,
                  ),
                  onChanged: (v) {
                    setState(() => _timeLimitMinutes = v);
                    controller.setDurationMinutes(v.round());
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.interviewModeLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final mode in InterviewMode.values)
                      ChoiceChip(
                        label: Text(mode.label(l10n)),
                        selected: config.mode == mode,
                        onSelected: (_) => controller.setMode(mode),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: l10n.interviewPreviewTitle,
            subtitle: l10n.interviewPreviewSubtitle,
            leading: Icon(Icons.preview_rounded, color: scheme.secondary),
            child: Column(
              children: [
                _PreviewTile(
                  icon: Icons.record_voice_over_rounded,
                  title: l10n.interviewPreviewType,
                  value: config.type == null ? '-' : config.type!.label(l10n),
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.timer_rounded,
                  title: l10n.interviewPreviewTime,
                  value: l10n.interviewTimeLimitMinutes(
                    timeLimitSeconds ~/ 60,
                    l10n.minutesShort,
                  ),
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.work_outline_rounded,
                  title: l10n.interviewPreviewJobRole,
                  value: config.jobRole == null
                      ? '-'
                      : config.jobRole!.label(l10n),
                ),
                const SizedBox(height: 10),
                _PreviewTile(
                  icon: Icons.smart_toy_outlined,
                  title: l10n.interviewPreviewMode,
                  value: config.mode == null ? '-' : config.mode!.label(l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: l10n.genericContinue,
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (!controller.isComplete) {
                final missing = controller.config.missingFields
                    .map((f) => f.label(l10n))
                    .join(', ');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.interviewCompleteMissingFields(missing)),
                  ),
                );
                return;
              }
              Navigator.of(context).pushNamed(AppRoutes.deviceCheck);
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
            child: Text(l10n.genericBack),
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

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
        Expanded(child: Text(title)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}
