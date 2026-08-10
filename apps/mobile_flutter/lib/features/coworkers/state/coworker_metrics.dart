/// Pure derivation helpers for the two figures `Coworker` itself cannot
/// carry — see `coworkers_repository.dart`'s doc comment and
/// WORK_TAB_CONTRACT.md ruling 7.6. Deliberately free of any Riverpod/
/// widget dependency (unlike `apps/console/src/data/useCoworkers.ts`'s
/// `deriveCoworkerMetrics`, which is a plain function for the identical
/// reason: "pure so it's trivially testable and so the screen can call it
/// once per coworker over lists it already fetched — it does not fetch
/// anything itself").
library;

import '../../../api/api.dart';

/// Count of [ads] whose `coworkerId` matches [coworkerId] — real, not
/// estimated (`Ad.coworkerId` is a genuine wire field), just not something
/// [Coworker] carries pre-counted.
int coworkerListingsCount(String coworkerId, List<Ad> ads) {
  var count = 0;
  for (final ad in ads) {
    if (ad.coworkerId == coworkerId) count++;
  }
  return count;
}

/// The latest [ActivityEvent.createdAt] among [events] whose `coworkerId`
/// matches [coworkerId], or `null` when there is none — a coworker with no
/// recorded activity gets an honest "no data" answer from the caller (an em
/// dash), never a fabricated "just now"/"today".
DateTime? coworkerLastActiveAt(String coworkerId, List<ActivityEvent> events) {
  DateTime? latest;
  for (final event in events) {
    if (event.coworkerId != coworkerId) continue;
    if (latest == null || event.createdAt.isAfter(latest)) {
      latest = event.createdAt;
    }
  }
  return latest;
}

/// A short relative-time label for [dt] against [now] (defaults to
/// [DateTime.now]) — "Just now" / "12 min ago" / "3 h ago" / "Yesterday" /
/// "5 days ago", falling back to a bare day count beyond a week rather than
/// inventing a calendar-week/month vocabulary SCREENS.md never specifies
/// for this particular label (only §4.4's notification feed gets exact
/// relative-time copy, and that is fixture-frozen text, not a formatter —
/// see `work_seed_data.dart`'s own doc comment).
String coworkerActivityLabel(DateTime dt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}
