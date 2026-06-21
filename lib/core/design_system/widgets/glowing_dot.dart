import 'package:flutter/material.dart';

/// A small glowing dot, useful as a status/beat indicator.
class GlowingDot extends StatelessWidget {
  const GlowingDot({
    required this.color,
    this.size = 12,
    this.active = true,
    super.key,
  });

  final Color color;

  final double size;

  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color c = active ? color : color.withOpacity(0.25);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: c.withOpacity(0.6),
            blurRadius: size,
            spreadRadius: size * 0.25,
          ),
        ],
      ),
    );
  }
}
