import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wraps a child with staggered fade-in + slide-up animation.
/// Use [index] for stagger delay between items.
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration duration;
  final double slideOffset;
  final Axis axis;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 350),
    this.slideOffset = 0.12,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: staggerDelay * index)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .then(duration: Duration.zero)
        .custom(
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final offset = axis == Axis.vertical
                ? Offset(0, (1 - value) * slideOffset * 100)
                : Offset((1 - value) * slideOffset * 100, 0);
            return Transform.translate(offset: offset, child: child);
          },
        );
  }
}

/// Wraps a child with a horizontal stagger animation (slide from right + fade).
class AnimatedHorizontalItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration duration;

  const AnimatedHorizontalItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: staggerDelay * index)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideX(
          begin: 0.15,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
