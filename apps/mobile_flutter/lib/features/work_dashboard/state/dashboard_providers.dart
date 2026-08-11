/// Riverpod state for `dashboard` (SCREENS.md §24). Six independent async
/// pieces plus one local selector — deliberately not merged into one
/// "screen state" provider (`WORK_TAB_CONTRACT.md` §6: "independent
/// providers per independently-failable section" — a failing coworker fetch
/// must not blank the ad stat tiles):
///
/// - [dashboardTimeRangeProvider] — the All/This month/This week/Today
///   selector (local UI state, default `thisMonth` per SCREENS.md §24).
/// - [adsStatisticsProvider] — re-fetches whenever the time range changes;
///   the only stat that genuinely responds to it server-side (ruling 7.1).
/// - [dashboardLeadsProvider] / [dashboardCoworkersProvider] /
///   [dashboardAdsProvider] — the caller's complete lead/coworker/ad lists.
///   Deliberately **not** re-fetched when the time range changes: neither
///   `GET /leads`, `GET /coworkers` nor `GET /my/ads` takes a date-range
///   param, and `apps/console`'s own `StatisticsScreen` makes the identical
///   call — Active leads/Coworkers are current-snapshot tiles, not
///   period-scoped ones, matching its `useLeads()`/`useCoworkers()` calls
///   never taking the selected `period` as an argument either.
/// - [dashboardCoworkerActivityProvider] — `GET /statistics/coworkers`,
///   always unfiltered server-side (ruling 7.2) — backs, filtered
///   client-side per [isWithinTimeRange],
///   [coworkerStatRowsProvider]'s "Ads count" column (see that provider's
///   own doc comment for why: the fixture set's own §4.3 "11"/"8" figures
///   only reconcile against this event stream, `workAdsFixtures`' own
///   `Ad.coworkerId` tagging is far sparser).
///
/// [coworkerStatRowsProvider] is the Coworker statistics section's actual
/// per-row data source — see its own doc comment for the event-stage fold
/// and the range-selector wiring ruling 7.2 asks for.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/dashboard_mode.dart';
import 'dashboard_repository_provider.dart';

/// SCREENS.md §24's time-range selector. `thisMonth` is the spec'd default.
class DashboardTimeRangeNotifier extends Notifier<StatisticsFilter> {
  @override
  StatisticsFilter build() => StatisticsFilter.thisMonth;

  void select(StatisticsFilter filter) => state = filter;
}

final dashboardTimeRangeProvider =
    NotifierProvider<DashboardTimeRangeNotifier, StatisticsFilter>(
      DashboardTimeRangeNotifier.new,
    );

class AdsStatisticsNotifier extends AsyncNotifier<AdsStatistics> {
  @override
  Future<AdsStatistics> build() {
    final filter = ref.watch(dashboardTimeRangeProvider);
    return ref.read(dashboardRepositoryProvider).fetchAdsStatistics(filter);
  }
}

final adsStatisticsProvider =
    AsyncNotifierProvider<AdsStatisticsNotifier, AdsStatistics>(
      AdsStatisticsNotifier.new,
    );

/// The "Ads statistics" chart's real, server-bucketed series
/// (`widgets/ads_statistics_panel.dart`) — re-fetches whenever the time
/// range changes, same as [adsStatisticsProvider], and independent of it:
/// the stat tiles and the chart are two different endpoints
/// (`fetchAdsStatistics`/`fetchAdsSeries`) that can fail independently.
class AdsSeriesNotifier extends AsyncNotifier<AdsSeries> {
  @override
  Future<AdsSeries> build() {
    final filter = ref.watch(dashboardTimeRangeProvider);
    return ref.read(dashboardRepositoryProvider).fetchAdsSeries(filter);
  }
}

final adsSeriesProvider = AsyncNotifierProvider<AdsSeriesNotifier, AdsSeries>(
  AdsSeriesNotifier.new,
);

class DashboardLeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() =>
      ref.read(dashboardRepositoryProvider).fetchAllLeads();
}

final dashboardLeadsProvider =
    AsyncNotifierProvider<DashboardLeadsNotifier, List<Lead>>(
      DashboardLeadsNotifier.new,
    );

class DashboardCoworkersNotifier extends AsyncNotifier<List<Coworker>> {
  @override
  Future<List<Coworker>> build() =>
      ref.read(dashboardRepositoryProvider).fetchCoworkers();
}

final dashboardCoworkersProvider =
    AsyncNotifierProvider<DashboardCoworkersNotifier, List<Coworker>>(
      DashboardCoworkersNotifier.new,
    );

class DashboardAdsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() =>
      ref.read(dashboardRepositoryProvider).fetchAllAds();
}

final dashboardAdsProvider = AsyncNotifierProvider<DashboardAdsNotifier, List<Ad>>(
  DashboardAdsNotifier.new,
);

class DashboardCoworkerActivityNotifier
    extends AsyncNotifier<List<ActivityEvent>> {
  @override
  Future<List<ActivityEvent>> build() =>
      ref.read(dashboardRepositoryProvider).fetchCoworkerActivity();
}

final dashboardCoworkerActivityProvider =
    AsyncNotifierProvider<DashboardCoworkerActivityNotifier, List<ActivityEvent>>(
      DashboardCoworkerActivityNotifier.new,
    );

/// SCREENS.md §24/§31's shared "due today or overdue" callback count —
/// `apps/console`'s `countCallbacksDueToday` (`deriveStatistics.ts`) ported
/// verbatim, reusing [Lead.isCallbackDueOrOverdue] rather than re-deriving
/// the due-today rule a second time.
int countCallbacksDueToday(List<Lead> leads) =>
    leads.where((lead) => lead.isCallbackDueOrOverdue).length;

/// The rolling window `thisWeek` names for [isWithinTimeRange] — 7 trailing
/// days from "now", not a calendar week (this build defines a calendar week
/// nowhere else either; `apps/console`'s own `countCoworkersActiveThisWeek`
/// makes the identical choice).
const Duration _activeWindow = Duration(days: 7);

/// Whether [createdAt] falls inside the window [filter] names — the
/// client-side substitute for the `filterType` param `GET
/// /statistics/coworkers` accepts but ignores (ruling 7.2). Mirrors
/// [countCoworkersActiveThisWeek]'s own rolling-7-day "this week" window
/// rather than a calendar week, since no calendar-week boundary is defined
/// anywhere else in this build either.
bool isWithinTimeRange(
  DateTime createdAt,
  StatisticsFilter filter, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  return switch (filter) {
    StatisticsFilter.all => true,
    StatisticsFilter.today =>
      createdAt.year == reference.year &&
          createdAt.month == reference.month &&
          createdAt.day == reference.day,
    StatisticsFilter.thisWeek => !createdAt.isBefore(
      reference.subtract(_activeWindow),
    ),
    StatisticsFilter.thisMonth =>
      createdAt.year == reference.year && createdAt.month == reference.month,
  };
}

/// One row of the Coworker statistics section (bar chart + list, SCREENS.md
/// §24). **`saleCount` used to be a permanent em dash here** — ruling 7.6
/// originally (and wrongly) concluded there was no "deals closed" event
/// anywhere in the schema. There is: `ActivityEventStage.adSold` events
/// always carried `coworkerId` (the same stream [adsCount] already folds
/// for `adCreated`), so `saleCount` folds that same stream by the `adSold`
/// stage instead — see `coworker_statistics_section.dart`'s doc comment for
/// how the column renders now that it's a real number.
class CoworkerStatRow {
  const CoworkerStatRow({
    required this.coworker,
    required this.adsCount,
    required this.leadCount,
    required this.saleCount,
  });

  final Coworker coworker;
  final int adsCount;
  final int leadCount;
  final int saleCount;
}

/// The Coworker statistics section's data source.
///
/// **`saleCount` folds the same [dashboardCoworkerActivityProvider] stream
/// as `adsCount`, just filtered to [ActivityEventStage.adSold] instead of
/// `adCreated`** — no separate fetch, no separate provider, since both
/// numbers already live in the one event stream this provider already
/// watches. It is time-range-filtered the same way `adsCount` is (live mode
/// only — see the `inRange` note below).
///
/// **`adsCount` folds [dashboardCoworkerActivityProvider]'s
/// [ActivityEventStage.adCreated] events by [ActivityEvent.coworkerId],
/// not [Ad.coworkerId] over [dashboardAdsProvider].** Both are real,
/// contract-sanctioned derivations (ruling 7.6 names the `Ad.coworkerId`
/// path for `coworkers-list`'s own "Ads count" column), but only the
/// event-stream fold reconciles with the fixture set's own §4.3 figures:
/// `workStatisticsCoworkersFixture`'s doc comment says outright it exists to
/// back "the two coworkers' '11'/'8' listings ... figures from §4.3" —
/// `workAdsFixtures` only tags one ad per coworker, which would render this
/// section almost empty for no honest reason when a richer, equally-real
/// fixture exists for exactly this purpose. `leadCount` stays on
/// [Lead.coworkerId] directly ([dashboardLeadsProvider]) — the fixture has
/// no `leadCreated` [ActivityEvent] rows to fold instead, and [Lead] itself
/// already carries a real `coworkerId` field, so there is no equivalent
/// reason to prefer the event stream there.
///
/// **Ruling 7.2's client-side range filter applies only in live mode.**
/// `workStatisticsCoworkersFixture`'s timestamps are synthetic (fixed
/// offsets from a constant, unrelated to wall-clock "now") — filtering them
/// against a real today/this-week/this-month boundary would zero out every
/// range but "All" and look like a rendering bug, not an honest empty
/// state. Live mode's timestamps are real, so [isWithinTimeRange] is worth
/// applying there — see `data/dashboard_mode.dart`'s `useLiveWorkDashboardApi`
/// gate below.
///
/// The coworkers fetch is this provider's primary gate (its own
/// loading/error state is what `coworker_statistics_section.dart` renders
/// for the section as a whole); activity/leads are secondary enrichment — a
/// failed or still-loading fetch degrades that half of every row's counts
/// to 0 rather than blocking a section that's still useful without it.
final coworkerStatRowsProvider = Provider<AsyncValue<List<CoworkerStatRow>>>((
  ref,
) {
  final coworkersAsync = ref.watch(dashboardCoworkersProvider);
  final events =
      ref.watch(dashboardCoworkerActivityProvider).value ??
      const <ActivityEvent>[];
  final leads = ref.watch(dashboardLeadsProvider).value ?? const <Lead>[];
  final filter = ref.watch(dashboardTimeRangeProvider);

  bool inRange(ActivityEvent event) =>
      !useLiveWorkDashboardApi || isWithinTimeRange(event.createdAt, filter);

  return coworkersAsync.whenData((coworkers) {
    return coworkers
        .map(
          (coworker) => CoworkerStatRow(
            coworker: coworker,
            adsCount: events
                .where(
                  (event) =>
                      event.coworkerId == coworker.id &&
                      event.stage == ActivityEventStage.adCreated &&
                      inRange(event),
                )
                .length,
            leadCount: leads
                .where((lead) => lead.coworkerId == coworker.id)
                .length,
            saleCount: events
                .where(
                  (event) =>
                      event.coworkerId == coworker.id &&
                      event.stage == ActivityEventStage.adSold &&
                      inRange(event),
                )
                .length,
          ),
        )
        .toList(growable: false);
  });
});
