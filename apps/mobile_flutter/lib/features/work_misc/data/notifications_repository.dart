/// Data-access seam for `notifications` (SCREENS.md §22).
///
/// **Contract ruling 7.11 is now superseded**: it was written when there was
/// no `notifications` endpoint anywhere in `apps/api`, and ruled that
/// [FixtureNotificationsRepository] rendering §4.4's seed data verbatim was
/// the only thing this contract could require, with a live implementation
/// left "a real design decision beyond this contract's scope." A real `GET
/// /notifications` now exists (see `apps/api/src/routes/notifications.js`
/// and `docs/04-api-spec.md`'s Notifications section) — [FixtureNotificationsRepository]
/// still renders §4.4's seed data verbatim for offline/deterministic use
/// (widget tests, no-network demo), and [LiveNotificationsRepository] wraps
/// the real endpoint directly rather than synthesizing it client-side. Kept
/// behind its own `*_mode.dart` switch like every other repository in this
/// app. See that file's own doc comment for the read-state/watermark
/// handling and the one kind-mapping edge case it has to account for.
///
/// **Return type is [WorkNotification]** (from
/// `lib/shared/fixtures/work_seed_data.dart`), reused rather than a new
/// parallel model — that class's own doc comment anticipates a live source
/// "will need its own live-mode type," but on inspection the two sources
/// need exactly the same five fields (id/kind/title/relativeTime/unread/
/// targetId) to drive this screen's rows, and [relativeTime] is already
/// documented as "display-ready ... a live-mode notifications source is
/// free to use real [DateTime]s" — i.e. a live source computing its own
/// relative-time string and handing back the same shape was anticipated,
/// just not required. Introducing a second, structurally-identical class
/// here would only be a rename.
library;

import './work_notification.dart';

abstract class NotificationsRepository {
  /// Every notification row, most-recent-first — §22's "Rows" list, one
  /// fetch, no pagination (nothing in §4.4's seed data or any live source
  /// this repository folds implies one).
  Future<List<WorkNotification>> fetchNotifications();

  /// Records that the agent has seen everything up to now — what the
  /// header's "Mark all read" action means. There is no server-side
  /// read-state mutation to call (see
  /// `notifications_watermark_repository.dart`), so the live implementation
  /// pushes the local watermark forward, which is exactly the boundary the
  /// *next* fetch's `unread` flags are computed against. The fixture
  /// implementation has no watermark at all and does nothing; the caller
  /// clears the rows it is already holding either way.
  Future<void> markAllRead();
}
