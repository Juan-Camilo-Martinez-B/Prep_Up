import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<double> _scoreHistory = [];
  int _avgTechnical = 0;
  int _avgFluency = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final authService = context.read<AuthService>();
    final dbService = context.read<RelationalDatabaseService>();

    final user = authService.currentUser;
    if (user != null) {
      final history = await dbService.getInterviewHistoryForUser(user.id);
      final List<double> scores = [];
      double totalTech = 0;
      double totalFluency = 0;
      int count = 0;

      for (final session in history.take(7)) {
        // Últimas 7 para el gráfico
        final result = await dbService.getInterviewResultForSession(session.id);
        if (result != null) {
          scores.add(result.overallScore.toDouble());
          // Simulación de breakdown si no está detallado
          totalTech += result.overallScore * 0.9;
          totalFluency += result.overallScore * 0.85;
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _scoreHistory = scores.reversed.toList();
          _avgTechnical = count > 0 ? (totalTech / count).round() : 0;
          _avgFluency = count > 0 ? (totalFluency / count).round() : 0;
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
            icon: const Icon(Icons.menu_rounded),
            tooltip: l10n.dashboardMenuTooltip,
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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            Text(
              l10n.dashboardDailyStats,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _GlowingLineChart(scores: _scoreHistory),
              ),
            ),
            const SizedBox(height: 24),

            _NeonStatItem(
              index: _avgTechnical.toString(),
              title: l10n.dashboardStatTechnicalAccuracyTitle,
              subtitle: l10n.dashboardStatTechnicalAccuracySubtitle,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            _NeonStatItem(
              index: _avgFluency.toString(),
              title: l10n.dashboardStatVerbalFluencyTitle,
              subtitle: l10n.dashboardStatVerbalFluencySubtitle,
              color: Colors.purpleAccent,
            ),
            const SizedBox(height: 24),

            // --- BAR CHART SIMULATION (Acciones Rápidas con estilo barras) ---
            Text(
              l10n.dashboardPracticeModes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _BarAction(
                    height: 60,
                    color: scheme.primary,
                    onTap: () {
                      context.read<InterviewConfigController>().reset();
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.selectInterviewType);
                    },
                    label: l10n.dashboardActionTrain,
                  ),
                  _BarAction(
                    height: 75,
                    color: scheme.primary,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                    label: l10n.dashboardActionSettings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingLineChart extends StatelessWidget {
  const _GlowingLineChart({required this.scores});

  final List<double> scores;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        color1: Theme.of(context).colorScheme.primary,
        color2: Colors.purpleAccent,
        scores: scores,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.color1,
    required this.color2,
    required this.scores,
  });

  final Color color1;
  final Color color2;
  final List<double> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (scores.isEmpty) return;

    final points = <Offset>[];
    final stepX = scores.length > 1 ? w / (scores.length - 1) : w;

    for (var i = 0; i < scores.length; i++) {
      // Normalizar puntaje (0-100) a la altura del canvas
      final y = h - (scores[i] / 100 * h);
      points.add(Offset(i * stepX, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Shadow path (subtle glow)
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = color1.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, shadowPaint);

    // Gradient Line
    final lineGradient = ui.Gradient.linear(
      Offset(0, h * 0.5),
      Offset(w, h * 0.5),
      [color1, color2, color1],
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = lineGradient;

    canvas.drawPath(path, linePaint);

    // Fill underneath
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillGradient = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [
      color1.withValues(alpha: 0.3),
      color1.withValues(alpha: 0.0),
    ]);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = fillGradient;

    canvas.drawPath(fillPath, fillPaint);

    // Draw little dots at data points
    final dotPaint = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = color1.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => false;
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
          // Glowing Circle
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

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.height,
    required this.color,
    required this.onTap,
    required this.label,
  });

  final double height;
  final Color color;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
