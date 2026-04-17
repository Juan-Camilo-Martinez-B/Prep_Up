import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class InterviewProcessingScreen extends StatefulWidget {
  const InterviewProcessingScreen({super.key, this.config, this.session});

  final InterviewConfig? config;
  final InterviewSession? session;

  @override
  State<InterviewProcessingScreen> createState() =>
      _InterviewProcessingScreenState();
}

class _InterviewProcessingScreenState extends State<InterviewProcessingScreen> {
  InterviewResultsModel? _results;
  String? _error;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateResults();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _generateResults() async {
    final l10n = context.l10n;
    final providerConfig = context.read<InterviewConfigController>().config;
    final languageCode = AppLocaleScope.of(context).languageCode;
    final config = widget.config ?? providerConfig;
    final session = widget.session;
    if (session == null || session.turns.isEmpty) {
      setState(() {
        _error = l10n.processingNotEnoughData;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _results = null;
    });

    try {
      final results = await GeminiService().generateInterviewResults(
        config: config,
        session: session,
        language: languageCode,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final providerConfig = context.watch<InterviewConfigController>().config;
    final config = widget.config ?? providerConfig;
    final session = widget.session;
    final results = _results;

    return AppScreenScaffold(
      title: l10n.processingTitle,
      background: const TechBackground(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.processingHeadline,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.processingSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (session != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.processingAnswersCaptured(session.turns.length),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: _isLoading ? null : 1.0,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.memory_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.modelGemini,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (_isLoading)
                Text(
                  l10n.processingWorking,
                  style: Theme.of(context).textTheme.labelLarge,
                )
              else if (results != null)
                Text(
                  '${results.overallScore}/100',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _ConfigSummary(config: config),
          const SizedBox(height: 14),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.errorContainer.withValues(alpha: 0.5),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.processingErrorTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _generateResults,
                      child: Text(l10n.genericRetry),
                    ),
                  ),
                ],
              ),
            )
          else if (results != null)
            _ResultsSummary(results: results),
          const Spacer(),
          AppPrimaryButton(
            label: l10n.processingViewResults,
            icon: Icons.insights_rounded,
            onPressed: results == null
                ? null
                : () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.generalResults,
                      arguments: {'results': results, 'session': session},
                    );
                  },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(l10n.processingBackToDashboard),
          ),
        ],
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.results});

  final InterviewResultsModel results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final outcomeLabel = switch (results.outcome) {
      InterviewOutcome.approved => l10n.outcomeApproved,
      InterviewOutcome.improve => l10n.outcomeImprove,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: scheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.checklist_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.processingSummaryReady,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.processingOutcomeStatus(outcomeLabel),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${results.overallScore}/100',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ConfigSummary extends StatelessWidget {
  const _ConfigSummary({required this.config});

  final InterviewConfig config;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.processingConfigReceived,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.processingConfigType(
              config.type == null ? '-' : config.type!.label(l10n),
            ),
          ),
          Text(
            l10n.processingConfigJobRole(
              config.jobRole == null ? '-' : config.jobRole!.label(l10n),
            ),
          ),
          Text(
            l10n.processingConfigDuration(
              config.durationMinutes == null
                  ? '-'
                  : l10n.interviewTimeLimitMinutes(
                      config.durationMinutes!,
                      l10n.minutesShort,
                    ),
            ),
          ),
          Text(
            l10n.processingConfigMode(
              config.mode == null ? '-' : config.mode!.label(l10n),
            ),
          ),
        ],
      ),
    );
  }
}
