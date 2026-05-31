import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'brand_logo.dart';

class BrandLoader extends StatefulWidget {
  final double size;

  const BrandLoader({super.key, this.size = 168});

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _OrbitDotsPainter(progress: _controller.value),
            child: Center(child: BrandLogo(size: widget.size * 0.34)),
          );
        },
      ),
    );
  }
}

class _OrbitDotsPainter extends CustomPainter {
  final double progress;

  const _OrbitDotsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const dots = 10;
    final center = size.center(Offset.zero);
    final radius = size.width * 0.39;

    for (var index = 0; index < dots; index++) {
      final normalized = index / dots;
      final angle = (math.pi * 2 * (normalized + progress)) - math.pi / 2;
      final dotCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final delta = ((normalized - progress).abs()) % 1;
      final emphasis = 1 - delta;
      final dotRadius = lerpDouble(4, 8, emphasis * 0.9)!;
      final color = Color.lerp(
        AppColors.accent.withValues(alpha: 0.25),
        AppColors.primary,
        emphasis,
      )!;
      canvas.drawCircle(dotCenter, dotRadius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
