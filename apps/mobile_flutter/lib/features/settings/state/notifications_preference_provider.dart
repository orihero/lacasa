/// [notificationsPreferenceProvider] holds the "Notifications" toggle's
/// on/off state — same [AsyncNotifier]-seeded-from-storage shape as
/// `language/state/language_provider.dart`'s [LanguageNotifier]. See
/// `data/notifications_preference_repository.dart`'s doc comment for what
/// this preference does and does not control.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications_preference_repository_provider.dart';

class NotificationsPreferenceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.read(notificationsPreferenceRepositoryProvider).load();
  }

  /// Updates state optimistically and persists in the background, mirroring
  /// `LanguageNotifier.select`'s "update state, then await the write" order.
  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    await ref.read(notificationsPreferenceRepositoryProvider).save(enabled);
  }
}

final notificationsPreferenceProvider =
    AsyncNotifierProvider<NotificationsPreferenceNotifier, bool>(
      NotificationsPreferenceNotifier.new,
    );
