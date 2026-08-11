/// Data-access seam for the two agent screens — `agents-directory`
/// (SCREENS.md §3.9) and `agent-profile` (§3.10). Two implementations
/// exist: [FixtureAgentsRepository] (bundled §4.3 seed data, no network)
/// and [LiveAgentsRepository] (the real [LaCasaApi]) — see
/// `agents_mode.dart` for which one the app wires up by default.
///
/// **Three methods, three different failure contracts**, deliberately:
///
/// - [fetchAgents] and [fetchAgent] are *fatal* for their screen. The
///   directory with no agents and the profile with no agent have nothing
///   left to render, so both surface [ApiException] and both screens show
///   a full-width error with a retry.
/// - [fetchAgentAds] is *not*. `agent-profile`'s identity block stands on
///   its own; the "Ads List" section below it failing should degrade to a
///   scoped retry card, not blank out the person's name and phone number.
///   That is why it is a separate method rather than one bundled
///   "profile payload" fetch.
///
/// **Why the directory and the profile use different model types**:
/// `GET /agents` returns [AgentSummary] and `GET /agents/:id` returns
/// [AgentDetail] (which adds `dealsClosedCount`). Rather than flatten them
/// into one client-side shape, each method returns exactly what its
/// endpoint gives — the extra field is the whole reason §3.10 can show a
/// closed-deals count and §3.9 cannot.
///
/// **Reviews (SCREENS.md §3.9's `"Review: {rating}/5"` row, and the
/// leave-a-review surface this task adds beyond the spec)**: three more
/// methods, mirroring `/api/agents/:id/reviews`'s three verbs one-for-one.
/// [fetchAgentReviews] is public, like [fetchAgents]/[fetchAgent].
/// [postAgentReview]/[deleteMyAgentReview] require an authenticated caller
/// — see their own doc comments for how that requirement is split between
/// this interface and its callers.
library;

import '../../../api/api.dart';

abstract class AgentsRepository {
  /// Every agent, for the directory list. Server-side this is strictly
  /// `role: "AGENT"` — coworkers never appear (see
  /// `agents_fixtures.dart`'s note, and `apps/api/src/repositories/
  /// agentRepository.js#findAgents`). Returns an empty list rather than
  /// throwing when there are none; the empty *state* is the screen's job.
  Future<List<AgentSummary>> fetchAgents();

  /// One agent, for `agent-profile`. Throws [ApiErrorException] with
  /// `code: notFound` for an unknown id — and also for a *real* coworker
  /// or buyer id, since the endpoint re-filters to agents. The screen
  /// treats both the same way: there is no profile to show.
  Future<AgentDetail> fetchAgent(String id);

  /// This agent's active public listings, for the profile's "Ads List"
  /// grid. Scoped to `stage: "ACTIVE"` by the server regardless of the
  /// agent's true total, which is why this count and
  /// [AgentDetail.adsCount] legitimately disagree — the latter is an
  /// all-time `AD_CREATED` tally that never decreases. See
  /// `agent_ads_grid.dart` for how that difference is surfaced rather
  /// than hidden.
  Future<List<Ad>> fetchAgentAds(String agentId);

  /// `GET /agents/:id/reviews?limit=&cursor=` — public, newest-first, no
  /// auth required. Does **not** throw for an id that isn't a real agent
  /// (or doesn't exist at all) — it just has no rows, mirroring
  /// `apps/api/src/services/reviewService.js#listReviews`, which never
  /// looks the agent up before querying its reviews. [limit] is clamped to
  /// 1..50 (default 20) by both implementations, matching the server's own
  /// clamp; [cursor] is the previous page's [AgentReviewPage.nextCursor].
  Future<AgentReviewPage> fetchAgentReviews(
    String agentId, {
    int? limit,
    String? cursor,
  });

  /// `POST /agents/:id/reviews` — upserts on `(agentId, authorId)`: a
  /// second call from the same author edits their existing review rather
  /// than stacking a new one next to it. Requires an authenticated caller;
  /// **this method does not itself check that one is signed in** — the
  /// screen that opens the review sheet gates it behind
  /// `authSessionProvider.isSignedIn` first (see
  /// `agent_review_sheet.dart`'s doc comment), the same split
  /// `add_coworker_screen.dart` already uses for its own auth-gated form.
  ///
  /// [actingAs] is who the caller is posting as. [LiveAgentsRepository]
  /// ignores it completely — the real server derives the author from the
  /// request's bearer token, the same way every other authenticated call in
  /// this app works, and never receives an explicit author id on the wire.
  /// [FixtureAgentsRepository] has no token to decode, though, so this is
  /// the one piece of context a fixture-mode caller must supply for the
  /// upsert-by-author and self-review checks to mean anything at all —
  /// callers build it from `authSessionProvider`'s signed-in `AuthUser`,
  /// which is available identically in both modes.
  ///
  /// Throws [ApiErrorException] with `code: validation` (400, an
  /// out-of-range rating or an over-long comment), `code: forbidden` (403,
  /// self-review — [agentId] is the caller's own agent id), or
  /// `code: notFound` (404, [agentId] is a real user but not role AGENT) —
  /// both implementations surface the same three codes in the same order
  /// `apps/api/src/services/reviewService.js#createOrUpdateReview` checks
  /// them in.
  Future<AgentReview> postAgentReview(
    String agentId, {
    required int rating,
    String? comment,
    required ReviewAuthor actingAs,
  });

  /// `DELETE /agents/:id/reviews/me` — idempotent, same [actingAs] bridge
  /// as [postAgentReview]. Always succeeds, including for a caller who
  /// never posted a review here, matching the live endpoint's own
  /// always-204 contract.
  Future<void> deleteMyAgentReview(String agentId, {required ReviewAuthor actingAs});
}
