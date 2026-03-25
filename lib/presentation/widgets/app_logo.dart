import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.borderRadius = 18,
  });

  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _AppLogoPainter(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  const _AppLogoPainter({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.06
      ..strokeCap = StrokeCap.round;

    final ringRect = Rect.fromCenter(
      center: center,
      width: size.width * 1.12,
      height: size.height * 0.74,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.42);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(ringRect, ringPaint);
    canvas.restore();

    final lettersPaint = Paint()..color = foregroundColor;
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final lettersBounds = Rect.fromCenter(
      center: center.translate(0, size.shortestSide * 0.03),
      width: size.width * 0.62,
      height: size.height * 0.42,
    );

    final thickness = lettersBounds.height * 0.26;
    final radius = Radius.circular(thickness * 0.42);

    canvas.saveLayer(Offset.zero & size, Paint());

    final pRect = Rect.fromLTWH(
      lettersBounds.left,
      lettersBounds.top,
      lettersBounds.width * 0.46,
      lettersBounds.height,
    );
    final pOuter = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pRect.left, pRect.top, thickness, pRect.height),
          radius,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            pRect.left,
            pRect.top,
            pRect.width,
            pRect.height * 0.62,
          ),
          radius,
        ),
      );
    canvas.drawPath(pOuter, lettersPaint);

    final pInner = Rect.fromLTWH(
      pRect.left + (thickness * 0.92),
      pRect.top + (thickness * 0.76),
      pRect.width - (thickness * 1.28),
      (pRect.height * 0.62) - (thickness * 1.34),
    );
    if (pInner.width > 0 && pInner.height > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(pInner, Radius.circular(thickness * 0.34)),
        clearPaint,
      );
    }

    final uRect = Rect.fromLTWH(
      lettersBounds.left + (lettersBounds.width * 0.52),
      lettersBounds.top,
      lettersBounds.width * 0.48,
      lettersBounds.height,
    );
    final uOuter = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(uRect.left, uRect.top, thickness, uRect.height),
          radius,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            uRect.right - thickness,
            uRect.top,
            thickness,
            uRect.height,
          ),
          radius,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            uRect.left,
            uRect.bottom - thickness,
            uRect.width,
            thickness,
          ),
          radius,
        ),
      );
    canvas.drawPath(uOuter, lettersPaint);

    final uInner = Rect.fromLTWH(
      uRect.left + (thickness * 0.92),
      uRect.top + (thickness * 0.76),
      uRect.width - (thickness * 1.84),
      uRect.height - (thickness * 1.58),
    );
    if (uInner.width > 0 && uInner.height > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(uInner, Radius.circular(thickness * 0.36)),
        clearPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
