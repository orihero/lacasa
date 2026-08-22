/// Data-access seam for `listing-detail` (SCREENS.md §3.7). Two
/// implementations exist: [FixtureListingDetailRepository] (bundled
/// SCREENS.md §4 seed data, no network) and [LiveListingDetailRepository]
/// (the real [LaCasaApi]) — see `listing_detail_mode.dart` for which one the
/// screen wires up by default and how to switch.
///
/// Split into two methods, deliberately not merged into one "screen data"
/// fetch, because they fail independently and differently:
/// - [fetchAd] failing is fatal to the whole screen — there is nothing to
///   show without the ad itself, so it surfaces the same [ApiException]
///   types [LaCasaApi] throws and the screen renders a full retry state.
/// - [fetchAgent] failing (a deleted/reassigned agent, or the agent id
///   simply not resolving) must NOT blank the rest of the listing — the
///   agent block alone degrades to an "unavailable" state. See its own doc
///   comment for why this method never throws.
library;

import '../../../api/api.dart';

abstract class ListingDetailRepository {
  /// `GET /ads/:id` (or the fixture equivalent). Throws
  /// [ApiErrorException] with `code: notFound` for a missing/invalid id —
  /// the caller (the AsyncNotifier in `state/listing_detail_providers.dart`)
  /// lets this propagate so the screen shows its terminal error state.
  Future<Ad> fetchAd(String id);

  /// `GET /agents/:id` (or the fixture equivalent) for the listing's
  /// [Ad.agentId]. Never throws — a 404 (a deleted/reassigned agent, or a
  /// coworker id that `GET /agents/:id` legitimately 404s on per
  /// `agents_resource.dart`'s own doc comment) or any other failure
  /// degrades to `null` so the agent block alone renders an "unavailable"
  /// state instead of taking the whole listing down with it.
  Future<AgentDetail?> fetchAgent(String agentId);
}
