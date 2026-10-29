import 'package:flutter/widgets.dart';

/// Action model listed and executed within `CommandPaletteHost`.
@immutable
class ZeroCommandAction {
  /// Creates a [ZeroCommandAction].
  const ZeroCommandAction({
    required this.id,
    required this.title,
    this.subtitle,
    this.category,
    this.shortcutLabel,
    this.leading,
    this.keywords = const <String>[],
    this.children = const <ZeroCommandAction>[],
    this.onSelected,
  });

  /// Unique identifier of the command.
  final String id;

  /// Primary visible title of the command.
  final String title;

  /// Optional secondary description text.
  final String? subtitle;

  /// Optional category or section group label.
  final String? category;

  /// Optional right-aligned keyboard shortcut badge (e.g. `'⌘P'`, `'⇧⌘D'`).
  final String? shortcutLabel;

  /// Optional custom leading icon or widget.
  final Widget? leading;

  /// Additional search keywords that boost fuzzy matching.
  final List<String> keywords;

  /// Nested sub-menu commands opened when this action is selected.
  final List<ZeroCommandAction> children;

  /// Callback invoked when the leaf action is executed.
  final VoidCallback? onSelected;

  /// Whether this action opens a nested sub-command menu.
  bool get hasChildren => children.isNotEmpty;
}

/// Scored fuzzy search result containing matched character indices for highlighting.
@immutable
class ScoredCommandMatch {
  /// Creates a [ScoredCommandMatch].
  const ScoredCommandMatch({
    required this.action,
    required this.score,
    required this.matchedTitleIndices,
  });

  /// Matched command action.
  final ZeroCommandAction action;

  /// Relevance score (higher means better match).
  final int score;

  /// Character indices inside [ZeroCommandAction.title] that matched the query.
  final List<int> matchedTitleIndices;
}

/// Zero-dependency $O(N)$ subsequence, word-boundary, and consecutive-character
/// fuzzy search scorer.
abstract final class FuzzyCommandScorer {
  /// Filters and sorts [actions] against [query] in descending score order.
  static List<ScoredCommandMatch> filterAndSort(
    List<ZeroCommandAction> actions,
    String query,
  ) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [
        for (final action in actions)
          ScoredCommandMatch(
            action: action,
            score: 0,
            matchedTitleIndices: const <int>[],
          ),
      ];
    }

    final lowerQuery = trimmed.toLowerCase();
    final results = <ScoredCommandMatch>[];

    for (final action in actions) {
      final titleMatch = scoreText(action.title, lowerQuery);
      var bestScore = titleMatch?.$1 ?? -1;
      final titleIndices = titleMatch?.$2 ?? const <int>[];

      if (action.subtitle != null) {
        final subScore = scoreText(action.subtitle!, lowerQuery)?.$1 ?? -1;
        if (subScore > 0 && subScore + 10 > bestScore) {
          bestScore = subScore + 10;
        }
      }
      if (action.category != null) {
        final catScore = scoreText(action.category!, lowerQuery)?.$1 ?? -1;
        if (catScore > 0 && catScore + 5 > bestScore) {
          bestScore = catScore + 5;
        }
      }
      for (final kw in action.keywords) {
        final kwScore = scoreText(kw, lowerQuery)?.$1 ?? -1;
        if (kwScore > 0 && kwScore + 15 > bestScore) {
          bestScore = kwScore + 15;
        }
      }

      if (bestScore > 0) {
        results.add(
          ScoredCommandMatch(
            action: action,
            score: bestScore,
            matchedTitleIndices: titleIndices,
          ),
        );
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Scores a single [candidate] string against [lowerQuery] and returns
  /// `(totalScore, matchedCharacterIndices)`, or `null` if no subsequence match exists.
  static (int, List<int>)? scoreText(String candidate, String lowerQuery) {
    if (lowerQuery.isEmpty) {
      return (1, const <int>[]);
    }
    final lowerCandidate = candidate.toLowerCase();
    final indices = <int>[];
    var score = 0;
    var queryIdx = 0;
    var prevMatchIdx = -2;

    for (var i = 0;
        i < lowerCandidate.length && queryIdx < lowerQuery.length;
        i++) {
      if (lowerCandidate.codeUnitAt(i) == lowerQuery.codeUnitAt(queryIdx)) {
        indices.add(i);
        score += 12;
        if (i == 0) {
          score += 35;
        }
        if (i > 0) {
          final prevChar = lowerCandidate.codeUnitAt(i - 1);
          if (prevChar == 32 || prevChar == 45 || prevChar == 95) {
            score += 28;
          }
        }
        if (prevMatchIdx == i - 1) {
          score += 24;
        }
        prevMatchIdx = i;
        queryIdx++;
      }
    }

    if (queryIdx < lowerQuery.length) {
      return null;
    }
    score += (40 - (candidate.length - lowerQuery.length)).clamp(0, 40);
    return (score, indices);
  }
}
