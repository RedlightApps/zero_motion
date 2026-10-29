import 'package:flutter/material.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/physics/zero_spring_builder.dart';
import 'package:zero_motion/src/toast/physics_toast_controller.dart';

/// Individual 3D spring-animated and swipe-dismissible card within `PhysicsToastDeck`.
class PhysicsToastCardEntry extends StatefulWidget {
  /// Creates a [PhysicsToastCardEntry].
  const PhysicsToastCardEntry({
    required this.item,
    required this.index,
    required this.maxVisible,
    required this.isExpanded,
    required this.cardHeight,
    required this.expandedGap,
    required this.collapsedPeekOffset,
    required this.collapsedScaleStep,
    required this.directionSign,
    required this.profile,
    required this.onTapCard,
    required this.onDismiss,
    super.key,
  });

  /// Toast notification data.
  final PhysicsToastItem item;

  /// Stack order index (`0` = frontmost card).
  final int index;

  /// Maximum visible cards in collapsed stack mode.
  final int maxVisible;

  /// Whether the deck is fanned out.
  final bool isExpanded;

  /// Base height of the card.
  final double cardHeight;

  /// Vertical spacing between cards when expanded.
  final double expandedGap;

  /// Vertical peek offset when collapsed.
  final double collapsedPeekOffset;

  /// Scale reduction step per card depth when collapsed.
  final double collapsedScaleStep;

  /// Vertical direction multiplier (`-1.0` upward, `1.0` downward).
  final double directionSign;

  /// Spring physics profile.
  final SpringProfile profile;

  /// Invoked when tapping the card.
  final VoidCallback onTapCard;

  /// Invoked when swiping the card away.
  final VoidCallback onDismiss;

  @override
  State<PhysicsToastCardEntry> createState() => _PhysicsToastCardEntryState();
}

class _PhysicsToastCardEntryState extends State<PhysicsToastCardEntry> {
  double _dragX = 0.0;

  Color _accentForType(PhysicsToastType type) {
    return switch (type) {
      PhysicsToastType.success => const Color(0xFF10B981),
      PhysicsToastType.warning => const Color(0xFFF59E0B),
      PhysicsToastType.error => const Color(0xFFEF4444),
      PhysicsToastType.loading => const Color(0xFF6366F1),
      PhysicsToastType.info => const Color(0xFF38BDF8),
    };
  }

  IconData _iconForType(PhysicsToastType type) {
    return switch (type) {
      PhysicsToastType.success => Icons.check_circle_rounded,
      PhysicsToastType.warning => Icons.warning_amber_rounded,
      PhysicsToastType.error => Icons.error_rounded,
      PhysicsToastType.loading => Icons.autorenew_rounded,
      PhysicsToastType.info => Icons.bolt_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.index;
    final targetY = widget.isExpanded
        ? idx * (widget.cardHeight + widget.expandedGap) * widget.directionSign
        : idx * widget.collapsedPeekOffset * widget.directionSign;
    final targetScale = widget.isExpanded
        ? 1.0
        : (1.0 - idx * widget.collapsedScaleStep).clamp(0.75, 1.0);
    final targetOpacity = idx >= widget.maxVisible
        ? 0.0
        : (1.0 - (_dragX.abs() / 260.0)).clamp(0.0, 1.0);

    return ZeroSpringBuilder(
      value: targetY,
      profile: widget.profile,
      builder: (context, animatedY, _, _) {
        return ZeroSpringBuilder(
          value: targetScale,
          profile: widget.profile,
          builder: (context, animatedScale, _, _) {
            return Transform.translate(
              offset: Offset(_dragX, animatedY),
              child: Transform.scale(
                scale: animatedScale,
                child: Opacity(
                  opacity: targetOpacity,
                  child: GestureDetector(
                    onTap: widget.onTapCard,
                    onHorizontalDragUpdate: (d) =>
                        setState(() => _dragX += d.delta.dx),
                    onHorizontalDragEnd: (d) {
                      final vx = d.velocity.pixelsPerSecond.dx.abs();
                      if (_dragX.abs() > 85.0 || vx > 420.0) {
                        widget.onDismiss();
                      } else {
                        setState(() => _dragX = 0.0);
                      }
                    },
                    child: _buildCardVisual(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardVisual() {
    final accent = _accentForType(widget.item.type);
    return Container(
      height: widget.cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181824),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          widget.item.leading ??
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(widget.item.type),
                  color: accent,
                  size: 20,
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.item.subtitle != null)
                  Text(
                    widget.item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.item.actionLabel != null)
            TextButton(
              onPressed: widget.item.onAction,
              child: Text(
                widget.item.actionLabel!,
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
