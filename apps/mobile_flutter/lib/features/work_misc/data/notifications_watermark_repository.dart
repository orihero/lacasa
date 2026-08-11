/// Data-access seam for the `notifications` (SCREENS.md §22) read-state
/// watermark — the wall-clock instant the signed-in agent last opened this
/// screen.
///
/// **Why this exists client-side at all.** `GET /notifications` has no
/// server-side read state (`notificationService.js`'s header comment,
/// section "Read state: no persistence, by design" — no `Notification`
/// table, no per-user watermark column, deliberately out of scope for that
/// slice). Instead the server computes `unread = createdAt > since` against
/// whatever `since` the *caller* supplies on each request, and defaults
/// every row to `unread: true` when `since` is omitted. That makes the
/// watermark the client's responsibility: something has to remember "the
/// last time this agent looked" across app restarts, or every single visit
/// to this screen would show everything as unread again. This repository is
/// that memory — see `secure_notifications_watermark_repository.dart` for
/// the storage mechanism.
///
/// **If the server ever grows a real watermark** (`notificationService.js`'s
/// comment names the shape it would take: a single
/// `User.notificationsReadAt DateTime?` column), this repository becomes
/// redundant with server state rather than the only copy of it — at that
/// point [LiveNotificationsRepository] would read/write through the API
/// instead of local storage, and this interface's two methods would keep
/// the exact same signatures (a "last seen" instant in, a "last seen"
/// instant out) since the contract a caller needs is identical either way.
///
/// Not shared with fixture mode: `FixtureNotificationsRepository` renders
/// SCREENS.md §4.4's seed rows verbatim, each with its own hardcoded
/// [WorkNotificationFixture.unread] value — there is no `since` to compute
/// against and nothing this watermark could change about what fixture mode
/// shows.
library;

abstract class NotificationsWatermarkRepository {
  /// The wall-clock instant this agent last opened `notifications`, or
  /// `null` if they never have (first-ever open on this device/session, or
  /// storage has nothing saved) — `null` is what tells the caller to omit
  /// `since` entirely rather than send some fabricated boundary, so every
  /// row honestly comes back unread on that very first visit.
  Future<DateTime?> load();

  /// Persists [watermark] as "the last time this agent looked" — call this
  /// once a fetch against the *previous* watermark has succeeded, never
  /// before, so a failed request doesn't silently forget how far the agent
  /// had actually read.
  Future<void> save(DateTime watermark);
}
