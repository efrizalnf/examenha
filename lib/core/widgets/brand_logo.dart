import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;

  const BrandLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// Removed _BrandLogoPainter as we are now using an image asset.
