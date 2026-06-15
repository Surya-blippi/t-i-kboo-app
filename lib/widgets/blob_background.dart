import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Soft neon blobs blurred behind content — that premium gradient-mesh look.
class BlobBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const BlobBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors ?? const [AppColors.violet, AppColors.pink, AppColors.lime];
    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppColors.ink)),
        Positioned(top: -120, left: -80, child: _blob(c[0], 320)),
        Positioned(top: 180, right: -110, child: _blob(c[1 % c.length], 280)),
        Positioned(
            bottom: -140, left: -60, child: _blob(c[2 % c.length], 360)),
        Positioned.fill(child: Container(color: AppColors.ink.withOpacity(0.55))),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
