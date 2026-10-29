import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Defines physical mass, stiffness, and damping parameters for a 120Hz
/// damped harmonic oscillator spring.
///
/// Unlike traditional `Duration` and `Curve` animations, [SpringProfile] drives
/// motion through real differential equations, enabling mid-flight interruption
/// with full $C^1$ velocity continuity.
@immutable
class SpringProfile {
  /// Creates a [SpringProfile] from physical [mass], [stiffness], and [damping].
  const SpringProfile({
    this.mass = 1.0,
    this.stiffness = 320.0,
    this.damping = 28.0,
    this.positionTolerance = 0.05,
    this.velocityTolerance = 0.5,
  }) : assert(mass > 0, 'Mass must be greater than zero.'),
       assert(stiffness > 0, 'Stiffness must be greater than zero.'),
       assert(damping >= 0, 'Damping cannot be negative.');

  /// Creates an intuitive [SpringProfile] from perceptual [response] (in seconds)
  /// and [dampingRatio] (SwiftUI / Emil Kowalski standard).
  ///
  /// - [response]: Approximate duration to approach target (smaller = faster).
  /// - [dampingRatio]: `1.0` is critically damped (no bounce), `< 1.0` is bouncy,
  ///   and `> 1.0` is over-damped.
  factory SpringProfile.fromResponse({
    double response = 0.38,
    double dampingRatio = 0.82,
    double mass = 1.0,
    double positionTolerance = 0.05,
    double velocityTolerance = 0.5,
  }) {
    final safeResponse = math.max(0.01, response);
    final omega0 = (2.0 * math.pi) / safeResponse;
    final stiffness = mass * omega0 * omega0;
    final damping = 4.0 * math.pi * dampingRatio * mass / safeResponse;
    return SpringProfile(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
      positionTolerance: positionTolerance,
      velocityTolerance: velocityTolerance,
    );
  }

  /// Inertial mass of the spring ($m$).
  final double mass;

  /// Spring constant / stiffness ($k$).
  final double stiffness;

  /// Viscous damping coefficient ($c$).
  final double damping;

  /// Position threshold below which the spring is considered settled.
  final double positionTolerance;

  /// Velocity threshold (units/second) below which the spring is considered settled.
  final double velocityTolerance;

  /// Natural undamped angular frequency ($\omega_0 = \sqrt{k / m}$).
  double get angularFrequency => math.sqrt(stiffness / mass);

  /// Dimensionless damping ratio ($\zeta = \frac{c}{2 \sqrt{k m}}$).
  double get dampingRatio => damping / (2.0 * math.sqrt(stiffness * mass));

  /// Crisp, non-bouncing response ideal for command palettes and toast stacks.
  static const SpringProfile snappy = SpringProfile(
    mass: 1.0,
    stiffness: 480.0,
    damping: 42.0,
  );

  /// Expressive, elastic bounce ideal for Dynamic Island capsules and micro-interactions.
  static const SpringProfile bouncy = SpringProfile(
    mass: 1.0,
    stiffness: 360.0,
    damping: 22.0,
  );

  /// Smooth, organic motion ideal for morphing surfaces and fluid bottom sheets.
  static const SpringProfile fluid = SpringProfile(
    mass: 1.0,
    stiffness: 290.0,
    damping: 30.0,
  );

  /// Soft, relaxed transition ideal for background scrim scaling and large panels.
  static const SpringProfile gentle = SpringProfile(
    mass: 1.0,
    stiffness: 180.0,
    damping: 26.0,
  );

  /// Ultra-responsive profile for direct finger-tracking gestures.
  static const SpringProfile interactive = SpringProfile(
    mass: 0.8,
    stiffness: 900.0,
    damping: 52.0,
  );

  /// Returns a copy of this [SpringProfile] with selected fields replaced.
  SpringProfile copyWith({
    double? mass,
    double? stiffness,
    double? damping,
    double? positionTolerance,
    double? velocityTolerance,
  }) {
    return SpringProfile(
      mass: mass ?? this.mass,
      stiffness: stiffness ?? this.stiffness,
      damping: damping ?? this.damping,
      positionTolerance: positionTolerance ?? this.positionTolerance,
      velocityTolerance: velocityTolerance ?? this.velocityTolerance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SpringProfile &&
        other.mass == mass &&
        other.stiffness == stiffness &&
        other.damping == damping &&
        other.positionTolerance == positionTolerance &&
        other.velocityTolerance == velocityTolerance;
  }

  @override
  int get hashCode => Object.hash(
    mass,
    stiffness,
    damping,
    positionTolerance,
    velocityTolerance,
  );
}
