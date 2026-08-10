/// Data-access seam for `dashboard` (SCREENS.md §24). Two implementations
/// exist: [FixtureDashboardRepository] (bundled seed data, no network) and
/// [LiveDashboardRepository] (the real [LaCasaApi]) — see `dashboard_mode.dart`
/// for which one the app wires up by default and how to switch.
///
/// **Why five methods instead of one "dashboard snapshot" call.** The build
/// contract's Riverpod convention (`WORK_TAB_CONTRACT.md` §6) asks for
/// "independent providers per independently-failable section" — a failing
/// coworker fetch must not blank the ad stat tiles. A single aggregate method
/// would force one `AsyncValue` over data that genuinely comes from up to
/// three different server round trips (`/statistics/ads`, `/leads`,
/// `/coworkers`); five thin methods let `state/dashboard_providers.dart`
/// build one `AsyncNotifier` per method instead.
///
/// **No method here returns a bucketed daily series.** `GET /statistics/ads`
/// only ever returns period totals (contract ruling 7.1) — there is nothing
/// to name a method after. The fixture-only 12-point series
/// (`WorkDashboardChartFixture`, `lib/shared/fixtures/work_seed_data.dart`)
/// has no wire shape at all (see that file's own doc comment), so it is read
/// directly by `widgets/ads_statistics_panel.dart` from the shared fixtures
/// export rather than routed through this repository abstraction — the same
/// judgment call the fixtures file itself documents for
/// `WorkDashboardChartPoint`.
library;

import '../../../api/api.dart';

abstract class DashboardRepository {
  /// `GET /statistics/ads?filterType=` — period-scoped Ads created/sold
  /// totals. The one dashboard figure that genuinely responds to the
  /// time-range selector server-side (ruling 7.1).
  Future<AdsStatistics> fetchAdsStatistics(StatisticsFilter filter);

  /// `GET /statistics/coworkers`-shaped raw events, always the full
  /// unfiltered history (ruling 7.2 — this endpoint ignores any date range).
  /// Backs the Coworker statistics section's "Ads count" column (folded by
  /// [ActivityEvent.coworkerId]/[ActivityEventStage.adCreated], filtered
  /// client-side by the time-range selector in live mode only — see
  /// `state/dashboard_providers.dart`'s `coworkerStatRowsProvider` doc
  /// comment for why the fixture side of that fold stays unfiltered).
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
