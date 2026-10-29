import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zero_motion/src/common/zero_motion_dict.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/toast/physics_toast_card.dart';
import 'package:zero_motion/src/toast/physics_toast_controller.dart';

/// Sonner-style 3D stackable toast deck that fans out on hover/tap and
/// supports velocity-aware swipe-to-dismiss physics.
class PhysicsToastDeck extends StatelessWidget {
  /// Creates a [PhysicsToastDeck].
  const PhysicsToastDeck({
    required this.controller,
    this.alignment = Alignment.bottomCenter,
    this.maxVisibleCount = 3,
    this.cardHeight = 74.0,
    this.expandedGap = 10.0,
    this.collapsedPeekOffset = 13.0,
    this.collapsedScaleStep = 0.055,
    this.profile = SpringProfile.snappy,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    this.maxWidth = 390.0,
    super.key,
  });

  /// Controller managing the notification queue.
  final PhysicsToastController controller;

  /// Screen alignment of the deck (`bottomCenter`, `topCenter`, `bottomRight`, etc.).
  final Alignment alignment;

  /// Maximum visible cards in collapsed stack mode.
  final int maxVisibleCount;

  /// Base height of each notification card.
  final double cardHeight;

  /// Vertical gap between cards when fanned out.
  final double expandedGap;

  /// Vertical peek offset between stacked cards when collapsed.
  final double collapsedPeekOffset;

  /// Scale reduction per card depth when collapsed.
  final double collapsedScaleStep;

  /// Spring profile used for stack and fan transitions.
  final SpringProfile profile;

  /// Outer screen margin around the deck.
  final EdgeInsets margin;

  /// Maximum width of the notification cards.
  final double maxWidth;

  bool get _isTopAligned => alignment.y < 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        final visibleCount = math.min(items.length, maxVisibleCount + 1);
        final isExpanded = controller.isExpanded;
        final directionSign = _isTopAligned ? 1.0 : -1.0;
        final stackHeight = isExpanded
            ? visibleCount * (cardHeight + expandedGap) + 32.0
            : cardHeight + (visibleCount * collapsedPeekOffset) + 24.0;

        return Align(
          alignment: alignment,
          child: Padding(
            padding: margin,
            child: MouseRegion(
              onEnter: (_) => controller.setExpanded(true),
              onExit: (_) => controller.setExpanded(false),
              child: SizedBox(
                width: maxWidth,
                height: math.max(cardHeight, stackHeight),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: _isTopAligned
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  children: [
                    for (var i = visibleCount - 1; i >= 0; i--)
                      PhysicsToastCardEntry(
                        key: ValueKey<String>(items[i].id),
                        item: items[i],
                        index: i,
                        maxVisible: maxVisibleCount,
                        isExpanded: isExpanded,
                        cardHeight: cardHeight,
                        expandedGap: expandedGap,
                        collapsedPeekOffset: collapsedPeekOffset,
                        collapsedScaleStep: collapsedScaleStep,
                        directionSign: directionSign,
                        profile: profile,
                        onTapCard: () => controller.setExpanded(!isExpanded),
                        onDismiss: () => controller.dismiss(items[i].id),
                      ),
                    if (items.length > 1 && isExpanded)
                      Positioned(
                        top: _isTopAligned ? stackHeight - 28 : 0,
                        bottom: _isTopAligned ? null : stackHeight - 28,
                        right: 0,
                        child: GestureDetector(
                          onTap: controller.clearAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xDD1E1E2E),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: const Color(0x33FFFFFF),
                              ),
                            ),
                            child: const Text(
                              ZeroMotionDict.toastClearAll,
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
