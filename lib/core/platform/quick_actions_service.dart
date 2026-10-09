import 'package:quick_actions/quick_actions.dart';

abstract class QuickActionsService {
  Future<void> initialize(void Function(String type) handler);
}

class MobileQuickActionsService implements QuickActionsService {
  final QuickActions _quickActions = const QuickActions();

  @override
  Future<void> initialize(void Function(String type) handler) async {
    _quickActions.initialize(handler);

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_search',
        localizedTitle: 'Ҷустуҷӯ',
        icon: 'ic_shortcut_search',
      ),
      const ShortcutItem(
        type: 'action_last_read',
        localizedTitle: 'Охирин боздид',
        icon: 'ic_shortcut_last_read',
      ),
      const ShortcutItem(
        type: 'action_delete_feedback',
        localizedTitle: 'Чаро удалит мекунед?',
        icon: 'ic_shortcut_feedback',
      ),
    ]);
  }
}

class NoOpQuickActionsService implements QuickActionsService {
  @override
  Future<void> initialize(void Function(String type) handler) async {
    // No-op on desktop/unsupported platforms
  }
}
