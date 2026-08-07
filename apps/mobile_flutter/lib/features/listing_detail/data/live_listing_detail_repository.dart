/// The real, network-backed [ListingDetailRepository] — a thin adapter over
/// [LaCasaApi], adding no wire shapes of its own.
///
/// The one piece of behaviour that lives here rather than in the API layer
/// is [fetchAgent]'s swallow. `AgentsResource.getById` throws for a missing
/// agent, exactly as it should; deciding that a listing-detail screen would
/// rather show an "unavailable" agent block than no listing at all is this
/// screen's policy, not the API client's, so it is applied at this seam.
library;

import '../../../api/api.dart';
import 'listing_detail_repository.dart';

class LiveListingDetailRepository implements ListingDetailRepository {
  const LiveListingDetailRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<Ad> fetchAd(String id) => _api.ads.getById(id);

  @override
  Future<AgentDetail?> fetchAgent(String agentId) async {
    // An ad whose `agentId` is blank has nobody to fetch — skip the round
    // trip rather than asking the server about `/agents/`.
    if (agentId.isEmpty) return null;
    try {
      return await _api.agents.getById(agentId);
    } on ApiException {
      // Every typed failure degrades identically: a 404 (deleted agent, or
      // a coworker id `GET /agents/:id` legitimately refuses), a 5xx, or no
      // network at all. See this method's contract in
      // `listing_detail_repository.dart` for why none of them are fatal.
      return null;
    }
  }
}
