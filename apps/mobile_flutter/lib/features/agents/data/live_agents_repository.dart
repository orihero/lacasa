/// The real, network-backed [AgentsRepository] — a thin adapter over
/// [LaCasaApi] that adds no wire shapes of its own, the same rule
/// `live_home_feed_repository.dart` and `live_search_repository.dart`
/// follow.
///
/// Note [fetchAgentAds] goes through `AdsResource`, not `AgentsResource`:
/// `GET /agents/:id` carries counts but no listings, and `GET /ads` already
/// takes an `agentId` scope (see `ads_resource.dart`). One endpoint per
/// concern, no new server work needed for this screen.
library;

import '../../../api/api.dart';
import 'agents_repository.dart';

class LiveAgentsRepository implements AgentsRepository {
  const LiveAgentsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<AgentSummary>> fetchAgents() => _api.agents.list();

  @override
  Future<AgentDetail> fetchAgent(String id) => _api.agents.getById(id);

  @override
  Future<List<Ad>> fetchAgentAds(String agentId) =>
      _api.ads.list(agentId: agentId);

  @override
  Future<AgentReviewPage> fetchAgentReviews(
    String agentId, {
    int? limit,
    String? cursor,
  }) => _api.agents.listReviews(agentId, limit: limit, cursor: cursor);

  @override
  Future<AgentReview> postAgentReview(
    String agentId, {
    required int rating,
    String? comment,
    // Ignored — see AgentsRepository.postAgentReview's doc comment. The
    // live endpoint authenticates via the request's bearer token, exactly
    // like every other authenticated call this client makes.
    required ReviewAuthor actingAs,
  }) => _api.agents.postReview(agentId, rating: rating, comment: comment);

  @override
  Future<void> deleteMyAgentReview(String agentId, {required ReviewAuthor actingAs}) =>
      _api.agents.deleteMyReview(agentId);
}
