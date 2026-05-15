import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class ChartData {
  const ChartData({required this.score, required this.label});
  final double score;
  final String label;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ChartData> _scoreHistory = [];
  int _totalInterviews = 0;
  int _avgOverallScore = 0;
  InterviewSessionModel? _latestSession;
  InterviewResultsModel? _latestResult;
  String _firstName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final l10n = context.l10n;
    final authService = context.read<AuthService>();
    final dbService = context.read<RelationalDatabaseService>();

    final user = authService.currentUser;
    if (user != null) {
      final dbUser = await dbService.getUserById(user.id);
      final history = await dbService.getInterviewHistoryForUser(user.id);

      final List<ChartData> dataPoints = [];
      int totalScore = 0;
      int resultsCount = 0;
      InterviewSessionModel? latestSession;
      InterviewResultsModel? latestResult;

      for (var i = 0; i < history.length; i++) {
        final session = history[i];
        final result = await dbService.getInterviewResultForSession(session.id);

        if (result != null) {
          if (resultsCount < 7) {
            final date = session.createdAt;
            final label =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
            dataPoints.add(
              ChartData(score: result.overallScore.toDouble(), label: label),
            );
          }
          totalScore += result.overallScore;
          resultsCount++;

          if (latestSession == null) {
            latestSession = session;
            latestResult = result;
          }
        }
      }

      if (mounted) {
        setState(() {
          _firstName = dbUser?.displayName.split(' ').first ?? l10n.profileDemoName;

          var historyData = dataPoints.reversed.toList();
          if (historyData.length == 1) {
            historyData.insert(
              0,
              ChartData(score: historyData.first.score, label: l10n.statsLabelChartStart),
            );
          }

          _scoreHistory = historyData;
          _totalInterviews = resultsCount;
          _avgOverallScore = resultsCount > 0
              ? (totalScore / resultsCount).round()
              : 0;
          _latestSession = latestSession;
          _latestResult = latestResult;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: AppScreenScaffold(
        title: '',
        showBackButton: false,
        background: const TechBackground(),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_rounded),
            tooltip: l10n.dashboardSettingsTooltip,
          ),
        ],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          height: 72,
          width: 72,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              context.read<InterviewConfigController>().reset();
              Navigator.of(context).pushNamed(AppRoutes.selectInterviewType);
            },
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: const CircleBorder(),
            elevation: 0,
            child: const Icon(Icons.play_arrow_rounded, size: 36),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: Theme.of(context).cardColor.withValues(alpha: 0.85),
          elevation: 0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.person_outline_rounded,
                  label: l10n.dashboardNavProfile,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.profile),
                ),
                const SizedBox(width: 48),
                _NavBarItem(
                  icon: Icons.history_rounded,
                  label: l10n.dashboardNavHistory,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.interviewHistory),
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  // Welcome Header
                  Text(
                    l10n.dashboardWelcomeGreeting(_firstName),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _totalInterviews == 0
                        ? l10n.dashboardSubtitleEmpty
                        : l10n.dashboardSubtitleReady,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_totalInterviews == 0) ...[
                    // Empty State
                    AppCard(
                      title: l10n.dashboardEmptyStateTitle,
                      subtitle: l10n.dashboardEmptyStateSubtitle,
                      leading: Icon(
                        Icons.rocket_launch_rounded,
                        color: scheme.primary,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Icon(
                            Icons.insights_rounded,
                            size: 64,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.dashboardEmptyStateBody,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Glowing Line Chart
                    AppCard(
                      title: l10n.dashboardChartTitle,
                      subtitle: l10n.dashboardChartSubtitle(_scoreHistory.length),
                      leading: Icon(
                        Icons.show_chart_rounded,
                        color: scheme.primary,
                      ),
                      child: SizedBox(
                        height: 220,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            bottom: 8,
                            left: 8,
                            right: 8,
                          ),
                          child: _GlowingLineChart(data: _scoreHistory),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Real Metrics
                    _NeonStatItem(
                      index: _avgOverallScore.toString(),
                      title: l10n.dashboardStatAvgScoreTitle,
                      subtitle: l10n.dashboardStatAvgScoreSubtitle(_totalInterviews),
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _NeonStatItem(
                      index: _totalInterviews.toString(),
                      title: l10n.dashboardStatTotalTitle,
                      subtitle: l10n.dashboardStatTotalSubtitle,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity Card
                    Text(
                      l10n.dashboardLastInterviewLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        if (_latestSession != null && _latestResult != null) {
                          Navigator.of(context).pushNamed(
                            AppRoutes.generalResults,
                            arguments: {
                              'results': _latestResult,
                              'session': _latestSession,
                            },
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: scheme.secondary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.work_outline_rounded,
                                color: scheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _latestSession?.jobRole.name ??
                                        l10n.dashboardJobRoleFallback,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.dashboardScoreDetail(_latestResult?.overallScore ?? 0),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _GlowingLineChart extends StatefulWidget {
  const _GlowingLineChart({required this.data});

  final List<ChartData> data;

  @override
  State<_GlowingLineChart> createState() => _GlowingLineChartState();
}

class _GlowingLineChartState extends State<_GlowingLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _GlowingLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _LineChartPainter(
            color1: Theme.of(context).colorScheme.primary,
            color2: Colors.purpleAccent,
            data: widget.data,
            progress: _animation.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.color1,
    required this.color2,
    required this.data,
    required this.progress,
  });

  final Color color1;
  final Color color2;
  final List<ChartData> data;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGrid(canvas, w, h);

    if (data.isEmpty) return;

    final points = <Offset>[];
    final paddingX = 20.0;
    final usableW = w - paddingX * 2;

    final paddingTop = 30.0;
    final paddingBottom = 30.0; // Aumentado para separar etiquetas
    final usableH = h - paddingTop - paddingBottom;

    final stepX = data.length > 1 ? usableW / (data.length - 1) : usableW;

    for (var i = 0; i < data.length; i++) {
      final scoreValue = data[i].score;
      final y = paddingTop + usableH - (scoreValue / 100 * usableH);
      points.add(Offset(paddingX + i * stepX, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final animatedPath = metric.extractPath(0.0, metric.length * progress);

      // 1. Fill underneath (Animated via ClipRect)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, paddingX + usableW * progress, h));

      final fillPathStatic = Path.from(path)
        ..lineTo(points.last.dx, usableH + paddingTop)
        ..lineTo(points.first.dx, usableH + paddingTop)
        ..close();

      final fillGradient = ui.Gradient.linear(
        Offset(0, paddingTop),
        Offset(0, usableH + paddingTop),
        [color1.withValues(alpha: 0.3), color1.withValues(alpha: 0.0)],
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = fillGradient;

      canvas.drawPath(fillPathStatic, fillPaint);
      canvas.restore();

      // 2. Shadow path (outer glow)
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = color1.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      canvas.drawPath(animatedPath, shadowPaint);

      // 3. Gradient Line (Sharp)
      final lineGradient = ui.Gradient.linear(
        Offset(0, h * 0.5),
        Offset(w, h * 0.5),
        [color1, color2],
      );

      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = lineGradient;

      canvas.drawPath(animatedPath, linePaint);
    } else if (points.length == 1) {
      // Handle single point edge case
      final animatedPath = Path()
        ..addOval(Rect.fromCircle(center: points.first, radius: 1));
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = color1;
      canvas.drawPath(animatedPath, linePaint);
    }

    // Draw dots and values
    final dotPaint = Paint()..color = Colors.white;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.dx <= paddingX + usableW * progress || points.length == 1) {
        canvas.drawCircle(p, 4, dotPaint);
        canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = color1
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: data[i].score.toInt().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(p.dx - textPainter.width / 2, p.dy - 20),
        );

        final datePainter = TextPainter(
          text: TextSpan(
            text: data[i].label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        datePainter.layout();
        datePainter.paint(
          canvas,
          Offset(p.dx - datePainter.width / 2, usableH + paddingTop + 12),
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, double w, double h) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final paddingTop = 30.0;
    final usableH = h - paddingTop - 30.0; // Consistente con paddingBottom

    final values = [0.0, 50.0, 100.0];
    for (final val in values) {
      final y = paddingTop + usableH - (val / 100 * usableH);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: val.toInt().toString(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(0, y - labelPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}

class _NeonStatItem extends StatelessWidget {
  const _NeonStatItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String index;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                index,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
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

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
