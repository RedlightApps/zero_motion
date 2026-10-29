import 'dart:ui' show ImageFilter, lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zero_motion/src/common/zero_motion_dict.dart';

/// Overlay view rendered by `MorphSurface` via `OverlayPortal`, handling
/// Gaussian backdrop blur and continuous `Rect`/`BorderRadius` interpolation.
class MorphOverlayView extends StatelessWidget {
  /// Creates a [MorphOverlayView].
  const MorphOverlayView({
    required this.progressListenable,
    required this.originRect,
    required this.dragOffset,
    required this.closedBorderRadius,
    required this.expandedBorderRadius,
    required this.closedColor,
    required this.expandedColor,
    required this.scrimColor,
    required this.maxBlurSigma,
    required this.expandedConstraints,
    required this.expandedMargin,
    required this.onTapScrim,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.closedChild,
    required this.expandedChild,
    super.key,
  });

  /// Spring progress listenable (`0.0..1.0`).
  final ValueListenable<double> progressListenable;

  /// Captured global bounding box of the origin widget.
  final Rect originRect;

  /// Active drag displacement offset.
  final Offset dragOffset;

  /// Border radius when collapsed.
  final BorderRadius closedBorderRadius;

  /// Border radius when expanded.
  final BorderRadius expandedBorderRadius;

  /// Surface color when collapsed.
  final Color closedColor;

  /// Surface color when expanded.
  final Color expandedColor;

  /// Backdrop scrim color.
  final Color scrimColor;

  /// Maximum backdrop Gaussian blur sigma.
  final double maxBlurSigma;

  /// Size constraints of the expanded card.
  final BoxConstraints expandedConstraints;

  /// Outer margin around the expanded card.
  final EdgeInsets expandedMargin;

  /// Invoked when tapping the backdrop scrim.
  final VoidCallback onTapScrim;

  /// Invoked when dragging the expanded card.
  final GestureDragUpdateCallback onPanUpdate;

  /// Invoked when releasing the expanded card.
  final GestureDragEndCallback onPanEnd;

  /// Collapsed widget tree.
  final Widget closedChild;

  /// Expanded widget tree.
  final Widget expandedChild;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final availW = (screen.width - expandedMargin.horizontal).clamp(
      160.0,
      expandedConstraints.maxWidth,
    );
    final availH =
        (screen.height - media.padding.vertical - expandedMargin.vertical)
            .clamp(160.0, expandedConstraints.maxHeight);
    final targetRect = Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height / 2) + dragOffset,
      width: availW,
      height: availH,
    );

    return ValueListenableBuilder<double>(
      valueListenable: progressListenable,
      builder: (context, rawT, _) {
        final t = rawT.clamp(0.0, 1.15);
        final clampedT = rawT.clamp(0.0, 1.0);
        final rect = Rect.lerp(originRect, targetRect, t) ?? targetRect;
        final radius =
            BorderRadius.lerp(
              closedBorderRadius,
              expandedBorderRadius,
              clampedT,
            ) ??
            expandedBorderRadius;
        final bgColor =
            Color.lerp(closedColor, expandedColor, clampedT) ?? expandedColor;
        final blur = lerpDouble(0.0, maxBlurSigma, clampedT) ?? 0.0;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapScrim,
                child: Semantics(
                  label: ZeroMotionDict.morphDismissSemantics,
                  button: true,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: ColoredBox(
                      color: scrimColor.withValues(
                        alpha: scrimColor.a * clampedT,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: GestureDetector(
                onPanUpdate: onPanUpdate,
                onPanEnd: onPanEnd,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x66000000).withValues(
                          alpha: 0.4 * clampedT,
                        ),
                        blurRadius: 28.0 * clampedT,
                        offset: Offset(0, 14.0 * clampedT),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          ignoring: clampedT > 0.35,
                          child: Opacity(
                            opacity: (1.0 - clampedT * 2.2).clamp(0.0, 1.0),
                            child: closedChild,
                          ),
                        ),
                        IgnorePointer(
                          ignoring: clampedT <= 0.35,
                          child: Opacity(
                            opacity: ((clampedT - 0.25) / 0.75).clamp(0.0, 1.0),
                            child: expandedChild,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
