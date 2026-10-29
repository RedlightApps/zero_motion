import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:zero_motion/src/command/fuzzy_command_scorer.dart';
import 'package:zero_motion/src/common/zero_motion_dict.dart';

/// Spotlight modal overlay and highlighted result list rendered by `CommandPaletteHost`.
class CommandPaletteModal extends StatelessWidget {
  /// Creates a [CommandPaletteModal].
  const CommandPaletteModal({
    required this.progress,
    required this.matches,
    required this.selectedIndex,
    required this.breadcrumbs,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHint,
    required this.emptyResultText,
    required this.maxWidth,
    required this.maxHeight,
    required this.onQueryChanged,
    required this.onSelectMatch,
    required this.onHoverIndex,
    required this.onClose,
    super.key,
  });

  /// Spring opening progress (`0.0..1.0`).
  final double progress;
  /// Scored and filtered command matches.
  final List<ScoredCommandMatch> matches;
  /// Currently highlighted row index.
  final int selectedIndex;
  /// Breadcrumb stack of nested sub-menus.
  final List<ZeroCommandAction> breadcrumbs;
  /// Search input text controller.
  final TextEditingController searchController;
  /// Search input focus node.
  final FocusNode searchFocusNode;
  /// Search input hint text.
  final String searchHint;
  /// Text displayed when no results match.
  final String emptyResultText;
  /// Maximum modal width.
  final double maxWidth;
  /// Maximum modal height.
  final double maxHeight;
  /// Invoked when the search query changes.
  final ValueChanged<String> onQueryChanged;
  /// Invoked when a command row is selected.
  final ValueChanged<ScoredCommandMatch> onSelectMatch;
  /// Invoked when the pointer hovers over a row.
  final ValueChanged<int> onHoverIndex;
  /// Invoked when tapping the backdrop scrim.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0 * t, sigmaY: 8.0 * t),
              child: ColoredBox(
                color: const Color(0x88000000).withValues(alpha: 0.55 * t),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
          child: Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.92 + (0.08 * t),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: Material(
                  color: const Color(0xFF14141F),
                  borderRadius: BorderRadius.circular(24),
                  elevation: 24,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchHeader(),
                      const Divider(height: 1, color: Color(0x22FFFFFF)),
                      Flexible(child: _buildResultsList()),
                      const Divider(height: 1, color: Color(0x18FFFFFF)),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            ZeroMotionDict.commandFooterHint,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 22),
          if (breadcrumbs.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF26263A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                breadcrumbs.last.title,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onQueryChanged,
              style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 15),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          emptyResultText,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
      );
    }
    final safeIdx = selectedIndex.clamp(0, matches.length - 1);
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final isSelected = index == safeIdx;
        final indices = match.matchedTitleIndices.toSet();
        return MouseRegion(
          onEnter: (_) => onHoverIndex(index),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelectMatch(match),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF232338)
                    : const Color(0x00000000),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  match.action.leading ??
                      const Icon(
                        Icons.flash_on_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          for (var i = 0; i < match.action.title.length; i++)
                            TextSpan(
                              text: match.action.title[i],
                              style: TextStyle(
                                color: indices.contains(i)
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFFF8FAFC),
                                fontSize: 14,
                                fontWeight: indices.contains(i)
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (match.action.shortcutLabel != null)
                    Text(
                      match.action.shortcutLabel!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
