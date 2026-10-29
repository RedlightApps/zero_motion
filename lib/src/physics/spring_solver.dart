import 'dart:math' as math;
import 'package:zero_motion/src/physics/spring_profile.dart';

/// Closed-form analytical 1D damped harmonic oscillator solver.
///
/// Solves the exact differential equation $m \ddot{x} + c \dot{x} + k(x - x_{\text{target}}) = 0$
/// rather than relying on numerical Euler integration, guaranteeing frame-rate
/// independence across 60Hz, 120Hz, and 240Hz displays and $C^1$ velocity
/// continuity during mid-flight retargeting.
class SpringSolver1D {
  /// Creates a 1D spring solver starting at [initialValue] with [profile].
  SpringSolver1D({
    required double initialValue,
    this.profile = SpringProfile.fluid,
  }) : _position = initialValue,
       _target = initialValue,
       _velocity = 0.0;

  /// Active physical spring profile.
  SpringProfile profile;

  double _position;
  double _target;
  double _velocity;

  /// Current position ($x_t$).
  double get position => _position;

  /// Current target position ($x_{\text{target}}$).
  double get target => _target;

  /// Current instantaneous velocity ($v_t$, in units/second).
  double get velocity => _velocity;

  /// Whether both displacement and velocity are within tolerance of [target].
  bool get isSettled =>
      (_position - _target).abs() <= profile.positionTolerance &&
      _velocity.abs() <= profile.velocityTolerance;

  /// Updates the target position while preserving current velocity ($C^1$ continuity).
  void setTarget(double nextTarget, {double? injectVelocity}) {
    _target = nextTarget;
    if (injectVelocity != null) {
      _velocity = injectVelocity;
    }
  }

  /// Immediately snaps both [position] and [target] to [value].
  void jumpTo(double value, {double velocity = 0.0}) {
    _position = value;
    _target = value;
    _velocity = velocity;
  }

  /// Advances the analytical spring simulation by [dtSeconds].
  ///
  /// Returns `true` if the spring has settled at [target], or `false` if still moving.
  bool step(double dtSeconds) {
    if (dtSeconds <= 0.0) {
      return isSettled;
    }
    final dt = math.min(dtSeconds, 0.1);
    final x0 = _position - _target;
    final v0 = _velocity;

    if (x0.abs() <= profile.positionTolerance &&
        v0.abs() <= profile.velocityTolerance) {
      _position = _target;
      _velocity = 0.0;
      return true;
    }

    final omega0 = profile.angularFrequency;
    final zeta = profile.dampingRatio;

    double nextDisplacement;
    double nextVelocity;

    if (zeta < 1.0 - 1e-6) {
      final omegaD = omega0 * math.sqrt(1.0 - zeta * zeta);
      final decay = math.exp(-zeta * omega0 * dt);
      final a = x0;
      final b = (zeta * omega0 * x0 + v0) / omegaD;
      final cosWt = math.cos(omegaD * dt);
      final sinWt = math.sin(omegaD * dt);

      nextDisplacement = decay * (a * cosWt + b * sinWt);
      nextVelocity =
          decay *
          ((b * omegaD - a * zeta * omega0) * cosWt -
              (a * omegaD + b * zeta * omega0) * sinWt);
    } else if (zeta > 1.0 + 1e-6) {
      final sqrtTerm = math.sqrt(zeta * zeta - 1.0);
      final r1 = -omega0 * (zeta - sqrtTerm);
      final r2 = -omega0 * (zeta + sqrtTerm);
      final c2 = (v0 - r1 * x0) / (r2 - r1);
      final c1 = x0 - c2;
      final e1 = math.exp(r1 * dt);
      final e2 = math.exp(r2 * dt);

      nextDisplacement = c1 * e1 + c2 * e2;
      nextVelocity = c1 * r1 * e1 + c2 * r2 * e2;
    } else {
      final decay = math.exp(-omega0 * dt);
      final a = x0;
      final b = v0 + omega0 * x0;

      nextDisplacement = decay * (a + b * dt);
      nextVelocity = decay * (b - omega0 * (a + b * dt));
    }

    _position = _target + nextDisplacement;
    _velocity = nextVelocity;

    if (isSettled) {
      _position = _target;
      _velocity = 0.0;
      return true;
    }
    return false;
  }
}
