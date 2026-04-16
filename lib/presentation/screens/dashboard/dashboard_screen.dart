import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: '', // Empty title to fully customize the top area
      titleWidget: const Text(
        'Mi Cuenta',
        style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
      ),
      background: const TechBackground(),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.menu_rounded), // Hamburger menu like in image
          tooltip: 'Menú',
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
                label: 'Perfil',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(width: 48), // Space for FAB
              _NavBarItem(
                icon: Icons.history_rounded,
                label: 'Historial',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.interviewHistory),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          Text(
            'Estadísticas Diarias',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          // --- GLOWING CHART CARD ---
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
                )
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 8, left: 16, right: 16),
              child: _GlowingLineChart(),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- SPECIFIC STATISTICS LIST ---
          _NeonStatItem(
            index: '01',
            title: 'Precisión Técnica',
            subtitle: 'Tu precisión al responder preguntas de código ha subido un 15% estadísticamente.',
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          const _NeonStatItem(
            index: '02',
            title: 'Fluidez Verbal',
            subtitle: 'Muestras una gran cadencia. Continúa reduciendo las muletillas durante la entrevista.',
            color: Colors.purpleAccent,
          ),
          const SizedBox(height: 24),

          // --- BAR CHART SIMULATION (Acciones Rápidas con estilo barras) ---
          Text(
            'Modos de Práctica',
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
                    Navigator.of(context).pushNamed(AppRoutes.selectInterviewType);
                  },
                  label: 'Entrenar',
                ),
                _BarAction(
                  height: 90,
                  color: Colors.purpleAccent,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.statistics),
                  label: 'Métricas',
                ),
                _BarAction(
                  height: 40,
                  color: Colors.cyanAccent,
                  onTap: () {},
                  label: 'Consejos',
                ),
                _BarAction(
                  height: 75,
                  color: scheme.primary,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingLineChart extends StatelessWidget {
  const _GlowingLineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        color1: Theme.of(context).colorScheme.primary,
        color2: Colors.purpleAccent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.color1, required this.color2});

  final Color color1;
  final Color color2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Simulate some chart points
    final points = [
      Offset(0, h * 0.7),
      Offset(w * 0.15, h * 0.3),
      Offset(w * 0.3, h * 0.6),
      Offset(w * 0.5, h * 0.1), // peak
      Offset(w * 0.7, h * 0.8),
      Offset(w * 0.85, h * 0.4),
      Offset(w, h * 0.6),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Glowing shadow path
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = color1.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
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

    final fillGradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, h),
      [
        color1.withValues(alpha: 0.3),
        color1.withValues(alpha: 0.0),
      ],
    );

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
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
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
                  )
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
