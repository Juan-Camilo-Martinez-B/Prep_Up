import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session.dart';
import 'package:prep_up/l10n/app_localizations.dart';

// ──────────────────────────────────────────────
// Data models
// ──────────────────────────────────────────────

class InterviewAnalyticsSnapshot {
  const InterviewAnalyticsSnapshot({
    required this.overallScore,
    required this.averageQuality,
    required this.averageResponseSeconds,
    required this.totalResponseSeconds,
    required this.validAnswersCount,
    required this.turns,
    required this.breakdownSlices,
  });

  final int overallScore;
  final int averageQuality;
  final int averageResponseSeconds;
  final int totalResponseSeconds;
  final int validAnswersCount;
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

// ──────────────────────────────────────────────
// Builder
// ──────────────────────────────────────────────

InterviewAnalyticsSnapshot buildInterviewAnalytics({
  required ThemeData theme,
  required AppLocalizations l10n,
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
        label: '${l10n.statsLabelQuestionPrefix}${index + 1}',
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
      ? results.averageResponseSeconds
      : (totalResponseSeconds / turns.length).round();

  return InterviewAnalyticsSnapshot(
    overallScore: results.overallScore,
    averageQuality: averageQuality,
    averageResponseSeconds: averageResponseSeconds,
    totalResponseSeconds: totalResponseSeconds > 0
        ? totalResponseSeconds
        : results.totalResponseSeconds,
    turns: turns,
    breakdownSlices: [
      InterviewPieSlice(
        label: l10n.statsBreakdownCommunication,
        value: results.breakdown.communication.toDouble(),
        color: scheme.primary,
      ),
      InterviewPieSlice(
        label: l10n.statsBreakdownMastery,
        value: results.breakdown.subjectMastery.toDouble(),
        color: scheme.secondary,
      ),
      InterviewPieSlice(
        label: l10n.statsBreakdownConfidence,
        value: results.breakdown.confidence.toDouble(),
        color: scheme.tertiary,
      ),
    ],
    validAnswersCount: results.validAnswersCount > 0
        ? results.validAnswersCount
        : turns.length,
  );
}

// ──────────────────────────────────────────────
// Score ring widget
// ──────────────────────────────────────────────

class ScoreRingWidget extends StatelessWidget {
  const ScoreRingWidget({
    super.key,
    required this.score,
    required this.size,
    this.strokeWidth = 14,
  });

  final int score;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = score >= 70
        ? scheme.primary
        : score >= 50
        ? scheme.secondary
        : scheme.error;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: score / 100,
          color: color,
          trackColor: scheme.surfaceContainerHighest,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '/100',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Summary metric cards (grid)
// ──────────────────────────────────────────────

class StatsSummaryGrid extends StatelessWidget {
  const StatsSummaryGrid({super.key, required this.analytics});

  final InterviewAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final items = [
      _GridItem(
        icon: Icons.emoji_events_rounded,
        color: scheme.primary,
        label: l10n.statsGridScoreGeneral,
        value: '${analytics.overallScore}/100',
      ),
      _GridItem(
        icon: Icons.auto_graph_rounded,
        color: scheme.secondary,
        label: l10n.statsGridAvgQuality,
        value: '${analytics.averageQuality}/100',
      ),
      _GridItem(
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        label: l10n.statsGridValidAnswers,
        value: '${analytics.validAnswersCount}',
      ),
      _GridItem(
        icon: Icons.timer_rounded,
        color: scheme.tertiary,
        label: l10n.statsGridAvgTime,
        value: _formatSecs(analytics.averageResponseSeconds),
      ),
      _GridItem(
        icon: Icons.schedule_rounded,
        color: scheme.outline,
        label: l10n.statsGridTotalTime,
        value: _formatSecs(analytics.totalResponseSeconds),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => _StatCard(
              icon: item.icon,
              color: item.color,
              label: item.label,
              value: item.value,
            ),
          )
          .toList(),
    );
  }

  String _formatSecs(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }
}

class _GridItem {
  const _GridItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// keep old alias for backward compat
class StatsSummaryChips extends StatelessWidget {
  const StatsSummaryChips({super.key, required this.analytics});
  final InterviewAnalyticsSnapshot analytics;
  @override
  Widget build(BuildContext context) => StatsSummaryGrid(analytics: analytics);
}

// ──────────────────────────────────────────────
// Donut chart card – no truncated text
// ──────────────────────────────────────────────

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
    final textTheme = Theme.of(context).textTheme;
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return _ChartCard(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          // Donut
          SizedBox(
            height: 180,
            child: total <= 0
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.statsLabelNoData,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _DonutPainter(
                      slices: slices,
                      trackColor: scheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(total / slices.length).round()}',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.statsLabelAverage,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Legend – full width, no truncation
          ...slices.map(
            (slice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LegendBar(slice: slice, total: total),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({required this.slice, required this.total});

  final InterviewPieSlice slice;
  final double total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pct = total > 0 ? slice.value / total : 0.0;
    final score = slice.value.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: slice.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                slice.label,
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$score/100',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(slice.color),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Bar chart card – scrollable, labels not clipped
// ──────────────────────────────────────────────

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

  int _getValue(InterviewTurnAnalytics bar) {
    if (valueSuffix == 's') return bar.responseSeconds;
    if (valueSuffix == '/100') return bar.quality;
    return bar.score;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    return _ChartCard(
      title: title,
      subtitle: subtitle,
      child: bars.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.statsLabelNotEnoughData,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                // Y-axis labels + bars
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Y-axis
                      SizedBox(
                        width: 36,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$safeMax$valueSuffix',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${(safeMax * 0.5).round()}$valueSuffix',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '0$valueSuffix',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bars area – horizontal scroll if many bars
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: bars
                                .map(
                                  (bar) => SizedBox(
                                    width: math.max(
                                      44,
                                      (MediaQuery.of(context).size.width -
                                              120) /
                                          bars.length.clamp(1, 8),
                                    ),
                                    child: _AnimatedBar(
                                      value: _getValue(bar),
                                      maxValue: safeMax,
                                      color: barColor,
                                      label: bar.label,
                                      valueSuffix: valueSuffix,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid lines overlay hint
                const SizedBox(height: 4),
                Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  height: 1,
                ),
              ],
            ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  const _AnimatedBar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.label,
    required this.valueSuffix,
  });

  final int value;
  final int maxValue;
  final Color color;
  final String label;
  final String valueSuffix;

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ratio = (widget.value / widget.maxValue).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final animRatio = ratio * _anim.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Value label on top of bar
              Text(
                '${widget.value}${widget.valueSuffix}',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Bar
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: math.max(animRatio, 0.03),
                    child: Container(
                      width: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // X-axis label – never clipped
              Text(
                widget.label,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Metric progress bar (for detailed analysis)
// ──────────────────────────────────────────────

class MetricProgressBar extends StatelessWidget {
  const MetricProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final double value; // 0.0 – 1.0
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = color ?? scheme.primary;
    final percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: barColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Shared chart card container
// ──────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Painters
// ──────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progress.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.trackColor});

  final List<InterviewPieSlice> slices;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 22.0;
    const gap = 0.03; // radians between slices

    var startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2 - gap;
      if (sweep <= 0) continue;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.slices != slices;
}
