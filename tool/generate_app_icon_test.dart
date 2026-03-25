import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Genera assets para launcher icons (fg/bg + ios/png genérico)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = Directory('assets')..createSync(recursive: true);
      expect(dir.existsSync(), isTrue);

      final ios = await _generateIconPng(
        outPath: 'assets/app_icon_ios.png',
        size: 1024,
        contentScale: 0.78,
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFFFFFFFF),
        transparentBg: false,
      );
      final general = await _generateIconPng(
        outPath: 'assets/app_icon.png',
        size: 1024,
        contentScale: 0.78,
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFFFFFFFF),
        transparentBg: false,
      );
      final fg = await _generateIconPng(
        outPath: 'assets/app_icon_fg.png',
        size: 1024,
        contentScale: 0.70,
        backgroundColor: const Color(0x00000000),
        foregroundColor: const Color(0xFFFFFFFF),
        transparentBg: true,
      );
      final bg = await _solidColorPng(
        outPath: 'assets/app_icon_bg.png',
        size: 1024,
        color: const Color(0xFF000000),
      );

      expect(ios.existsSync(), isTrue);
      expect(general.existsSync(), isTrue);
      expect(fg.existsSync(), isTrue);
      expect(bg.existsSync(), isTrue);
    },
  );
}

Future<File> _generateIconPng({
  required String outPath,
  required int size,
  required double contentScale,
  required Color backgroundColor,
  required Color foregroundColor,
  required bool transparentBg,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fullSize = Size(size.toDouble(), size.toDouble());

  if (!transparentBg) {
    canvas.drawRect(Offset.zero & fullSize, Paint()..color = backgroundColor);
  }

  final contentSize = size * contentScale;
  final offset = (size - contentSize) / 2;
  canvas.save();
  canvas.translate(offset, offset);
  _paintLogo(
    canvas,
    Size(contentSize, contentSize),
    backgroundColor: transparentBg ? const Color(0x00000000) : backgroundColor,
    foregroundColor: foregroundColor,
  );
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('No se pudo generar el PNG del icono');
  }

  final file = File(outPath);
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return file;
}

Future<File> _solidColorPng({
  required String outPath,
  required int size,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fullSize = Size(size.toDouble(), size.toDouble());
  canvas.drawRect(Offset.zero & fullSize, Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('No se pudo generar el PNG sólido');
  }
  final file = File(outPath);
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return file;
}

void _paintLogo(
  Canvas canvas,
  Size size, {
  required Color backgroundColor,
  required Color foregroundColor,
}) {
  if (backgroundColor.a > 0) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);
  }

  final center = size.center(Offset.zero);
  final ringPaint = Paint()
    ..color = foregroundColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.shortestSide * 0.06
    ..strokeCap = StrokeCap.round;

  final ringRect = Rect.fromCenter(
    center: center,
    width: size.width * 1.02,
    height: size.height * 0.68,
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
        Rect.fromLTWH(pRect.left, pRect.top, pRect.width, pRect.height * 0.62),
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
