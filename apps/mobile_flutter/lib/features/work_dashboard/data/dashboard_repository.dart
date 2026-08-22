/// Data-access seam for `dashboard` (SCREENS.md §24). One implementation
/// ships — [LiveDashboardRepository], over the real [LaCasaApi]. The
/// fixture repository and the `dashboard_mode.dart` compile-time switch
/// that used to choose between the two are gone; the seam stays because it
/// is what `test/features/work_dashboard/support/fake_dashboard_repository
/// .dart` overrides, which is the only other implementation anywhere.
///
/// **Why six methods instead of one "dashboard snapshot" call.** The build
/// contract's Riverpod convention (`WORK_TAB_CONTRACT.md` §6) asks for
/// "independent providers per independently-failable section" — a failing
/// coworker fetch must not blank the ad stat tiles. A single aggregate method
/// would force one `AsyncValue` over data that genuinely comes from up to
/// four different server round trips (`/statistics/ads`,
/// `/statistics/ads/series`, `/leads`, `/coworkers`); six thin methods let
/// `state/dashboard_providers.dart` build one `AsyncNotifier` per method
/// instead.
///
/// **[fetchAdsSeries] closes contract ruling 7.1's old gap.** `GET
/// /statistics/ads` only ever returns period totals — that's still true, and
/// [fetchAdsStatistics] still backs the stat tiles from it. But `GET
/// /statistics/ads/series` now exists and returns a real, server-bucketed
/// day/hour series, so `widgets/ads_statistics_panel.dart` no longer reads
/// `WorkDashboardChartFixture` directly nor degrades to a 2-bar comparison
/// when there is no seed data — it plots one real [AdsSeries] from this one
/// method.
library;

import '../../../api/api.dart';

abstract class DashboardRepository {
  /// `GET /statistics/ads?filterType=` — period-scoped Ads created/sold
  /// totals. The one dashboard figure that genuinely responds to the
  /// time-range selector server-side (ruling 7.1).
  Future<AdsStatistics> fetchAdsStatistics(StatisticsFilter filter);

  /// `GET /statistics/ads/series?filterType=` — the bucketed sibling of
  /// [fetchAdsStatistics], backing the "Ads statistics" chart
  /// (`widgets/ads_statistics_panel.dart`) with real per-bucket
  /// created/sold counts instead of a single pair of totals. See this
  /// file's own doc comment for why this closes contract ruling 7.1.
  Future<AdsSeries> fetchAdsSeries(StatisticsFilter filter);

  /// `GET /statistics/coworkers`-shaped raw events, always the full
  /// unfiltered history (ruling 7.2 — this endpoint ignores any date range).
  /// Backs the Coworker statistics section's "Ads count" column (folded by
  /// [ActivityEvent.coworkerId]/[ActivityEventStage.adCreated], and filtered
  /// client-side by the time-range selector — unconditionally now that every
  /// timestamp reaching it is a real one; see
  /// `state/dashboard_providers.dart`'s `coworkerStatRowsProvider` doc
  /// comment for the gate that used to sit in front of that fold).
  Future<List<ActivityEvent>> fetchCoworkerActivity();

  /// The caller's complete ad list, every stage, no pagination (same
  /// contract as `AgentAdsResource.myList`) — backs the Workspace "My Ads"
  /// quick-link subtitle's listing/draft counts. **Not** the source of the
  /// coworker statistics section's "Ads count" column — see
  /// [fetchCoworkerActivity]'s own doc comment for why that column folds
  /// the event stream instead of `Ad.coworkerId` here.
  Future<List<Ad>> fetchAllAds();

  /// The caller's complete lead list, no pagination — backs the "Active
  /// leads" stat tile, its "N need a callback today" sub-label, the
  /// per-coworker "Lead count" column (via `Lead.coworkerId`), and the
  /// Workspace "Leads" quick-link subtitle.
  Future<List<Lead>> fetchAllLeads();

  /// The caller's coworkers — backs the "Coworkers" stat tile and the
  /// coworker statistics section's rows.
  Future<List<Coworker>> fetchCoworkers();
}
