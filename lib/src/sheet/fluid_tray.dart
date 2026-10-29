import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zero_motion/src/common/zero_motion_dict.dart';
import 'package:zero_motion/src/physics/gesture_spring_controller.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/sheet/fluid_size_measure.dart';

/// Family / Vaul-style dynamic bottom tray that smoothly springs its height
/// at 120Hz when child content changes, the keyboard opens, or user drags across [detents].
class FluidTray extends StatefulWidget {
  /// Creates a [FluidTray].
  const FluidTray({
    required this.child,
    this.isOpen = true,
    this.onDismissed,
    this.profile = SpringProfile.fluid,
    this.detents,
    this.initialDetentIndex = 0,
    this.onDetentChanged,
    this.floatingMargin = const EdgeInsets.fromLTRB(12, 0, 12, 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.backgroundColor = const Color(0xFF161622),
    this.scrimColor = const Color(0x88000000),
    this.showDragHandle = true,
    this.enableDragDismiss = true,
    this.dismissVelocityThreshold = 550.0,
    this.progressNotifier,
    super.key,
  });

  /// Dynamic content displayed inside the tray.
  final Widget child;
  /// Whether the tray is open (`true`) or closed (`false`).
  final bool isOpen;
  /// Invoked when the tray is dismissed by dragging down or tapping the scrim.
  final VoidCallback? onDismissed;
  /// Spring physics profile.
  final SpringProfile profile;
  /// Optional fractional snap detents (e.g. `[0.4, 0.85]`).
  final List<double>? detents;
  /// Initial detent index when [detents] is non-null.
  final int initialDetentIndex;
  /// Invoked when the active detent index changes.
  final ValueChanged<int>? onDetentChanged;
  /// Outer margin for floating tray appearance.
  final EdgeInsets floatingMargin;
  /// Tray border radius.
  final BorderRadius borderRadius;
  /// Tray background color.
  final Color backgroundColor;
  /// Backdrop scrim color.
  final Color scrimColor;
  /// Whether to render the top drag handle pill.
  final bool showDragHandle;
  /// Whether downward drag dismissal is enabled.
  final bool enableDragDismiss;
  /// Downward fling velocity threshold (px/s) that triggers dismissal.
  final double dismissVelocityThreshold;
  /// Optional notifier broadcasting `0.0..1.0` openness to `ScrimScaleHost`.
  final ValueNotifier<double>? progressNotifier;

  @override
  State<FluidTray> createState() => _FluidTrayState();
}

class _FluidTrayState extends State<FluidTray> with TickerProviderStateMixin {
  late final GestureSpringController _heightSpring;
  late final GestureSpringController _offsetSpring;
  double _measuredContentHeight = 260.0;
  int _activeDetentIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeDetentIndex = widget.initialDetentIndex;
    _heightSpring = GestureSpringController(vsync: this, initialValue: _measuredContentHeight, profile: widget.profile);
    _offsetSpring = GestureSpringController(vsync: this, initialValue: widget.isOpen ? 0.0 : 500.0, profile: widget.profile)
      ..addListener(_syncProgressNotifier);
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _offsetSpring.animateTo(0.0);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant FluidTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    _heightSpring.profile = widget.profile;
    _offsetSpring.profile = widget.profile;
    if (oldWidget.isOpen != widget.isOpen) {
      _offsetSpring.animateTo(widget.isOpen ? 0.0 : _targetHeight(context) + 80.0);
    }
  }
  double _targetHeight(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final detents = widget.detents;
    if (detents != null && detents.isNotEmpty) {
      return (screenH * detents[_activeDetentIndex.clamp(0, detents.length - 1)]).clamp(120.0, screenH * 0.94);
    }
    return (_measuredContentHeight + (widget.showDragHandle ? 28.0 : 0.0)).clamp(80.0, screenH * 0.92);
  }

  void _onChildSizeMeasured(Size size) {
    if ((size.height - _measuredContentHeight).abs() > 0.5) {
      _measuredContentHeight = size.height;
      if (widget.detents == null && mounted) {
        _heightSpring.animateTo(_targetHeight(context));
      }
    }
  }

  void _syncProgressNotifier() {
    final n = widget.progressNotifier;
    if (n != null) {
      n.value = (1.0 - (_offsetSpring.value / math.max(1.0, _heightSpring.value))).clamp(0.0, 1.0);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;
    final detents = widget.detents;
    if (detents != null && detents.length > 1 && _offsetSpring.value <= 1.0) {
      final sH = MediaQuery.sizeOf(context).height;
      _heightSpring.dragBy(-dy, minBound: sH * detents.first, maxBound: sH * detents.last);
      return;
    }
    final next = _offsetSpring.value + dy;
    _offsetSpring.jumpTo(
      next < 0
          ? GestureSpringController.applyRubberBand(next, minBound: 0, maxBound: 600, dimension: 90)
          : next,
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    final vy = details.velocity.pixelsPerSecond.dy;
    final detents = widget.detents;
    if (detents != null && detents.length > 1 && _offsetSpring.value <= 4.0) {
      final ratio = _heightSpring.value / MediaQuery.sizeOf(context).height;
      var best = 0;
      for (var i = 1; i < detents.length; i++) {
        if ((detents[i] - ratio).abs() < (detents[best] - ratio).abs()) {
          best = i;
        }
      }
      if (vy < -380 && best < detents.length - 1) {
        best++;
      } else if (vy > 380 && best > 0) {
        best--;
      } else if (vy > widget.dismissVelocityThreshold && best == 0 && widget.enableDragDismiss) {
        _dismiss(velocity: vy);
        return;
      }
      _activeDetentIndex = best;
      widget.onDetentChanged?.call(best);
      _heightSpring.animateTo(_targetHeight(context), velocity: -vy);
      return;
    }
    if (widget.enableDragDismiss &&
        (_offsetSpring.value > _heightSpring.value * 0.28 || vy > widget.dismissVelocityThreshold)) {
      _dismiss(velocity: vy);
    } else {
      _offsetSpring.animateTo(0.0, velocity: vy);
    }
  }

  void _dismiss({double velocity = 0.0}) {
    _offsetSpring.animateTo(_heightSpring.value + 120.0, velocity: velocity);
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _offsetSpring..removeListener(_syncProgressNotifier)..dispose();
    _heightSpring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetH = _targetHeight(context);
    if ((_heightSpring.target - targetH).abs() > 0.5 && !_heightSpring.isAnimating) {
      _heightSpring.animateTo(targetH);
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_heightSpring, _offsetSpring]),
      builder: (context, _) {
        final h = math.max(48.0, _heightSpring.value);
        final yOffset = _offsetSpring.value;
        final openT = (1.0 - (yOffset / h)).clamp(0.0, 1.0);
        if (!widget.isOpen && openT <= 0.01 && !_offsetSpring.isAnimating) {
          return const SizedBox.shrink();
        }
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.enableDragDismiss ? _dismiss : null,
                child: Semantics(
                  label: ZeroMotionDict.trayDismissSemantics,
                  button: true,
                  child: ColoredBox(color: widget.scrimColor.withValues(alpha: widget.scrimColor.a * openT)),
                ),
              ),
            ),
            Padding(
              padding: widget.floatingMargin.add(EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)),
              child: Transform.translate(
                offset: Offset(0, yOffset),
                child: GestureDetector(
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  child: Container(
                    width: double.infinity,
                    height: h,
                    decoration: BoxDecoration(color: widget.backgroundColor, borderRadius: widget.borderRadius),
                    clipBehavior: Clip.antiAlias,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.showDragHandle)
                            Container(
                              width: 42,
                              height: 5,
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              decoration: BoxDecoration(color: const Color(0x44FFFFFF), borderRadius: BorderRadius.circular(99)),
                            ),
                          FluidChildSizeMeasure(onSizeChanged: _onChildSizeMeasured, child: widget.child),
                        ],
                      ),
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
