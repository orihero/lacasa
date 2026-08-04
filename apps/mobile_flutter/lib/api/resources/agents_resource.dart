/// `/api/agents` — the listing-detail agent card and the agent-profile
/// screen. Both endpoints are public, no auth. `adsCount` on both is an
/// all-time `AD_CREATED` event tally, not a live count of the agent's
/// current listings (see `AgentSummary`/`AgentDetail`'s doc comments).
library;

import '../api_client.dart';
import '../models/agent.dart';

class AgentsResource {
  final ApiClient _client;

  const AgentsResource(this._client);

  /// `GET /api/agents`.
  Future<List<AgentSummary>> list() async {
    final json = await _client.request(method: 'GET', path: '/agents');
    return (json as List<dynamic>)
        .map((e) => AgentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/agents/:id`. Internally re-filtered to `role: "AGENT"` on
  /// the server — a coworker's or buyer's id 404s here even though it's a
  /// real user row. Throws [ApiErrorException] with `code: notFound` (404).
  Future<AgentDetail> getById(String id) async {
    final json = await _client.request(method: 'GET', path: '/agents/$id');
    return AgentDetail.fromJson(json as Map<String, dynamic>);
  }
}
