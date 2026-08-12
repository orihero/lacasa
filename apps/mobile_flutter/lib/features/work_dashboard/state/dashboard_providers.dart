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
///
/// **Finding M5's provider half.** `dashboard` stays mounted for the whole
/// Work-tab session (`StatefulShellRoute.indexedStack`) and none of the six
/// `AsyncNotifierProvider`s below is `.autoDispose`, so nothing ever tore
/// them down across a sign-out/sign-in before this fix — a new session
/// (even one sharing the exact same role as the last, which the router's
/// own redirect guard can't distinguish) would keep rendering the previous
/// account's leads/coworkers/ads/stats until the app happened to restart.
/// Each `build()` below now starts with [_watchSessionForCacheInvalidation],
/// which watches (not reads) the signed-in user's id — the same "let
/// Riverpod's own dependency graph do the invalidation" approach as
/// [myListingsResultsProvider] (`my_listings/state/my_listings_providers
/// .dart`) and [coworkersListProvider] (`coworkers/state/coworkers_providers
/// .dart`), rather than a fourth place trying to remember to call
/// `ref.invalidate` from inside `auth_session.dart`'s `signIn`/`signOut`
/// (out of this fix's file ownership, and a worse seam anyway — a provider
/// declaring its own dependency can't be forgotten by a future caller the
/// way an imperative invalidate-on-sign-out call site could be).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../navigation/auth_session.dart';
import '../data/dashboard_mode.dart';
import 'dashboard_repository_provider.dart';

/// See this file's doc comment's "Finding M5's provider half" section.
/// Selecting just `user?.id` (never the whole [AuthSessionState]) keeps
/// [AuthSessionState.isRestoring] flicker from re-firing every dashboard
/// fetch on its own.
void _watchSessionForCacheInvalidation(Ref ref) =>
    ref.watch(authSessionProvider.select((s) => s.user?.id));

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
    _watchSessionForCacheInvalidation(ref);
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
    _watchSessionForCacheInvalidation(ref);
    final filter = ref.watch(dashboardTimeRangeProvider);
    return ref.read(dashboardRepositoryProvider).fetchAdsSeries(filter);
  }
}

final adsSeriesProvider = AsyncNotifierProvider<AdsSeriesNotifier, AdsSeries>(
  AdsSeriesNotifier.new,
);

class DashboardLeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() {
    _watchSessionForCacheInvalidation(ref);
    return ref.read(dashboardRepositoryProvider).fetchAllLeads();
  }
}

final dashboardLeadsProvider =
    AsyncNotifierProvider<DashboardLeadsNotifier, List<Lead>>(
      DashboardLeadsNotifier.new,
    );

class DashboardCoworkersNotifier extends AsyncNotifier<List<Coworker>> {
  @override
  Future<List<Coworker>> build() {
    _watchSessionForCacheInvalidation(ref);
    return ref.read(dashboardRepositoryProvider).fetchCoworkers();
  }
}

final dashboardCoworkersProvider =
    AsyncNotifierProvider<DashboardCoworkersNotifier, List<Coworker>>(
      DashboardCoworkersNotifier.new,
    );

class DashboardAdsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() {
    _watchSessionForCacheInvalidation(ref);
    return ref.read(dashboardRepositoryProvider).fetchAllAds();
  }
}

final dashboardAdsProvider = AsyncNotifierProvider<DashboardAdsNotifier, List<Ad>>(
  DashboardAdsNotifier.new,
);

class DashboardCoworkerActivityNotifier
    extends AsyncNotifier<List<ActivityEvent>> {
  @override
  Future<List<ActivityEvent>> build() {
    _watchSessionForCacheInvalidation(ref);
    return ref.read(dashboardRepositoryProvider).fetchCoworkerActivity();
  }
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
