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
///   client-side per [isWithinTimeRange], [coworkerStatRowsProvider]'s "Ads
///   count" *and* "Sale count" columns (see that provider's own doc comment
///   for why both come off this one stream rather than one off the ad
///   table).
///
/// [canManageCoworkersProvider] is the one non-async piece besides the
/// selector: a pure read of the signed-in session that decides whether the
/// screen renders its coworker surfaces at all (see its own doc comment).
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
import 'dashboard_repository_provider.dart';

/// See this file's doc comment's "Finding M5's provider half" section.
/// Selecting just `user?.id` (never the whole [AuthSessionState]) keeps
/// [AuthSessionState.isRestoring] flicker from re-firing every dashboard
/// fetch on its own.
void _watchSessionForCacheInvalidation(Ref ref) =>
    ref.watch(authSessionProvider.select((s) => s.user?.id));

/// Whether this session has a coworker roster to manage at all — the one
/// predicate every coworker-shaped surface on `dashboard` gates on (the
/// "Coworker statistics" section, the "Coworkers" stat tile and the
/// Workspace "Coworkers" row).
///
/// **A solo realtor has no team and cannot acquire one.**
/// `apps/api/src/routes/coworkers.js` 403s `POST /coworkers` for a
/// `RealtorKind.solo` caller, and `coworkers_list_screen.dart` already
/// hides its "+ Add new coworker" action on exactly this test —
/// WORK_TAB_CONTRACT.md: "check `AuthUser.realtor?.kind` client-side to hide
/// the affordance entirely for a solo agent rather than let this 403 surface
/// as a surprise." Solo is the *default* choice on `register`, so before
/// this predicate reached the dashboard the most common new realtor landed
/// on a screen a third of which was a permanently empty "No coworkers yet."
/// panel with no action, over a tile inviting them to "tap to manage" a
/// roster they are forbidden to add to. Hiding is right rather than
/// disabling for the same reason it is on `coworkers-list`: there is no
/// state the user can reach where these surfaces become useful.
///
/// It repeats `coworkers_list_screen.dart`'s expression rather than importing
/// it because that expression lives inline in a `build()` there; this is the
/// second call site and therefore the first place a shared name is worth
/// having. **The `role == agent` half matters even though only agents ever
/// reach this screen** (`app_router.dart` redirects a coworker session
/// straight to `workMyListings`): a coworker cannot create coworkers either,
/// so the predicate stays honest if this screen is ever pumped for one.
///
/// A `null` [RealtorProfile] — the shape every `setRole`-only test session
/// and any pre-application agent has — is deliberately **not** treated as
/// solo. Nothing has said this account is solo, and hiding a real team's
/// statistics on a missing field would be the worse error of the two.
final canManageCoworkersProvider = Provider<bool>((ref) {
  final session = ref.watch(authSessionProvider);
  return session.role == UserRole.agent &&
      session.user?.realtor?.kind != RealtorKind.solo;
});

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

final dashboardAdsProvider =
    AsyncNotifierProvider<DashboardAdsNotifier, List<Ad>>(
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
    AsyncNotifierProvider<
      DashboardCoworkerActivityNotifier,
      List<ActivityEvent>
    >(DashboardCoworkerActivityNotifier.new);

/// SCREENS.md §24/§31's shared "due today or overdue" callback count —
/// `apps/console`'s `countCallbacksDueToday` (`deriveStatistics.ts`), reusing
/// [Lead.isCallbackDueOrOverdue] rather than re-deriving the due-today rule a
/// second time.
///
/// **It folds only the leads [countActiveLeads] itself counts** — the same
/// [_isLeadActive] predicate, deliberately not a second opinion about which
/// leads are still in play. Both surfaces that render this number render it
/// as the *subtitle of* the active-leads figure ("N active · M need a call
/// back", "M needs a call back" under the tile's N), so the two must satisfy
/// `M <= N` or the pair contradicts itself on screen. They used to, trivially:
/// the value beside it was `leads.length`, which is `>=` any subset of the
/// table. Now that the value is [countActiveLeads], an unfiltered fold here
/// would let a single **closed** lead carrying a stale `callbackDate` — a
/// rejected conversation nobody ever cleared the date off, which is the
/// normal end state, since `kanban-move-sheet` never blanks it — render the
/// tile as "0" over the subtitle "1 needs a call back". Gating both counts on
/// one predicate makes that state unrepresentable rather than merely
/// unlikely.
///
/// It is also the honest count on its own terms: a callback on an archived or
/// already-closed lead is not a call anyone has to make, so counting it would
/// overstate the agent's actual queue even if nothing were rendered beside it.
int countCallbacksDueToday(List<Lead> leads) => leads
    .where((lead) => _isLeadActive(lead) && lead.isCallbackDueOrOverdue)
    .length;

/// SCREENS.md §24's **"Active leads"** stat tile and the Workspace "Leads"
/// row's `{n} active` figure — the single definition of "active" both read,
/// deliberately one function so those two surfaces can never disagree about
/// the same word again.
///
/// Both call sites used to render `leads.length`, i.e. the raw `GET /leads`
/// table (`listLeads` in `apps/api/src/services/leadService.js` returns every
/// agent-scoped row, filtered by nothing) — so an agent with 6 live leads and
/// 40 rejections read "46" under a label that promises the opposite.
/// [Lead] carries two independent "still in play" signals and this counts a
/// lead only when **both** agree:
///
/// - **[Lead.active] is true.** This is the server's archive/soft-delete
///   flag: `createLead` defaults it to `true` and `parseLeadInput` lets
///   `PATCH /leads/:id` clear it, but nothing on the read path filters
///   archived rows out, so the client has to.
/// - **[Lead.status] is neither [LeadStatus.rejected] nor
///   [LeadStatus.accepted]** — the two terminal Kanban outcomes. SCREENS.md
///   §31/§34 treats exactly this pair as "the conversation is over": they
///   are the only two statuses `kanban-move-sheet` collects a closing
///   `conversationComment` for, and the only two `kanban_card.dart` renders
///   that closing note pill for. `accepted` is excluded alongside `rejected`
///   for that reason and not by oversight — a won deal is no longer a lead
///   anyone has to work. The three non-terminal statuses
///   ([LeadStatus.newLead], [LeadStatus.couldNotConnect],
///   [LeadStatus.needToCallBack]) all still need action from the agent, so
///   all three count.
///
/// [LeadStatus.unknown] deliberately **counts as active**. It only means the
/// server sent a status string this build does not recognize yet, which is no
/// evidence that the lead is closed; silently hiding a live lead is the worse
/// of the two failure modes, and it is the same conservatism behind
/// [LeadStatus.kanbanOrder] refusing to file `unknown` under a real column.
///
/// Note this is a **current-snapshot** count, not a period-scoped one: it is
/// intentionally not passed through [isWithinTimeRange], matching this file's
/// own header note (and `apps/console`'s `StatisticsScreen`, whose
/// `useLeads()` never takes the selected period either) — the tile answers
/// "how many leads are open right now", a question the range chips do not
/// narrow.
int countActiveLeads(List<Lead> leads) => leads.where(_isLeadActive).length;

bool _isLeadActive(Lead lead) =>
    lead.active &&
    lead.status != LeadStatus.rejected &&
    lead.status != LeadStatus.accepted;

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
///
/// **Both sides are normalized to the device's local zone before any
/// calendar field is read.** Every timestamp that reaches this predicate
/// ([ActivityEvent.createdAt], [Lead.createdAt]) arrives through
/// [dateTimeFromWireTimestamp], which builds its [DateTime] with
/// `isUtc: true` — so `.year`/`.month`/`.day` on the raw value are *UTC*
/// calendar fields, while `DateTime.now()` returns *local* ones. Comparing
/// the two directly was an off-by-one-day bug for every user whose zone
/// isn't UTC, and this app's own market is one of them: a lead created at
/// 03:00 on the 1st in Tashkent (UTC+5) is stored as 22:00Z on the last day
/// of the previous month, so it dropped out of "Today" *and* out of "This
/// month" — the range chips silently under-reporting the day's work, worst
/// exactly during the early-morning hours. `.toLocal()` on an already-local
/// value is a no-op, so this is safe for the caller-supplied [now] too, and
/// [StatisticsFilter.thisWeek]'s [DateTime.isBefore] comparison was never
/// affected (it compares absolute instants, not calendar fields) — the
/// conversion is applied uniformly anyway so no future edit to this switch
/// has to re-derive which arms need it.
///
/// The user's own zone is the right frame here rather than the server's:
/// "Today" on a stat chip means the day the person tapping it is living in.
bool isWithinTimeRange(
  DateTime createdAt,
  StatisticsFilter filter, {
  DateTime? now,
}) {
  final at = createdAt.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();
  return switch (filter) {
    StatisticsFilter.all => true,
    StatisticsFilter.today =>
      at.year == reference.year &&
          at.month == reference.month &&
          at.day == reference.day,
    StatisticsFilter.thisWeek => !at.isBefore(
      reference.subtract(_activeWindow),
    ),
    StatisticsFilter.thisMonth =>
      at.year == reference.year && at.month == reference.month,
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
/// watches. It is time-range-filtered the same way `adsCount` is — always,
/// for every source (see the `inRange` note below).
///
/// **`adsCount` folds [dashboardCoworkerActivityProvider]'s
/// [ActivityEventStage.adCreated] events by [ActivityEvent.coworkerId],
/// not [Ad.coworkerId] over [dashboardAdsProvider]** — so that both of this
/// row's ad-derived numbers come from one fetch and one definition of
/// "belongs to this coworker". `saleCount` has no second source at all
/// (nothing in the ad table records *who* sold a listing; only the `AD_SOLD`
/// event does), and both `AD_CREATED`'s and `Ad.coworkerId`'s value is
/// stamped from the same `actor.coworkerId` at create time
/// (`adService.createAd`), so the two paths cannot disagree about a
/// coworker's ad while they can disagree about how many rows survive
/// deletion. Deriving "Ads count" from the same stream "Sale count" must use
/// keeps a row internally consistent; ruling 7.6's `Ad.coworkerId` path
/// stays correct for `coworkers-list`'s own column, which folds no events.
///
/// (This choice used to be justified by two fixture files —
/// `workStatisticsCoworkersFixture` and `workAdsFixtures` — and their §4.3
/// "11"/"8" figures. Both were deleted along with the fixture repositories,
/// so the reasoning above rests on the live sources instead, which is what
/// it should have rested on from the start.)
///
/// `leadCount` folds [dashboardLeadsProvider] by [Lead.coworkerId] rather
/// than the stream's [ActivityEventStage.leadCreated] events, which do
/// exist. Neither source is truer — `leadService.createLead` stamps the row
/// and the event from the one `actor.coworkerId`, and nothing reassigns
/// either afterwards — so the tie breaks on cost and failure surface: the
/// lead list is already fetched for the "Active leads" tile, and [Lead]
/// carries both the `coworkerId` and the [Lead.createdAt] this column needs,
/// so reading it adds no request and one fewer thing that can be missing.
/// It is **not** an unfiltered fold of that list: see the range-filter
/// paragraph below, which governs this column exactly as it does the other
/// two.
///
/// **All three columns honour the time-range chip — `leadCount` included.**
/// It did not used to: `adsCount`/`saleCount` filtered their events through
/// [isWithinTimeRange] while `leadCount` folded the whole lead list, so
/// picking "Today" produced rows reading `Ads 0 · Leads 14 · Sales 0` —
/// three numbers under one selector, only two of which obeyed it. [Lead]
/// carries a real [Lead.createdAt] (the same `{seconds}` wire shape
/// [ActivityEvent.createdAt] uses), so the fix is simply to run it through
/// the identical predicate rather than to rename the column. A lead whose
/// `createdAt` was missing on the wire decodes to the epoch and therefore
/// falls outside every range but "All" — the honest outcome for a row with
/// no usable date, and not something worth faking a timestamp to avoid.
///
/// The column stays an *outcome-blind* count of leads created in the window:
/// unlike the "Active leads" tile it does **not** go through
/// [countActiveLeads], because a lead this coworker brought in and later lost
/// is still work they did in that period — exactly as `adsCount` keeps
/// counting an ad that has since sold.
///
/// **Ruling 7.2's client-side range filter now applies unconditionally.**
/// It used to be gated behind `dashboard_mode.dart`'s
/// `useLiveWorkDashboardApi`, because the fixture dashboard's timestamps
/// were synthetic (fixed offsets from a constant, unrelated to wall-clock
/// "now") and filtering them against a real today/this-week/this-month
/// boundary zeroed out every range but "All" — which read as a rendering
/// bug rather than an honest empty state. That gate is gone along with the
/// fixture repositories: every timestamp reaching this provider now comes
/// from the API and is real, so [isWithinTimeRange] simply always applies.
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
      isWithinTimeRange(event.createdAt, filter);
  bool leadInRange(Lead lead) => isWithinTimeRange(lead.createdAt, filter);

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
                .where(
                  (lead) => lead.coworkerId == coworker.id && leadInRange(lead),
                )
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
