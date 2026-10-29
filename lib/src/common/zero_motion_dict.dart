/// Default UI strings and accessibility labels for the Zero Motion package.
///
/// Centralizes all user-facing and accessibility text constants so widgets
/// remain free of hard-coded string literals and can be localized easily.
abstract final class ZeroMotionDict {
  /// Default search hint for `CommandPaletteHost`.
  static const String commandSearchHint = 'Type a command or search...';

  /// Default message shown when no commands match the query.
  static const String commandNoResults = 'No matching commands found.';

  /// Keyboard navigation hint shown in the command palette footer.
  static const String commandFooterHint =
      '↑↓ Navigate • Enter Select • Esc Close';

  /// Root breadcrumb label for the command palette.
  static const String commandRootLabel = 'Commands';

  /// Label for the button that clears all active notifications in `PhysicsToastDeck`.
  static const String toastClearAll = 'Clear All';

  /// Label for collapsing the expanded toast deck.
  static const String toastCollapse = 'Collapse';

  /// Suffix for hidden toast count indicator.
  static const String toastMoreSuffix = 'more notifications';

  /// Accessibility label for dismissing `FluidTray`.
  static const String trayDismissSemantics = 'Dismiss tray';

  /// Accessibility label for collapsing `MorphSurface`.
  static const String morphDismissSemantics = 'Collapse surface';
}
