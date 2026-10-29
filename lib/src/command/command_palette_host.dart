import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zero_motion/src/command/command_palette_modal.dart';
import 'package:zero_motion/src/command/fuzzy_command_scorer.dart';
import 'package:zero_motion/src/common/zero_motion_dict.dart';
import 'package:zero_motion/src/physics/spring_profile.dart';
import 'package:zero_motion/src/physics/zero_spring_builder.dart';

/// Reactive controller for programmatically opening or closing a [CommandPaletteHost].
class CommandPaletteController extends ChangeNotifier {
  bool _isOpen = false;

  /// Whether the command palette is currently open.
  bool get isOpen => _isOpen;

  /// Opens the command palette using spring physics.
  void open() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  /// Closes the command palette.
  void close() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// Toggles the open state of the command palette.
  void toggle() => _isOpen ? close() : open();
}

/// Spotlight / `Cmd+K` / `Ctrl+K` command palette host featuring $O(N)$ fuzzy
/// search scoring, nested breadcrumb sub-menus, and 120Hz spring transitions.
class CommandPaletteHost extends StatefulWidget {
  /// Creates a [CommandPaletteHost].
  const CommandPaletteHost({
    required this.actions,
    required this.child,
    this.controller,
    this.profile = SpringProfile.snappy,
    this.searchHint = ZeroMotionDict.commandSearchHint,
    this.emptyResultText = ZeroMotionDict.commandNoResults,
    this.enableKeyboardShortcut = true,
    this.maxWidth = 540.0,
    this.maxHeight = 440.0,
    super.key,
  });

  /// Root searchable and executable command actions.
  final List<ZeroCommandAction> actions;

  /// Primary application or page subtree wrapped by the command palette.
  final Widget child;

  /// Optional external palette controller.
  final CommandPaletteController? controller;

  /// Spring profile used for opening and closing transitions.
  final SpringProfile profile;

  /// Search input hint text.
  final String searchHint;

  /// Text shown when no commands match the query.
  final String emptyResultText;

  /// Whether `Cmd+K` and `Ctrl+K` keyboard shortcuts are automatically bound.
  final bool enableKeyboardShortcut;

  /// Maximum width of the palette modal.
  final double maxWidth;

  /// Maximum height of the palette modal.
  final double maxHeight;

  @override
  State<CommandPaletteHost> createState() => _CommandPaletteHostState();
}

class _CommandPaletteHostState extends State<CommandPaletteHost> {
  late final CommandPaletteController _internalController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<ZeroCommandAction> _breadcrumbStack = <ZeroCommandAction>[];
  int _selectedIndex = 0;

  CommandPaletteController get _effectiveController =>
      widget.controller ?? _internalController;

  List<ZeroCommandAction> get _activeSourceActions => _breadcrumbStack.isEmpty
      ? widget.actions
      : _breadcrumbStack.last.children;

  @override
  void initState() {
    super.initState();
    _internalController = CommandPaletteController();
    _effectiveController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CommandPaletteHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController).removeListener(
        _onControllerChanged,
      );
      _effectiveController.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (_effectiveController.isOpen) {
      _searchController.clear();
      _breadcrumbStack.clear();
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchFocusNode.unfocus();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _executeMatch(ScoredCommandMatch match) {
    if (match.action.hasChildren) {
      setState(() {
        _breadcrumbStack.add(match.action);
        _searchController.clear();
        _selectedIndex = 0;
      });
      return;
    }
    _effectiveController.close();
    match.action.onSelected?.call();
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    List<ScoredCommandMatch> matches,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown && matches.isNotEmpty) {
      setState(() => _selectedIndex = (_selectedIndex + 1) % matches.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp && matches.isNotEmpty) {
      setState(
        () => _selectedIndex =
            (_selectedIndex - 1 + matches.length) % matches.length,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && matches.isNotEmpty) {
      _executeMatch(matches[_selectedIndex.clamp(0, matches.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace &&
        _searchController.text.isEmpty &&
        _breadcrumbStack.isNotEmpty) {
      setState(() {
        _breadcrumbStack.removeLast();
        _selectedIndex = 0;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _effectiveController.close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _internalController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _effectiveController.isOpen;
    final matches = FuzzyCommandScorer.filterAndSort(
      _activeSourceActions,
      _searchController.text,
    );
    final content = Stack(
      children: [
        widget.child,
        ZeroSpringBuilder(
          value: isOpen ? 1.0 : 0.0,
          profile: widget.profile,
          builder: (context, rawT, _, _) {
            final t = rawT.clamp(0.0, 1.0);
            if (!isOpen && t <= 0.01) {
              return const SizedBox.shrink();
            }
            return Focus(
              onKeyEvent: (n, e) => _handleKeyEvent(n, e, matches),
              child: CommandPaletteModal(
                progress: t,
                matches: matches,
                selectedIndex: _selectedIndex,
                breadcrumbs: _breadcrumbStack,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchHint: widget.searchHint,
                emptyResultText: widget.emptyResultText,
                maxWidth: widget.maxWidth,
                maxHeight: widget.maxHeight,
                onQueryChanged: (_) => setState(() => _selectedIndex = 0),
                onSelectMatch: _executeMatch,
                onHoverIndex: (idx) => setState(() => _selectedIndex = idx),
                onClose: _effectiveController.close,
              ),
            );
          },
        ),
      ],
    );
    if (!widget.enableKeyboardShortcut) {
      return content;
    }
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _effectiveController.toggle,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _effectiveController.toggle,
      },
      child: Focus(autofocus: true, child: content),
    );
  }
}
