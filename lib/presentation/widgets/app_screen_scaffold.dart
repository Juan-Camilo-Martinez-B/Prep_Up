import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';

class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.background,
    this.padding = const EdgeInsets.all(16),
    this.centerTitle = false,
    this.extendBodyBehindAppBar = false,
    this.showBackButton = true,
  });

  final String title;
  final Widget body;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? background;
  final EdgeInsetsGeometry padding;
  final bool centerTitle;
  final bool extendBodyBehindAppBar;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: AppBar(
        title: titleWidget ?? Text(title),
        centerTitle: centerTitle,
        actions: actions,
        automaticallyImplyLeading: false,
        leading: (showBackButton && canPop)
            ? BackButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    nav.maybePop();
                  }
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          SafeArea(
            child: Padding(padding: padding, child: body),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class TechBackground extends StatelessWidget {
  const TechBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -150,
          left: -100,
          child: _GlowBlob(
            color: scheme.primary,
            size: 400,
            opacity: isDark ? 0.35 : 0.20,
          ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child: _GlowBlob(
            color: scheme
                .primary, // Using primary for both spots in the crypto aesthetic
            size: 500,
            opacity: isDark ? 0.25 : 0.15,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.05,
              child: CustomPaint(
                painter: _DotGridPainter(color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 28.0; // wider spacing for a cleaner look
    const radius = 1.0;

    for (double y = 14; y < size.height; y += step) {
      for (double x = 14; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
