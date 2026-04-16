import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';

class InterviewAnalyticsSnapshot {
  const InterviewAnalyticsSnapshot({
    required this.overallScore,
    required this.averageQuality,
    required this.averageResponseSeconds,
    required this.totalResponseSeconds,
    required this.turns,
    required this.breakdownSlices,
  });

  final int overallScore;
  final int averageQuality;
  final int averageResponseSeconds;
  final int totalResponseSeconds;
  final List<InterviewTurnAnalytics> turns;
  final List<InterviewPieSlice> breakdownSlices;

  bool get hasTurns => turns.isNotEmpty;
}

class InterviewTurnAnalytics {
  const InterviewTurnAnalytics({
    required this.label,
    required this.score,
    required this.quality,
    required this.responseSeconds,
  });

  final String label;
  final int score;
  final int quality;
  final int responseSeconds;
}

class InterviewPieSlice {
  const InterviewPieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

InterviewAnalyticsSnapshot buildInterviewAnalytics({
  required ThemeData theme,
  required InterviewResultsModel results,
  InterviewSession? session,
}) {
  final scheme = theme.colorScheme;
  final turns = (session?.turns ?? const <InterviewTurn>[]).asMap().entries.map(
    (entry) {
      final index = entry.key;
      final turn = entry.value;
      final score = turn.evaluation.overallScore.clamp(0, 100);
      final wordCount = turn.answer
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final richness = ((wordCount / 45) * 100).round().clamp(0, 100);
      final quality = ((score * 0.8) + (richness * 0.2)).round().clamp(0, 100);
      return InterviewTurnAnalytics(
        label: 'R${index + 1}',
        score: score,
        quality: quality,
        responseSeconds: turn.responseDurationSeconds < 0
            ? 0
            : turn.responseDurationSeconds,
      );
    },
  ).toList();

  final totalResponseSeconds = turns.fold<int>(
    0,
    (sum, turn) => sum + turn.responseSeconds,
  );
  final averageQuality = turns.isEmpty
      ? results.overallScore
      : (turns.fold<int>(0, (sum, turn) => sum + turn.quality) / turns.length)
            .round();
  final averageResponseSeconds = turns.isEmpty
      ? 0
      : (totalResponseSeconds / turns.length).round();

  return InterviewAnalyticsSnapshot(
    overallScore: results.overallScore,
    averageQuality: averageQuality,
    averageResponseSeconds: averageResponseSeconds,
    totalResponseSeconds: totalResponseSeconds,
    turns: turns,
    breakdownSlices: [
      InterviewPieSlice(
        label: 'Comunicacion',
        value: results.breakdown.communication.toDouble(),
        color: scheme.primary,
      ),
      InterviewPieSlice(
        label: 'Tecnico',
        value: results.breakdown.technicalKnowledge.toDouble(),
        color: scheme.secondary,
      ),
      InterviewPieSlice(
        label: 'Confianza',
        value: results.breakdown.confidence.toDouble(),
        color: scheme.tertiary,
      ),
    ],
  );
}

class StatsSummaryChips extends StatelessWidget {
  const StatsSummaryChips({super.key, required this.analytics});

  final InterviewAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricChip(
          label: 'Score general',
          value: '${analytics.overallScore}/100',
          icon: Icons.emoji_events_rounded,
        ),
        _MetricChip(
          label: 'Calidad promedio',
          value: '${analytics.averageQuality}/100',
          icon: Icons.auto_graph_rounded,
        ),
        _MetricChip(
          label: 'Tiempo promedio',
          value: '${analytics.averageResponseSeconds}s',
          icon: Icons.timer_outlined,
        ),
        _MetricChip(
          label: 'Tiempo total',
          value: '${analytics.totalResponseSeconds}s',
          icon: Icons.schedule_rounded,
        ),
      ],
    );
  }
}

class InterviewPieChartCard extends StatelessWidget {
  const InterviewPieChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.slices,
  });

  final String title;
  final String subtitle;
  final List<InterviewPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _PieChartPainter(slices: slices),
                  child: Center(
                    child: Text(
                      total.round().toString(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final slice in slices) ...[
                      _LegendRow(
                        color: slice.color,
                        label: slice.label,
                        value: slice.value.round().toString(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InterviewBarChartCard extends StatelessWidget {
  const InterviewBarChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bars,
    required this.maxValue,
    required this.barColor,
    required this.valueSuffix,
  });

  final String title;
  final String subtitle;
  final List<InterviewTurnAnalytics> bars;
  final int maxValue;
  final Color barColor;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: bars.isEmpty
                ? Center(
                    child: Text(
                      'Aun no hay datos suficientes para graficar.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final bar in bars)
                        Expanded(
                          child: _SingleBar(
                            label: bar.label,
                            value: valueSuffix == 's'
                                ? bar.responseSeconds
                                : valueSuffix == '/100'
                                ? bar.quality
                                : bar.score,
                            maxValue: maxValue,
                            color: barColor,
                            valueSuffix: valueSuffix,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value),
      ],
    );
  }
}

class _SingleBar extends StatelessWidget {
  const _SingleBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.valueSuffix,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final safeMax = maxValue <= 0 ? 1 : maxValue;
    final ratio = (value / safeMax).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value$valueSuffix',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: math.max(ratio, 0.04),
                child: Container(
                  width: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.slices});

  final List<InterviewPieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2,
    );

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(14), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
