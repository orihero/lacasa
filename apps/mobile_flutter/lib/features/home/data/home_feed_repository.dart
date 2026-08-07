/// Data-access seam for the Home feed screen. Two implementations exist:
/// [FixtureHomeFeedRepository] (bundled SCREENS.md §4 seed data, no
/// network) and [LiveHomeFeedRepository] (the real [LaCasaApi]) — see
/// `home_feed_mode.dart` for which one the app wires up by default and how
/// to switch.
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws (`lib/api/api_exception.dart`) so widgets only need to know about
/// that one exception hierarchy regardless of which implementation is
/// active.
///
/// This interface used to carry three more methods for the saved/favourited
/// ad id set (`fetchInitialSavedAdIds`/`saveAd`/`unsaveAd`). They moved to
/// `lib/shared/state/favourite_ad_ids_repository.dart` once a second
/// feature needed the exact same favourited state Home's own cards
/// reflect — see that file's doc comment for why a per-feature copy was
/// rejected.
library;

import '../../../api/api.dart';

abstract class HomeFeedRepository {
  /// The public browse feed backing both the Featured Listings rail and the
  /// Explore Nearby grid — one list, two views of it (build spec, "On the
  /// source data for rails 5 and 8"). Already scoped to active listings by
  /// the server (or, for the fixture, by construction).
  Future<List<Ad>> fetchFeed();

  /// Top 5 agents by [AgentSummary.adsCount], descending.
  Future<List<AgentSummary>> fetchTopAgents();
}
