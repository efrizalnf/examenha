import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final brandingDir = Directory('assets/branding')..createSync(recursive: true);

  final icon = _buildBrandImage(1024);
  File(
    '${brandingDir.path}/app_icon.png',
  ).writeAsBytesSync(img.encodePng(icon));

  final logo = _buildBrandImage(720);
  File(
    '${brandingDir.path}/app_logo.png',
  ).writeAsBytesSync(img.encodePng(logo));
}

img.Image _buildBrandImage(int size) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 0));

  final scale = size / 512.0;

  _fillRoundedRect(
    canvas,
    left: (105 * scale).round(),
    top: (42 * scale).round(),
    right: (365 * scale).round(),
    bottom: (396 * scale).round(),
    radius: (28 * scale).round(),
    color: img.ColorRgb8(78, 199, 213),
  );

  _fillCircle(
    canvas,
    centerX: (285 * scale).round(),
    centerY: (124 * scale).round(),
    radius: (52 * scale).round(),
    color: img.ColorRgba8(19, 126, 136, 70),
  );
  _fillCircle(
    canvas,
    centerX: (285 * scale).round(),
    centerY: (124 * scale).round(),
    radius: (24 * scale).round(),
    color: img.ColorRgb8(17, 116, 126),
  );

  _fillRoundedRect(
    canvas,
    left: (28 * scale).round(),
    top: (112 * scale).round(),
    right: (212 * scale).round(),
    bottom: (316 * scale).round(),
    radius: (20 * scale).round(),
    color: img.ColorRgb8(23, 151, 159),
  );
  _fillRoundedRect(
    canvas,
    left: (44 * scale).round(),
    top: (128 * scale).round(),
    right: (206 * scale).round(),
    bottom: (308 * scale).round(),
    radius: (18 * scale).round(),
    color: img.ColorRgb8(29, 165, 173),
  );

  _fillRect(
    canvas,
    left: (78 * scale).round(),
    top: (150 * scale).round(),
    right: (112 * scale).round(),
    bottom: (274 * scale).round(),
    color: img.ColorRgb8(255, 255, 255),
  );
  _fillRect(
    canvas,
    left: (78 * scale).round(),
    top: (150 * scale).round(),
    right: (150 * scale).round(),
    bottom: (184 * scale).round(),
    color: img.ColorRgb8(255, 255, 255),
  );
  _fillRect(
    canvas,
    left: (78 * scale).round(),
    top: (202 * scale).round(),
    right: (142 * scale).round(),
    bottom: (234 * scale).round(),
    color: img.ColorRgb8(255, 255, 255),
  );

  _fillRoundedRect(
    canvas,
    left: (254 * scale).round(),
    top: (158 * scale).round(),
    right: (482 * scale).round(),
    bottom: (464 * scale).round(),
    radius: (18 * scale).round(),
    color: img.ColorRgb8(105, 64, 189),
  );
  _fillTriangle(
    canvas,
    x1: (404 * scale).round(),
    y1: (158 * scale).round(),
    x2: (482 * scale).round(),
    y2: (158 * scale).round(),
    x3: (482 * scale).round(),
    y3: (236 * scale).round(),
    color: img.ColorRgb8(190, 170, 231),
  );
  _drawDocumentOutline(canvas, scale);
  _drawDocumentDetails(canvas, scale);
  _drawHeart(canvas, scale);

  return canvas;
}

void _drawHeart(img.Image canvas, double scale) {
  final centerX = 241 * scale;
  final centerY = 246 * scale;
  final radius = 42 * scale;

  for (var y = (170 * scale).round(); y <= (338 * scale).round(); y++) {
    for (var x = (156 * scale).round(); x <= (322 * scale).round(); x++) {
      final nx = (x - centerX) / radius;
      final ny = (y - centerY) / radius;
      final value =
          math.pow(nx * nx + ny * ny - 1, 3) - nx * nx * math.pow(ny, 3);
      if (value <= 0) {
        final highlight =
            x > centerX + radius * 0.4 && y < centerY - radius * 0.1;
        final color = highlight
            ? img.ColorRgb8(255, 192, 174)
            : (x < centerX
                  ? img.ColorRgb8(255, 86, 79)
                  : img.ColorRgb8(255, 99, 93));
        canvas.setPixel(x, y, color);
      }
    }
  }
}

void _drawDocumentOutline(img.Image canvas, double scale) {
  final black = img.ColorRgb8(14, 8, 22);

  img.drawLine(
    canvas,
    x1: (270 * scale).round(),
    y1: (158 * scale).round(),
    x2: (404 * scale).round(),
    y2: (158 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (270 * scale).round(),
    y1: (158 * scale).round(),
    x2: (270 * scale).round(),
    y2: (442 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (270 * scale).round(),
    y1: (442 * scale).round(),
    x2: (456 * scale).round(),
    y2: (442 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (482 * scale).round(),
    y1: (184 * scale).round(),
    x2: (482 * scale).round(),
    y2: (420 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (456 * scale).round(),
    y1: (442 * scale).round(),
    x2: (482 * scale).round(),
    y2: (420 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (404 * scale).round(),
    y1: (158 * scale).round(),
    x2: (482 * scale).round(),
    y2: (236 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (404 * scale).round(),
    y1: (158 * scale).round(),
    x2: (404 * scale).round(),
    y2: (206 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
  img.drawLine(
    canvas,
    x1: (404 * scale).round(),
    y1: (206 * scale).round(),
    x2: (454 * scale).round(),
    y2: (206 * scale).round(),
    color: black,
    thickness: (8 * scale).clamp(2, 20).round(),
  );
}

void _drawDocumentDetails(img.Image canvas, double scale) {
  final black = img.ColorRgb8(14, 8, 22);
  final white = img.ColorRgb8(255, 255, 255);
  final lineThickness = (14 * scale).clamp(3, 24).round();

  for (final row in [292, 338, 384]) {
    _fillCircle(
      canvas,
      centerX: (305 * scale).round(),
      centerY: (row * scale).round(),
      radius: (15 * scale).round(),
      color: black,
    );
    _fillCircle(
      canvas,
      centerX: (305 * scale).round(),
      centerY: (row * scale).round(),
      radius: (6 * scale).round(),
      color: white,
    );
  }

  for (final row in [284, 330, 376]) {
    _drawPillLine(
      canvas,
      left: (338 * scale).round(),
      top: (row * scale).round(),
      width: (108 * scale).round(),
      height: (26 * scale).round(),
      outer: black,
      inner: white,
      thickness: lineThickness,
    );
  }
}

void _drawPillLine(
  img.Image canvas, {
  required int left,
  required int top,
  required int width,
  required int height,
  required img.Color outer,
  required img.Color inner,
  required int thickness,
}) {
  final radius = height ~/ 2;
  _fillRoundedRect(
    canvas,
    left: left,
    top: top,
    right: left + width,
    bottom: top + height,
    radius: radius,
    color: outer,
  );

  final inset = thickness ~/ 3;
  _fillRoundedRect(
    canvas,
    left: left + inset,
    top: top + inset,
    right: left + width - inset,
    bottom: top + height - inset,
    radius: math.max(1, radius - inset),
    color: inner,
  );
}

void _fillTriangle(
  img.Image canvas, {
  required int x1,
  required int y1,
  required int x2,
  required int y2,
  required int x3,
  required int y3,
  required img.Color color,
}) {
  final minX = math.min(x1, math.min(x2, x3));
  final maxX = math.max(x1, math.max(x2, x3));
  final minY = math.min(y1, math.min(y2, y3));
  final maxY = math.max(y1, math.max(y2, y3));
  final denominator = ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
      .toDouble();

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final a = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denominator;
      final b = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denominator;
      final c = 1 - a - b;
      if (a >= 0 && b >= 0 && c >= 0) {
        canvas.setPixel(x, y, color);
      }
    }
  }
}

void _fillRoundedRect(
  img.Image canvas, {
  required int left,
  required int top,
  required int right,
  required int bottom,
  required int radius,
  required img.Color color,
}) {
  final safeRadius = math.max(1, radius);
  _fillRect(
    canvas,
    left: left + safeRadius,
    top: top,
    right: right - safeRadius,
    bottom: bottom,
    color: color,
  );
  _fillRect(
    canvas,
    left: left,
    top: top + safeRadius,
    right: right,
    bottom: bottom - safeRadius,
    color: color,
  );

  _fillCircle(
    canvas,
    centerX: left + safeRadius,
    centerY: top + safeRadius,
    radius: safeRadius,
    color: color,
  );
  _fillCircle(
    canvas,
    centerX: right - safeRadius,
    centerY: top + safeRadius,
    radius: safeRadius,
    color: color,
  );
  _fillCircle(
    canvas,
    centerX: left + safeRadius,
    centerY: bottom - safeRadius,
    radius: safeRadius,
    color: color,
  );
  _fillCircle(
    canvas,
    centerX: right - safeRadius,
    centerY: bottom - safeRadius,
    radius: safeRadius,
    color: color,
  );
}

void _fillRect(
  img.Image canvas, {
  required int left,
  required int top,
  required int right,
  required int bottom,
  required img.Color color,
}) {
  img.fillRect(canvas, x1: left, y1: top, x2: right, y2: bottom, color: color);
}

void _fillCircle(
  img.Image canvas, {
  required int centerX,
  required int centerY,
  required int radius,
  required img.Color color,
}) {
  img.fillCircle(
    canvas,
    x: centerX,
    y: centerY,
    radius: math.max(1, radius),
    color: color,
  );
}
