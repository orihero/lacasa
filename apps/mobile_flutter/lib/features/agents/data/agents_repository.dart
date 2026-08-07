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
}
