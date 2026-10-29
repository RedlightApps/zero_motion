import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Zero-overhead layout reporter that measures its [child] size during layout
/// and invokes [onSizeChanged] post-frame whenever the size changes.
class FluidChildSizeMeasure extends SingleChildRenderObjectWidget {
  /// Creates a [FluidChildSizeMeasure].
  const FluidChildSizeMeasure({
    required this.onSizeChanged,
    required super.child,
    super.key,
  });

  /// Callback invoked when the measured child size changes.
  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderFluidChildSizeMeasure(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderFluidChildSizeMeasure renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

/// Custom [RenderProxyBox] backing [FluidChildSizeMeasure].
class RenderFluidChildSizeMeasure extends RenderProxyBox {
  /// Creates a [RenderFluidChildSizeMeasure].
  RenderFluidChildSizeMeasure(this.onSizeChanged);

  /// Size change callback.
  ValueChanged<Size> onSizeChanged;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && newSize != _lastSize) {
      _lastSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSizeChanged(newSize);
      });
    }
  }
}
