import 'package:flutter/widgets.dart';
import 'package:zero_motion/src/physics/gesture_spring_controller.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';

/// Declarative widget that tracks any scalar [value] using 120Hz interruptible
/// spring physics.
///
/// Unlike `TweenAnimationBuilder`, changing [value] mid-flight preserves
/// instantaneous velocity ($C^1$ continuity) with zero motion discontinuity.
class ZeroSpringBuilder extends StatefulWidget {
  /// Creates a [ZeroSpringBuilder].
  const ZeroSpringBuilder({
    required this.value,
    required this.builder,
    this.profile = SpringProfile.fluid,
    this.onSettled,
    this.child,
    super.key,
  });

  /// Target scalar value tracked by the spring.
  final double value;

  /// Physical spring profile.
  final SpringProfile profile;

  /// Called on every tick with `currentValue` and instantaneous `velocity`.
  final Widget Function(
    BuildContext context,
    double currentValue,
    double velocity,
    Widget? child,
  ) builder;

  /// Optional callback invoked when the spring settles at [value].
  final VoidCallback? onSettled;

  /// Optional pre-built subtree passed through to [builder].
  final Widget? child;

  @override
  State<ZeroSpringBuilder> createState() => _ZeroSpringBuilderState();
}

class _ZeroSpringBuilderState extends State<ZeroSpringBuilder>
    with SingleTickerProviderStateMixin {
  late final GestureSpringController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GestureSpringController(
      vsync: this,
      initialValue: widget.value,
      profile: widget.profile,
    )..addListener(_handleTick);
  }

  @override
  void didUpdateWidget(covariant ZeroSpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _controller.profile = widget.profile;
    }
    if (oldWidget.value != widget.value) {
      _controller.animateTo(widget.value);
    }
  }

  void _handleTick() {
    if (!_controller.isAnimating) {
      widget.onSettled?.call();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _controller,
      child: widget.child,
      builder: (context, currentValue, child) {
        return widget.builder(
          context,
          currentValue,
          _controller.velocity,
          child,
        );
      },
    );
  }
}
