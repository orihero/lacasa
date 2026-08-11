/// Pure derivation/lookup helpers for the figures `Coworker` itself cannot
/// carry — see `coworkers_repository.dart`'s doc comment and
/// WORK_TAB_CONTRACT.md ruling 7.6. Deliberately free of any Riverpod/
/// widget dependency (unlike `apps/console/src/data/useCoworkers.ts`'s
/// `deriveCoworkerMetrics`, which is a plain function for the identical
/// reason: "pure so it's trivially testable and so the screen can call it
/// once per coworker over lists it already fetched — it does not fetch
/// anything itself").
///
/// **This file used to fold [Ad]/[ActivityEvent] lists client-side**
/// (`coworkerListingsCount`/`coworkerLastActiveAt`, both since removed) —
/// `GET /statistics/coworkers/summary` now does that fold server-side, so a
/// screen looks its coworker's row up directly in the fetched
/// [CoworkerSummary] list via [summaryFor] instead.
library;

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';

/// The [CoworkerSummary] row for [coworkerId] within [summaries], or `null`
/// when the aggregate hasn't loaded this coworker yet — a caller renders
/// that as "…"/an em dash the same way it already handles the surrounding
/// async value's own loading/error states, never a fabricated `0`.
CoworkerSummary? summaryFor(String coworkerId, List<CoworkerSummary> summaries) {
  for (final summary in summaries) {
    if (summary.coworkerId == coworkerId) return summary;
  }
  return null;
}

/// A short relative-time label for [dt] against [now] (defaults to
/// [DateTime.now]) — "Just now" / "12 min ago" / "3 h ago" / "Yesterday" /
/// "5 days ago", falling back to a bare day count beyond a week rather than
/// inventing a calendar-week/month vocabulary SCREENS.md never specifies
/// for this particular label (only §4.4's notification feed gets exact
/// relative-time copy, and that is fixture-frozen text, not a formatter —
/// see `work_seed_data.dart`'s own doc comment).
///
/// Takes [l10n] rather than a `BuildContext` — this is a pure, widget-free
/// helper (see the file doc comment) called from `coworker_detail_screen
/// .dart`'s build methods, which already have an `AppLocalizations` in
/// scope; threading the resolved instance through avoids a second
/// `AppLocalizations.of(context)` lookup at the call site.
String coworkerActivityLabel(AppLocalizations l10n, DateTime dt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) return l10n.coworkersActivityJustNow;
  if (diff.inMinutes < 60) return l10n.coworkersActivityMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.coworkersActivityHoursAgo(diff.inHours);
  if (diff.inDays == 1) return l10n.coworkersActivityYesterday;
  return l10n.coworkersActivityDaysAgo(diff.inDays);
}
