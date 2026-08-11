/// `GET /api/notifications`'s row shape — see `docs/04-api-spec.md`'s
/// Notifications section and `apps/api/src/services/notificationService.js`'s
/// header comment for the full design: a merged, newest-first feed derived
/// from leads/ad-lifecycle/coworker/publish activity, with **no
/// notifications table and no persisted read state**.
///
/// [AppNotification.unread] is exactly what the server computed against
/// whatever `since` the caller sent (`unread = createdAt > since`, or
/// unconditionally `true` when `since` was omitted — the server has no
/// basis to claim anything has been seen with no boundary at all). This
/// class does not recompute or second-guess that; it is honest about being
/// a snapshot, not a durable flag — polling twice with two different
/// `since` values can legitimately disagree about the same row.
library;

import 'wire_timestamp.dart';

/// One of the four sources `notificationService.js` folds into the feed.
enum NotificationKind {
  lead,
  sold,
  coworkerActivity,
  publish,
  unknown;

  static NotificationKind fromWire(String? value) => switch (value) {
    'lead' => NotificationKind.lead,
    'sold' => NotificationKind.sold,
    'coworkerActivity' => NotificationKind.coworkerActivity,
    'publish' => NotificationKind.publish,
    _ => NotificationKind.unknown,
  };
}

class AppNotification {
  /// Deterministic — built server-side from the source row's own primary
  /// key(s) (`lead:<leadId>:<eventId>`, `sold:<adId>:<eventId>`,
  /// `coworker:<coworkerId>:<eventId>`, or
  /// `publish:<adId>:<channel>:<epochSecondsOfLastAttempt>`), never a
  /// minted UUID. An unchanged underlying row reproduces the same [id]
  /// across polls, so a client can dedupe against what it already
  /// rendered — see `notificationService.js`'s header comment for why a
  /// per-request-random id would break that.
  final String id;
  final NotificationKind kind;
  final String title;
  final DateTime createdAt;

  /// See this file's doc comment — computed relative to the `since` the
  /// caller passed, not a durably stored flag.
  final bool unread;

  /// The id of whatever this notification is about — a lead id, an ad id,
  /// or a coworker id, depending on [kind] — what tapping the row should
  /// navigate to.
  final String targetId;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    required this.unread,
    required this.targetId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      kind: NotificationKind.fromWire(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      createdAt: json['createdAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['createdAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      unread: json['unread'] as bool? ?? true,
      targetId: json['targetId'] as String? ?? '',
    );
  }
}
