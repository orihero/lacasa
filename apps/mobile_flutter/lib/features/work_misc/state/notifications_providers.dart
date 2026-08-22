/// Riverpod state for `notifications` (SCREENS.md §22) — one plain fetch
/// plus the header's single mutation, "Mark all read".
///
/// An [AsyncNotifier] rather than a bare `FutureProvider`: read state is
/// the client's own (see `notifications_watermark_repository.dart` — the
/// server has no per-row read flag to `PATCH`), so clearing the dots means
/// (a) moving the watermark, which only changes what the *next* fetch
/// reports, and (b) clearing the rows this provider is already holding so
/// the screen updates now. Both live behind [NotificationsNotifier.markAllRead].
/// A retry still re-fetches via `ref.invalidate`, same as before.
///
/// Not `.autoDispose`: this is a pushed screen reachable from a bell icon
/// on more than one header, likely to be opened and left multiple times in
/// one session — same non-autoDispose reasoning
/// `connected_accounts_providers.dart` gives for its own provider. The
/// dashboard header also watches it for its unread badge dot, so a cleared
/// list has to stay cleared for that reader too.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications_repository_provider.dart';
import '../data/work_notification.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<WorkNotification>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<WorkNotification>> {
  @override
  Future<List<WorkNotification>> build() {
    return ref.read(notificationsRepositoryProvider).fetchNotifications();
  }

  /// Marks every currently-loaded row read. No-ops while the first fetch is
  /// still in flight or has failed — there is nothing on screen to clear,
  /// and moving the watermark past rows the agent never saw would hide
  /// them for good.
  Future<void> markAllRead() async {
    final rows = state.value;
    if (rows == null || rows.every((row) => !row.unread)) return;

    await ref.read(notificationsRepositoryProvider).markAllRead();

    state = AsyncData([
      for (final row in rows)
        WorkNotification(
          id: row.id,
          kind: row.kind,
          title: row.title,
          relativeTime: row.relativeTime,
          unread: false,
          targetId: row.targetId,
        ),
    ]);
  }
}
