import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:zero_motion/src/physics/gesture_spring_controller.dart';
import 'package:zero_motion/src/physics/spring_multi_solver.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/physics/spring_solver.dart';

/// Geometric presentation modes for [DynamicIslandCapsule].
enum DynamicIslandMode {
  /// Minimal circular/pill indicator.
  minimal,
  /// Standard two-sided compact pill.
  compact,
  /// Full interactive expanded card.
  expanded,
}

/// iOS Dynamic Island-inspired capsule driven by 2D analytical spring physics
/// ([SpringSolver2D]) with rubber-band gesture stretching.
class DynamicIslandCapsule extends StatefulWidget {
  /// Creates a [DynamicIslandCapsule].
  const DynamicIslandCapsule({
    required this.mode,
    required this.compactBuilder,
    required this.expandedBuilder,
    this.minimalBuilder,
    this.onModeChanged,
    this.profile = SpringProfile.bouncy,
    this.minimalSize = const Size(52, 36),
    this.compactSize = const Size(188, 38),
    this.expandedSize = const Size(348, 168),
    this.minimalRadius = 22.0,
    this.compactRadius = 24.0,
    this.expandedRadius = 38.0,
    this.backgroundColor = const Color(0xFF0A0A0F),
    this.borderColor = const Color(0x28FFFFFF),
    super.key,
  });

  /// Active presentation mode of the capsule.
  final DynamicIslandMode mode;
  /// Content builder for [DynamicIslandMode.minimal].
  final WidgetBuilder? minimalBuilder;
  /// Content builder for [DynamicIslandMode.compact].
  final WidgetBuilder compactBuilder;
  /// Content builder for [DynamicIslandMode.expanded].
  final WidgetBuilder expandedBuilder;
  /// Invoked when the user taps or stretches the capsule into a new mode.
  final ValueChanged<DynamicIslandMode>? onModeChanged;
  /// Spring profile used for size and corner transitions.
  final SpringProfile profile;
  /// Target size for [DynamicIslandMode.minimal].
  final Size minimalSize;
  /// Target size for [DynamicIslandMode.compact].
  final Size compactSize;
  /// Target size for [DynamicIslandMode.expanded].
  final Size expandedSize;
  /// Corner radius in minimal mode.
  final double minimalRadius;
  /// Corner radius in compact mode.
  final double compactRadius;
  /// Corner radius in expanded mode.
  final double expandedRadius;
  /// Capsule background color.
  final Color backgroundColor;
  /// Capsule border color.
  final Color borderColor;

  @override
  State<DynamicIslandCapsule> createState() => _DynamicIslandCapsuleState();
}

class _DynamicIslandCapsuleState extends State<DynamicIslandCapsule>
    with SingleTickerProviderStateMixin {
  late final SpringSolver2D _sizeSolver;
  late final SpringSolver1D _radiusSolver;
  late final SpringSolver1D _expandProgressSolver;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  Offset _stretchDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    final s = _sizeForMode(widget.mode);
    _sizeSolver = SpringSolver2D(initialOffset: Offset(s.width, s.height), profile: widget.profile);
    _radiusSolver = SpringSolver1D(initialValue: _radiusForMode(widget.mode), profile: widget.profile);
    _expandProgressSolver = SpringSolver1D(
      initialValue: widget.mode == DynamicIslandMode.expanded ? 1.0 : 0.0,
      profile: widget.profile,
    );
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant DynamicIslandCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sizeSolver.profile = widget.profile;
    _radiusSolver.profile = widget.profile;
    _expandProgressSolver.profile = widget.profile;
    if (oldWidget.mode != widget.mode ||
        oldWidget.expandedSize != widget.expandedSize ||
        oldWidget.compactSize != widget.compactSize) {
      _retargetToMode(widget.mode);
    }
  }

  Size _sizeForMode(DynamicIslandMode m) => switch (m) {
    DynamicIslandMode.minimal => widget.minimalSize,
    DynamicIslandMode.compact => widget.compactSize,
    DynamicIslandMode.expanded => widget.expandedSize,
  };

  double _radiusForMode(DynamicIslandMode m) => switch (m) {
    DynamicIslandMode.minimal => widget.minimalRadius,
    DynamicIslandMode.compact => widget.compactRadius,
    DynamicIslandMode.expanded => widget.expandedRadius,
  };

  void _retargetToMode(DynamicIslandMode targetMode, {Offset? velocity}) {
    final s = _sizeForMode(targetMode);
    _sizeSolver.setTarget(Offset(s.width, s.height), injectVelocity: velocity);
    _radiusSolver.setTarget(_radiusForMode(targetMode));
    _expandProgressSolver.setTarget(targetMode == DynamicIslandMode.expanded ? 1.0 : 0.0);
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed!).inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    final settled = _sizeSolver.step(dt) & _radiusSolver.step(dt) & _expandProgressSolver.step(dt);
    setState(() {});
    if (settled) {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _stretchDelta += details.delta;
      final b = _sizeForMode(widget.mode);
      _sizeSolver.jumpTo(Offset(
        GestureSpringController.applyRubberBand(
          b.width + _stretchDelta.dx * 0.4,
          minBound: widget.minimalSize.width,
          maxBound: widget.expandedSize.width + 20,
          dimension: 80,
        ),
        GestureSpringController.applyRubberBand(
          b.height + _stretchDelta.dy * 0.6,
          minBound: widget.minimalSize.height,
          maxBound: widget.expandedSize.height + 24,
          dimension: 80,
        ),
      ));
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final vy = details.velocity.pixelsPerSecond.dy;
    final dy = _stretchDelta.dy;
    _stretchDelta = Offset.zero;
    var next = widget.mode;
    if (dy > 28 || vy > 320) {
      next = DynamicIslandMode.expanded;
    } else if (dy < -24 || vy < -320) {
      next = DynamicIslandMode.compact;
    }
    if (next != widget.mode) {
      widget.onModeChanged?.call(next);
    }
    _retargetToMode(next, velocity: details.velocity.pixelsPerSecond * 0.3);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _sizeSolver.position;
    final expandT = _expandProgressSolver.position.clamp(0.0, 1.0);
    final collapsed = widget.mode == DynamicIslandMode.minimal && widget.minimalBuilder != null
        ? widget.minimalBuilder!(context)
        : widget.compactBuilder(context);
    return GestureDetector(
      onTap: () {
        final next = widget.mode == DynamicIslandMode.expanded
            ? DynamicIslandMode.compact
            : DynamicIslandMode.expanded;
        widget.onModeChanged?.call(next);
        _retargetToMode(next);
      },
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: RepaintBoundary(
        child: Container(
          width: pos.dx.clamp(36.0, 600.0),
          height: pos.dy.clamp(28.0, 480.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(_radiusSolver.position.clamp(12.0, 64.0)),
            border: Border.all(color: widget.borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0x66000000),
                blurRadius: lerpDouble(12.0, 32.0, expandT) ?? 16.0,
                offset: Offset(0, lerpDouble(4, 14, expandT) ?? 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                ignoring: expandT > 0.45,
                child: Opacity(
                  opacity: (1.0 - expandT * 2.0).clamp(0.0, 1.0),
                  child: OverflowBox(maxWidth: widget.compactSize.width, maxHeight: widget.compactSize.height, child: collapsed),
                ),
              ),
              IgnorePointer(
                ignoring: expandT <= 0.45,
                child: Opacity(
                  opacity: ((expandT - 0.3) / 0.7).clamp(0.0, 1.0),
                  child: OverflowBox(
                    maxWidth: widget.expandedSize.width,
                    maxHeight: widget.expandedSize.height,
                    child: SizedBox.fromSize(
                      size: widget.expandedSize,
                      child: widget.expandedBuilder(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
