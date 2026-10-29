import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/physics/spring_solver.dart';

/// Two-dimensional ([Offset]) velocity-preserving analytical spring solver.
class SpringSolver2D {
  /// Creates a 2D spring solver starting at [initialOffset] with [profile].
  SpringSolver2D({
    required Offset initialOffset,
    SpringProfile profile = SpringProfile.fluid,
  }) : _x = SpringSolver1D(initialValue: initialOffset.dx, profile: profile),
       _y = SpringSolver1D(initialValue: initialOffset.dy, profile: profile);

  final SpringSolver1D _x;
  final SpringSolver1D _y;

  /// Current 2D position.
  Offset get position => Offset(_x.position, _y.position);

  /// Target 2D position.
  Offset get target => Offset(_x.target, _y.target);

  /// Current 2D velocity vector (pixels/second).
  Offset get velocity => Offset(_x.velocity, _y.velocity);

  /// Whether both axes have settled at their target positions.
  bool get isSettled => _x.isSettled && _y.isSettled;

  /// Updates the spring profile on both axes.
  set profile(SpringProfile nextProfile) {
    _x.profile = nextProfile;
    _y.profile = nextProfile;
  }

  /// Updates the 2D target while preserving instantaneous velocity.
  void setTarget(Offset nextTarget, {Offset? injectVelocity}) {
    _x.setTarget(nextTarget.dx, injectVelocity: injectVelocity?.dx);
    _y.setTarget(nextTarget.dy, injectVelocity: injectVelocity?.dy);
  }

  /// Immediately snaps the 2D position to [value].
  void jumpTo(Offset value, {Offset velocity = Offset.zero}) {
    _x.jumpTo(value.dx, velocity: velocity.dx);
    _y.jumpTo(value.dy, velocity: velocity.dy);
  }

  /// Advances both axes by [dtSeconds].
  bool step(double dtSeconds) {
    final sx = _x.step(dtSeconds);
    final sy = _y.step(dtSeconds);
    return sx && sy;
  }
}

/// Four-dimensional ([Rect] — left, top, width, height) geometric morphing spring solver.
class SpringRectSolver {
  /// Creates a 4D rectangle spring solver starting at [initialRect] with [profile].
  SpringRectSolver({
    required Rect initialRect,
    SpringProfile profile = SpringProfile.fluid,
  }) : _left = SpringSolver1D(initialValue: initialRect.left, profile: profile),
       _top = SpringSolver1D(initialValue: initialRect.top, profile: profile),
       _width = SpringSolver1D(
         initialValue: initialRect.width,
         profile: profile,
       ),
       _height = SpringSolver1D(
         initialValue: initialRect.height,
         profile: profile,
       );

  final SpringSolver1D _left;
  final SpringSolver1D _top;
  final SpringSolver1D _width;
  final SpringSolver1D _height;

  /// Current interpolated [Rect] geometry.
  Rect get rect => Rect.fromLTWH(
    _left.position,
    _top.position,
    math.max(0.0, _width.position),
    math.max(0.0, _height.position),
  );

  /// Target [Rect] geometry.
  Rect get target =>
      Rect.fromLTWH(_left.target, _top.target, _width.target, _height.target);

  /// Whether all four dimensions have settled.
  bool get isSettled =>
      _left.isSettled &&
      _top.isSettled &&
      _width.isSettled &&
      _height.isSettled;

  /// Updates the spring profile across all four dimensions.
  set profile(SpringProfile nextProfile) {
    _left.profile = nextProfile;
    _top.profile = nextProfile;
    _width.profile = nextProfile;
    _height.profile = nextProfile;
  }

  /// Updates the target [Rect] geometry while preserving velocity.
  void setTarget(Rect nextRect, {Offset? injectVelocity}) {
    _left.setTarget(nextRect.left, injectVelocity: injectVelocity?.dx);
    _top.setTarget(nextRect.top, injectVelocity: injectVelocity?.dy);
    _width.setTarget(nextRect.width);
    _height.setTarget(nextRect.height);
  }

  /// Immediately snaps all four dimensions to [value].
  void jumpTo(Rect value) {
    _left.jumpTo(value.left);
    _top.jumpTo(value.top);
    _width.jumpTo(value.width);
    _height.jumpTo(value.height);
  }

  /// Advances all four dimensions by [dtSeconds].
  bool step(double dtSeconds) {
    final l = _left.step(dtSeconds);
    final t = _top.step(dtSeconds);
    final w = _width.step(dtSeconds);
    final h = _height.step(dtSeconds);
    return l && t && w && h;
  }
}
