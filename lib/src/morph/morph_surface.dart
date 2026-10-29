import 'package:flutter/material.dart';
import 'package:zero_motion/src/morph/morph_overlay_view.dart';
import 'package:zero_motion/src/physics/gesture_spring_controller.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';

/// Controller for programmatically expanding or collapsing a [MorphSurface].
class MorphSurfaceController extends ChangeNotifier {
  bool _isExpanded = false;

  /// Whether the surface is currently expanded.
  bool get isExpanded => _isExpanded;

  /// Expands the surface using spring physics.
  void expand() {
    if (!_isExpanded) {
      _isExpanded = true;
      notifyListeners();
    }
  }

  /// Collapses the surface back into its origin slot.
  void collapse() {
    if (_isExpanded) {
      _isExpanded = false;
      notifyListeners();
    }
  }

  /// Toggles between expanded and collapsed states.
  void toggle() => _isExpanded ? collapse() : expand();
}

/// In-place geometric morphing widget that transforms a button, card, or pill
/// into an interactive modal surface using 120Hz spring physics without pushing a new `Route`.
class MorphSurface extends StatefulWidget {
  /// Creates a [MorphSurface].
  const MorphSurface({
    required this.closedBuilder,
    required this.expandedBuilder,
    this.controller,
    this.profile = SpringProfile.fluid,
    this.closedBorderRadius = const BorderRadius.all(Radius.circular(18)),
    this.expandedBorderRadius = const BorderRadius.all(Radius.circular(28)),
    this.closedColor = const Color(0xFF1E1E2A),
    this.expandedColor = const Color(0xFF161622),
    this.scrimColor = const Color(0x99000000),
    this.maxBlurSigma = 12.0,
    this.expandedConstraints = const BoxConstraints(
      maxWidth: 420,
      maxHeight: 520,
    ),
    this.expandedMargin = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 48,
    ),
    this.dismissDragThreshold = 90.0,
    this.onStateChanged,
    super.key,
  });

  /// Builder for the collapsed trigger widget (receives `open` callback).
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;

  /// Builder for the expanded surface content (receives `close` callback).
  final Widget Function(BuildContext context, VoidCallback close)
  expandedBuilder;

  /// Optional external controller.
  final MorphSurfaceController? controller;

  /// Spring physics profile used for morphing transitions.
  final SpringProfile profile;

  /// Border radius when collapsed.
  final BorderRadius closedBorderRadius;

  /// Border radius when expanded.
  final BorderRadius expandedBorderRadius;

  /// Background color when collapsed.
  final Color closedColor;

  /// Background color when expanded.
  final Color expandedColor;

  /// Backdrop scrim color.
  final Color scrimColor;

  /// Maximum Gaussian blur sigma applied to the backdrop when expanded.
  final double maxBlurSigma;

  /// Maximum size constraints of the expanded surface.
  final BoxConstraints expandedConstraints;

  /// Screen margin around the expanded surface.
  final EdgeInsets expandedMargin;

  /// Drag distance threshold (in pixels) that triggers dismissal upon release.
  final double dismissDragThreshold;

  /// Optional callback invoked when the expanded state changes.
  final ValueChanged<bool>? onStateChanged;

  @override
  State<MorphSurface> createState() => _MorphSurfaceState();
}

class _MorphSurfaceState extends State<MorphSurface>
    with SingleTickerProviderStateMixin {
  final GlobalKey _originKey = GlobalKey();
  final OverlayPortalController _portalController = OverlayPortalController();
  late final GestureSpringController _progressSpring;
  Rect _originRect = const Rect.fromLTWH(0, 0, 120, 48);
  Offset _dragOffset = Offset.zero;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _progressSpring = GestureSpringController(
      vsync: this,
      initialValue: 0.0,
      profile: widget.profile,
    )..addListener(_onSpringUpdate);
    widget.controller?.addListener(_onExternalControllerChanged);
  }

  @override
  void didUpdateWidget(covariant MorphSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onExternalControllerChanged);
      widget.controller?.addListener(_onExternalControllerChanged);
    }
    _progressSpring.profile = widget.profile;
  }

  void _onExternalControllerChanged() {
    final targetExpanded = widget.controller?.isExpanded ?? false;
    if (targetExpanded != _isExpanded) {
      targetExpanded ? open() : close();
    }
  }

  void _captureOriginRect() {
    final box = _originKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _originRect = box.localToGlobal(Offset.zero) & box.size;
    }
  }

  /// Expands the surface using spring physics.
  void open() {
    _captureOriginRect();
    _dragOffset = Offset.zero;
    _isExpanded = true;
    widget.controller?.expand();
    widget.onStateChanged?.call(true);
    if (!_portalController.isShowing) {
      _portalController.show();
    }
    _progressSpring.animateTo(1.0);
    setState(() {});
  }

  /// Collapses the surface back to its origin slot preserving velocity.
  void close({double? velocity}) {
    _captureOriginRect();
    _isExpanded = false;
    widget.controller?.collapse();
    widget.onStateChanged?.call(false);
    _progressSpring.animateTo(0.0, velocity: velocity);
    setState(() {});
  }

  void _onSpringUpdate() {
    if (!_isExpanded &&
        !_progressSpring.isAnimating &&
        _progressSpring.value <= 0.01 &&
        _portalController.isShowing) {
      _dragOffset = Offset.zero;
      _portalController.hide();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isExpanded) {
      setState(() {
        _dragOffset += details.delta * 0.65;
        _progressSpring.jumpTo(
          (1.0 - (_dragOffset.distance / 420.0)).clamp(0.35, 1.0),
        );
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final speed = details.velocity.pixelsPerSecond.distance;
    if (_dragOffset.distance >= widget.dismissDragThreshold || speed > 650.0) {
      _dragOffset = Offset.zero;
      close(velocity: -(speed / 420.0).clamp(0.5, 6.0));
    } else {
      setState(() => _dragOffset = Offset.zero);
      _progressSpring.animateTo(1.0);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onExternalControllerChanged);
    _progressSpring
      ..removeListener(_onSpringUpdate)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (overlayCtx) => MorphOverlayView(
        progressListenable: _progressSpring,
        originRect: _originRect,
        dragOffset: _dragOffset,
        closedBorderRadius: widget.closedBorderRadius,
        expandedBorderRadius: widget.expandedBorderRadius,
        closedColor: widget.closedColor,
        expandedColor: widget.expandedColor,
        scrimColor: widget.scrimColor,
        maxBlurSigma: widget.maxBlurSigma,
        expandedConstraints: widget.expandedConstraints,
        expandedMargin: widget.expandedMargin,
        onTapScrim: close,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        closedChild: widget.closedBuilder(overlayCtx, open),
        expandedChild: widget.expandedBuilder(overlayCtx, close),
      ),
      child: Opacity(
        key: _originKey,
        opacity: _portalController.isShowing ? 0.0 : 1.0,
        child: widget.closedBuilder(context, open),
      ),
    );
  }
}
