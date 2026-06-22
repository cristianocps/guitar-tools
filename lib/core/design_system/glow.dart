import 'package:flutter/material.dart';

/// Reusable animation helpers shared across features.

/// A widget that continuously pulses (scales) its [child] between 1.0 and
/// [maxScale] using [SingleTickerProviderStateMixin] for a vsync-backed,
/// 60fps-friendly animation.
class PulseScale extends StatefulWidget {
  const PulseScale({
    required this.child,
    this.maxScale = 1.15,
    this.duration = const Duration(milliseconds: 700),
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final double maxScale;
  final Duration duration;
  final bool enabled;

  @override
  State<PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<PulseScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.maxScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Wraps [child] with a soft colored glow rendered behind it.
class NeonGlow extends StatelessWidget {
  const NeonGlow({
    required this.child,
    required this.color,
    this.radius = 24,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
