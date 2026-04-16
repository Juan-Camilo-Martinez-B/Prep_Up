import 'package:flutter/material.dart';
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
    final providerConfig = context.read<InterviewConfigController>().config;
    final config = widget.config ?? providerConfig;
    final session = widget.session;
    if (session == null || session.turns.isEmpty) {
      setState(() {
        _error = 'No hay datos suficientes para generar resultados.';
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
    final providerConfig = context.watch<InterviewConfigController>().config;
    final config = widget.config ?? providerConfig;
    final session = widget.session;
    final results = _results;

    return AppScreenScaffold(
      title: 'Analizando',
      background: const TechBackground(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analizando tu entrevista con IA...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Generando resultados con IA a partir de tus respuestas.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (session != null) ...[
            const SizedBox(height: 8),
            Text(
              'Respuestas capturadas: ${session.turns.length}',
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
                  'Modelo: Gemini',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (_isLoading)
                Text(
                  'Procesando...',
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
                    'No se pudieron generar resultados',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _generateResults,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
            )
          else if (results != null)
            _ResultsSummary(results: results),
          const Spacer(),
          AppPrimaryButton(
            label: 'Ver resultados',
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
            child: const Text('Volver al Dashboard'),
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
    final outcomeLabel = switch (results.outcome) {
      InterviewOutcome.approved => 'Aprobado',
      InterviewOutcome.improve => 'Mejorar',
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
                  'Resumen listo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Estado: $outcomeLabel',
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
            'Configuración recibida',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Text('Tipo: ${config.type?.label ?? '-'}'),
          Text('Cargo: ${config.jobRole.isEmpty ? '-' : config.jobRole}'),
          Text(
            'Duración: ${config.durationMinutes == null ? '-' : '${config.durationMinutes} min'}',
          ),
          Text('Modalidad: ${config.mode?.label ?? '-'}'),
        ],
      ),
    );
  }
}
