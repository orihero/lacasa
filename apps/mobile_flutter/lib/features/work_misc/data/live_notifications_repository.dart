/// A real, network-backed [NotificationsRepository] over `GET
/// /notifications` — see `notifications_repository.dart`'s doc comment for
/// how this fits the fixture/live split, `lib/api/models/notification.dart`
/// for the wire shape, and `apps/api/src/services/notificationService.js`'s
/// header comment for the server's own derivation (leads/ad-lifecycle/
/// coworker/publish activity, no `notifications` table).
///
/// **This replaces an earlier client-side synthesis.** Before this endpoint
/// existed, this file built the same feed itself out of `GET /leads` +
/// `GET /my/ads` + `GET /statistics/coworkers` + `GET /coworkers`, and could
/// only honestly cover 3 of SCREENS.md §4.4's 4 notification kinds — it
/// dropped [WorkNotificationKind.publish] entirely because
/// `PublishResource.statusForAds` deliberately omits `lastAttemptAt`, the
/// one field that would have let it be ranked against everything else in
/// the feed. The server-side implementation reads `AdPublication
/// .lastAttemptAt`/`updatedAt` directly and has no such gap (see
/// `notificationService.js`'s "Publish outcomes" section), so all 4 kinds
/// are covered now. That old per-source synthesis is deleted rather than
/// kept behind a flag — duplicating what the server now does correctly
/// would just be a second, worse implementation to keep in sync.
///
/// **Read state (`unread`) is still the client's problem** — the server has
/// no persisted watermark (see `notifications_watermark_repository.dart`'s
/// doc comment) and computes `unread` purely against whatever `since` this
/// repository sends. So each fetch here: (1) loads the watermark saved from
/// the *previous* visit, (2) sends it as `since` (or omits it entirely on a
/// first-ever visit, so every row honestly comes back unread), and (3), only
/// once the request has actually succeeded, saves "now" as the new
/// watermark for the *next* visit. A failed fetch leaves the old watermark
/// untouched — nothing was actually seen.
///
/// **An unrecognized [NotificationKind.unknown] row is dropped, not
/// rendered.** [WorkNotification] — the shape this whole screen is
/// built around — has exactly 4 [WorkNotificationKind] values with no
/// "other" case and no icon for one (`NotificationRow._iconFor` is an
/// exhaustive switch); a kind this build doesn't know about is the server
/// getting ahead of this client, not something safe to fake an icon for.
/// Same "skip rather than fabricate" call the old synthesis already made
/// for a lead/ad/coworker row whose parent had been deleted.
library;

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import 'notifications_repository.dart';
import 'notifications_watermark_repository.dart';
import './work_notification.dart';

class LiveNotificationsRepository implements NotificationsRepository {
  const LiveNotificationsRepository(this._api, this._watermark, this._l10n);

  final LaCasaApi _api;
  final NotificationsWatermarkRepository _watermark;

  /// Threaded in at construction (see `notifications_repository_provider
  /// .dart`) rather than taking a `BuildContext` — this repository is a
  /// plain, widget-free data seam (its own [NotificationsRepository]
  /// abstraction has no `BuildContext` anywhere in its contract), so the
  /// caller resolves [AppLocalizations] once from the ambient `MaterialApp`
  /// locale and hands it in, the same shape [fetchNotifications]'s own
  /// return type ([WorkNotification.relativeTime]) already commits
  /// to: a pre-formatted string, not a lazily-localized one.
  final AppLocalizations _l10n;

  @override
  Future<List<WorkNotification>> fetchNotifications() async {
    final since = await _watermark.load();
    final notifications = await _api.notifications.fetch(since: since);

    final rows = <WorkNotification>[
      for (final n in notifications)
        if (_mapKind(n.kind) case final kind?)
          WorkNotification(
            id: n.id,
            kind: kind,
            title: n.title,
            relativeTime: _relativeTime(_l10n, n.createdAt),
            unread: n.unread,
            targetId: n.targetId,
          ),
    ];

    // Only reached once `fetch` above has already succeeded — see this
    // file's doc comment on why a failed request must never overwrite the
    // watermark.
    await _watermark.save(DateTime.now());

    return rows;
  }

  /// "The agent has seen everything up to now" — the exact thing the
  /// watermark stores, so marking all read is just pushing it to now. The
  /// next fetch sends this as `since`, and the server's
  /// `unread = createdAt > since` then reports every current row as read.
  @override
  Future<void> markAllRead() => _watermark.save(DateTime.now());
}

WorkNotificationKind? _mapKind(NotificationKind kind) => switch (kind) {
  NotificationKind.lead => WorkNotificationKind.lead,
  NotificationKind.sold => WorkNotificationKind.sold,
  NotificationKind.coworkerActivity => WorkNotificationKind.coworkerActivity,
  NotificationKind.publish => WorkNotificationKind.publish,
  NotificationKind.unknown => null,
};

/// A small "N units ago" formatter matching §4.4's seed copy style
/// ("2 min ago", "1 h ago", "Yesterday", "2 days ago"). Not promoted to
/// `Formatters` (`lib/shared/formatters/formatters.dart`) — this is the
/// only live-data screen in the whole Work build that renders a relative
/// time rather than [Formatters.date]'s absolute `DD.MM.YYYY | HH:MM`, so
/// there is exactly one caller.
String _relativeTime(AppLocalizations l10n, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) {
    return l10n.notificationsRelativeJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.notificationsRelativeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.notificationsRelativeHoursAgo(diff.inHours);
  }
  if (diff.inDays == 1) return l10n.notificationsRelativeYesterday;
  return l10n.notificationsRelativeDaysAgo(diff.inDays);
}
