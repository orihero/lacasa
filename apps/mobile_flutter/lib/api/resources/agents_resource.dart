/// `/api/agents` — the listing-detail agent card and the agent-profile
/// screen. Both endpoints are public, no auth. `adsCount` on both is an
/// all-time `AD_CREATED` event tally, not a live count of the agent's
/// current listings (see `AgentSummary`/`AgentDetail`'s doc comments).
///
/// Also `/api/agents/:id/reviews` (SCREENS.md §3.9) — [listReviews] is
/// public like the card itself; [postReview]/[deleteMyReview] require auth.
library;

import '../api_client.dart';
import '../models/agent.dart';
import '../models/agent_review.dart';

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

  /// `GET /agents/:id/reviews?limit=&cursor=` — public, newest-first.
  /// [limit] is clamped server-side to 1..50 (default 20); [cursor] is the
  /// previous page's [AgentReviewPage.nextCursor], omit for the first page.
  Future<AgentReviewPage> listReviews(
    String agentId, {
    int? limit,
    String? cursor,
  }) async {
    final json = await _client.request(
      method: 'GET',
      path: '/agents/$agentId/reviews',
      query: {'limit': limit, 'cursor': cursor},
    );
    return AgentReviewPage.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /agents/:id/reviews` — any authenticated caller. Upserts on
  /// `(agentId, authorId)`: a repeat call from the same caller edits their
  /// existing review rather than stacking a second one, and still answers
  /// `200` (not `201`) either way. [rating] must be an integer 1..5; this
  /// client does not pre-validate it. Throws [ApiErrorException] with
  /// `code: validation` (400, out-of-range rating or an over-long
  /// [comment]), `code: forbidden` (403, self-review — [agentId] is the
  /// caller's own agent id), or `code: notFound` (404, [agentId] is a real
  /// user but not role AGENT).
  Future<AgentReview> postReview(
    String agentId, {
    required int rating,
    String? comment,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/agents/$agentId/reviews',
      body: {'rating': rating, 'comment': ?comment},
    );
    return AgentReview.fromJson(json as Map<String, dynamic>);
  }

  /// `DELETE /agents/:id/reviews/me` — any authenticated caller, idempotent:
  /// answers `204` whether or not the caller ever posted a review here.
  Future<void> deleteMyReview(String agentId) async {
    await _client.request(
      method: 'DELETE',
      path: '/agents/$agentId/reviews/me',
    );
  }
}
