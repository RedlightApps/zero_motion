import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/physics/spring_solver.dart';

/// Reactive 120Hz [Ticker]-driven controller that bridges pointer gestures
/// directly into an analytical [SpringSolver1D].
///
/// Applies iOS-style hyperbolic rubber-band resistance ([applyRubberBand])
/// outside bounds and injects gesture release velocity directly into [animateTo].
class GestureSpringController extends ChangeNotifier
    implements ValueListenable<double> {
  /// Creates a [GestureSpringController] bound to [vsync].
  GestureSpringController({
    required TickerProvider vsync,
    double initialValue = 0.0,
    SpringProfile profile = SpringProfile.fluid,
  }) : _solver = SpringSolver1D(initialValue: initialValue, profile: profile) {
    _ticker = vsync.createTicker(_onTick);
  }

  final SpringSolver1D _solver;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  bool _isDisposed = false;

  @override
  double get value => _solver.position;

  /// Current target value of the spring.
  double get target => _solver.target;

  /// Instantaneous velocity (units/second).
  double get velocity => _solver.velocity;

  /// Whether the ticker is actively stepping the spring simulation.
  bool get isAnimating => _ticker.isActive;

  /// Active physical spring profile.
  SpringProfile get profile => _solver.profile;
  set profile(SpringProfile nextProfile) {
    _solver.profile = nextProfile;
  }

  /// Starts or retargets the velocity-preserving spring toward [targetValue].
  void animateTo(
    double targetValue, {
    double? velocity,
    SpringProfile? customProfile,
  }) {
    if (_isDisposed) {
      return;
    }
    if (customProfile != null) {
      _solver.profile = customProfile;
    }
    _solver.setTarget(targetValue, injectVelocity: velocity);
    if (!_solver.isSettled && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (_solver.isSettled) {
      _stopTicker();
      notifyListeners();
    }
  }

  /// Immediately offsets the value during an active user drag gesture.
  void dragBy(double delta, {double? minBound, double? maxBound}) {
    if (_isDisposed) {
      return;
    }
    _stopTicker();
    var next = _solver.position + delta;
    if (minBound != null && maxBound != null) {
      next = applyRubberBand(next, minBound: minBound, maxBound: maxBound);
    }
    _solver.jumpTo(next);
    notifyListeners();
  }

  /// Immediately snaps the value to [newValue] without animation.
  void jumpTo(double newValue) {
    if (_isDisposed) {
      return;
    }
    _stopTicker();
    _solver.jumpTo(newValue);
    notifyListeners();
  }

  /// Applies iOS-style hyperbolic rubber-band resistance beyond [minBound]..[maxBound].
  static double applyRubberBand(
    double value, {
    required double minBound,
    required double maxBound,
    double dimension = 240.0,
    double resistance = 0.55,
  }) {
    if (value < minBound) {
      final overscroll = minBound - value;
      final damped =
          (1.0 -
              (1.0 /
                  ((overscroll * resistance / math.max(1.0, dimension)) +
                      1.0))) *
          dimension;
      return minBound - damped;
    }
    if (value > maxBound) {
      final overscroll = value - maxBound;
      final damped =
          (1.0 -
              (1.0 /
                  ((overscroll * resistance / math.max(1.0, dimension)) +
                      1.0))) *
          dimension;
      return maxBound + damped;
    }
    return value;
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }
    final dtSeconds =
        (elapsed - _lastElapsed!).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;

    final settled = _solver.step(dtSeconds);
    notifyListeners();
    if (settled) {
      _stopTicker();
    }
  }

  void _stopTicker() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastElapsed = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker.dispose();
    super.dispose();
  }
}
