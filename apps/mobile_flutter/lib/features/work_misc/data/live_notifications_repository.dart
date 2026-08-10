/// A real, network-backed [NotificationsRepository] — see
/// `notifications_repository.dart`'s doc comment for why this exists at
/// all (contract ruling 7.11 leaves it explicitly optional).
///
/// **What this can honestly synthesize, and what it can't.** SCREENS.md
/// §4.4 has 4 notification kinds; this repository covers 3 of them from
/// real, timestamped data:
///
/// - [WorkNotificationKind.lead] — every [LeadStatus.newLead] row from
///   `GET /leads`, timestamped by [Lead.createdAt], **plus** every lead
///   [Lead.isCallbackDueOrOverdue] as a callback reminder (the same shared
///   rule Dashboard/Kanban use), timestamped by [Lead.callbackDate].
/// - [WorkNotificationKind.sold] — every [AdStage.sold] row from
///   `GET /my/ads`, timestamped by [Ad.updatedAt] (the closest real proxy
///   for "when it was marked sold" this wire shape offers).
/// - [WorkNotificationKind.coworkerActivity] — every
///   [ActivityEventStage.adCreated] row from `GET /statistics/coworkers`,
///   timestamped by [ActivityEvent.createdAt], resolved to a coworker name
///   via `GET /coworkers` and an ad title via the already-fetched
///   `GET /my/ads` list (an event whose ad isn't in that list — deleted, or
///   outside the caller's own scope somehow — is skipped rather than
///   rendered with a blank title).
///
/// **[WorkNotificationKind.publish] is never synthesized here.** The only
/// candidate data source, `PublishResource.statusForAds`, deliberately
/// omits `lastAttemptAt` on every row it returns (see that method's own
/// doc comment) — there is no timestamp to rank a publish event against
/// everything else in this list, and `PublishResource.statusForAd`'s richer
/// per-ad shape would mean one extra round trip *per ad* to even attempt
/// it. Silently dropping the kind is more honest than mixing in a
/// mis-ordered or fabricated-timestamp row.
///
/// **[WorkNotificationFixture.unread] is always `false` here.** No read/
/// unread state exists anywhere in this schema (this repository is the
/// closest thing to "real" data §22 has, and even it has nothing to say
/// about read state) — inventing a heuristic (e.g. "unread if < 1 day old")
/// would let this screen show an unread dot backed by nothing, exactly the
/// kind of fabricated affordance this codebase's honesty rule forbids.
///
/// Results are capped at 30 rows (most-recent-first) — a defensive bound
/// for an agent with a long history, not a real pagination contract (none
/// of the four source endpoints offers one either).
library;

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import 'notifications_repository.dart';

const int _maxNotifications = 30;

class LiveNotificationsRepository implements NotificationsRepository {
  const LiveNotificationsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<WorkNotificationFixture>> fetchNotifications() async {
    final results = await Future.wait([
      _api.leads.list(),
      _api.agentAds.myList(),
      _api.statistics.coworkers(),
      _api.coworkers.list(),
    ]);
    final leads = results[0] as List<Lead>;
    final ads = results[1] as List<Ad>;
    final events = results[2] as List<ActivityEvent>;
    final coworkers = results[3] as List<Coworker>;

    final adsById = {for (final ad in ads) ad.id: ad};
    final coworkerNamesById = {
      for (final coworker in coworkers) coworker.id: coworker.fullName,
    };

    final rows = <(DateTime, WorkNotificationFixture)>[];

    for (final lead in leads) {
      if (lead.status == LeadStatus.newLead) {
        rows.add((
          lead.createdAt,
          WorkNotificationFixture(
            id: 'live-lead-new-${lead.id}',
            kind: WorkNotificationKind.lead,
            title: 'New lead: ${lead.fullName}',
            relativeTime: _relativeTime(lead.createdAt),
            unread: false,
            targetId: lead.id,
          ),
        ));
      }
      if (lead.callbackDate case final due? when lead.isCallbackDueOrOverdue) {
        rows.add((
          due,
          WorkNotificationFixture(
            id: 'live-lead-callback-${lead.id}',
            kind: WorkNotificationKind.lead,
            title: 'Callback reminder — Call ${lead.fullName}',
            relativeTime: _relativeTime(due),
            unread: false,
            targetId: lead.id,
          ),
        ));
      }
    }

    for (final ad in ads) {
      if (ad.stage == AdStage.sold) {
        rows.add((
          ad.updatedAt,
          WorkNotificationFixture(
            id: 'live-sold-${ad.id}',
            kind: WorkNotificationKind.sold,
            title: 'Listing sold — ${ad.title} marked as Sold',
            relativeTime: _relativeTime(ad.updatedAt),
            unread: false,
            targetId: ad.id,
          ),
        ));
      }
    }

    for (final event in events) {
      if (event.stage != ActivityEventStage.adCreated) continue;
      final ad = adsById[event.adId];
      final coworkerName = coworkerNamesById[event.coworkerId];
      if (ad == null || coworkerName == null) continue;
      rows.add((
        event.createdAt,
        WorkNotificationFixture(
          id: 'live-coworker-${event.id}',
          kind: WorkNotificationKind.coworkerActivity,
          title: 'Coworker added a new listing — $coworkerName created '
              '${ad.title}',
          relativeTime: _relativeTime(event.createdAt),
          unread: false,
          targetId: event.coworkerId,
        ),
      ));
    }

    rows.sort((a, b) => b.$1.compareTo(a.$1));
    return rows.take(_maxNotifications).map((r) => r.$2).toList();
  }
}

/// A small "N units ago" formatter matching §4.4's seed copy style
/// ("2 min ago", "1 h ago", "Yesterday", "2 days ago"). Not promoted to
/// `Formatters` (`lib/shared/formatters/formatters.dart`) — this is the
/// only live-data screen in the whole Work build that renders a relative
/// time rather than [Formatters.date]'s absolute `DD.MM.YYYY | HH:MM`, so
/// there is exactly one caller.
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}
