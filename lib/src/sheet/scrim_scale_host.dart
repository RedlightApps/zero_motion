import 'dart:ui' show ImageFilter, lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Vaul / iOS-style background wrapper that scales down (`0.93x`), rounds the
/// top corners, and blurs the primary screen while a `FluidTray` is open.
class ScrimScaleHost extends StatelessWidget {
  /// Creates a [ScrimScaleHost].
  const ScrimScaleHost({
    required this.progressListenable,
    required this.child,
    this.minScale = 0.93,
    this.maxBorderRadius = 26.0,
    this.maxTopOffset = 14.0,
    this.maxBlurSigma = 6.0,
    this.backgroundColor = const Color(0xFF000000),
    super.key,
  });

  /// Spring progress listenable ranging from `0.0` (closed) to `1.0` (fully open).
  final ValueListenable<double> progressListenable;

  /// Primary background application/page subtree.
  final Widget child;

  /// Minimum scale factor applied to [child] at `progress == 1.0`.
  final double minScale;

  /// Maximum corner radius applied to [child] at `progress == 1.0`.
  final double maxBorderRadius;

  /// Maximum downward translation offset (in pixels) at `progress == 1.0`.
  final double maxTopOffset;

  /// Optional Gaussian blur sigma applied to [child] at `progress == 1.0`.
  final double maxBlurSigma;

  /// Void background color visible behind the scaled [child].
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: ValueListenableBuilder<double>(
        valueListenable: progressListenable,
        child: child,
        builder: (context, rawProgress, cachedChild) {
          final t = rawProgress.clamp(0.0, 1.0);
          if (t <= 0.001) {
            return cachedChild!;
          }
          final scale = lerpDouble(1.0, minScale, t) ?? 1.0;
          final radius = lerpDouble(0.0, maxBorderRadius, t) ?? 0.0;
          final translateY = lerpDouble(0.0, maxTopOffset, t) ?? 0.0;
          final blur = lerpDouble(0.0, maxBlurSigma, t) ?? 0.0;

          Widget transformed = Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: cachedChild,
              ),
            ),
          );

          if (blur > 0.1) {
            transformed = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: transformed,
            );
          }

          return RepaintBoundary(child: transformed);
        },
      ),
    );
  }
}
