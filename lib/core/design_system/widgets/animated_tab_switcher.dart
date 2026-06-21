import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Indexed tab content with a subtle fade + slide entrance when the selected
/// index changes. Preserves the state of every child via [IndexedStack].
class AnimatedTabSwitcher extends StatefulWidget {
  const AnimatedTabSwitcher({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;

  final List<Widget> children;

  @override
  State<AnimatedTabSwitcher> createState() => _AnimatedTabSwitcherState();
}

class _AnimatedTabSwitcherState extends State<AnimatedTabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.emphasis));
    _controller.value = 1; // fully visible on first build.
  }

  @override
  void didUpdateWidget(covariant AnimatedTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}
