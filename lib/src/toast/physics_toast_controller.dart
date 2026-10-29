import 'dart:async';
import 'package:flutter/widgets.dart';

/// Visual severity and accent type for a [PhysicsToastItem].
enum PhysicsToastType {
  /// Informational notification.
  info,

  /// Successful operation notification.
  success,

  /// Warning notification.
  warning,

  /// Error or failure notification.
  error,

  /// In-progress asynchronous operation notification.
  loading,
}

/// Immutable data model representing a single notification in `PhysicsToastDeck`.
@immutable
class PhysicsToastItem {
  /// Creates a [PhysicsToastItem].
  const PhysicsToastItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.type = PhysicsToastType.info,
    this.duration = const Duration(seconds: 4),
    this.actionLabel,
    this.onAction,
    this.leading,
  });

  /// Unique identifier of the toast.
  final String id;

  /// Primary title text.
  final String title;

  /// Optional secondary description text.
  final String? subtitle;

  /// Visual accent type.
  final PhysicsToastType type;

  /// Auto-dismiss duration (`Duration.zero` disables auto-dismiss).
  final Duration duration;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback invoked when the action button is pressed.
  final VoidCallback? onAction;

  /// Optional custom leading widget.
  final Widget? leading;
}

/// Reactive controller managing a Sonner-style 3D notification stack (`PhysicsToastDeck`).
///
/// Handles insertion ([show]), dismissal ([dismiss]), and automatic timer
/// pausing/resuming when the user expands the deck ([setExpanded]).
class PhysicsToastController extends ChangeNotifier {
  /// Creates a [PhysicsToastController] with [maxStackSize].
  PhysicsToastController({this.maxStackSize = 6});

  /// Maximum number of active toasts retained in memory.
  final int maxStackSize;

  final List<PhysicsToastItem> _items = <PhysicsToastItem>[];
  final Map<String, Timer> _timers = <String, Timer>{};
  bool _isExpanded = false;
  int _idCounter = 0;

  /// Active toast items ordered from newest (`0`) to oldest.
  List<PhysicsToastItem> get items => List<PhysicsToastItem>.unmodifiable(_items);

  /// Whether the toast deck is currently fanned out (expanded).
  bool get isExpanded => _isExpanded;

  /// Expands or collapses the 3D toast deck.
  ///
  /// Expanding the deck pauses all auto-dismiss timers so the user can inspect notifications.
  void setExpanded(bool expanded) {
    if (_isExpanded == expanded) {
      return;
    }
    _isExpanded = expanded;
    if (_isExpanded) {
      _pauseAllTimers();
    } else {
      _resumeAllTimers();
    }
    notifyListeners();
  }

  /// Pushes a new toast notification to the front of the 3D deck (`index 0`).
  String show({
    required String title,
    String? subtitle,
    PhysicsToastType type = PhysicsToastType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    Widget? leading,
    String? customId,
  }) {
    final id = customId ?? 'toast_${++_idCounter}';
    final item = PhysicsToastItem(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      leading: leading,
    );

    _timers.remove(id)?.cancel();
    _items.removeWhere((e) => e.id == id);
    _items.insert(0, item);

    if (_items.length > maxStackSize) {
      final removed = _items.removeLast();
      _timers.remove(removed.id)?.cancel();
    }

    if (!_isExpanded && duration > Duration.zero) {
      _startTimer(item);
    }
    notifyListeners();
    return id;
  }

  /// Dismisses the toast matching [id].
  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    final before = _items.length;
    _items.removeWhere((e) => e.id == id);
    if (_items.isEmpty) {
      _isExpanded = false;
    }
    if (_items.length != before) {
      notifyListeners();
    }
  }

  /// Clears all active notifications.
  void clearAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _items.clear();
    _isExpanded = false;
    notifyListeners();
  }

  void _startTimer(PhysicsToastItem item) {
    if (item.duration <= Duration.zero) {
      return;
    }
    _timers[item.id]?.cancel();
    _timers[item.id] = Timer(item.duration, () => dismiss(item.id));
  }

  void _pauseAllTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _resumeAllTimers() {
    for (final item in _items) {
      _startTimer(item);
    }
  }

  @override
  void dispose() {
    _pauseAllTimers();
    super.dispose();
  }
}
