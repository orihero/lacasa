/// Offline stand-in for [AgentsRepository], backed by
/// `agents_fixtures.dart`'s SCREENS.md §4.3 seed data. No network, no
/// [LaCasaApi] dependency — this is what both agent screens render from by
/// default (see `agents_mode.dart`), which is how the build's "must render
/// sensibly with NO network available" rule is met.
///
/// **The unknown-id case throws rather than returning null**, and it throws
/// the *same* [ApiErrorException] shape (`notFound`, 404) the live endpoint
/// would. A fixture whose failure mode differs from production's is a
/// fixture that hides the bug it was supposed to let you find — the
/// profile screen's not-found branch is exercised identically either way.
library;

import '../../../api/api.dart';
import 'agents_fixtures.dart';
import 'agents_repository.dart';

class FixtureAgentsRepository implements AgentsRepository {
  const FixtureAgentsRepository();

  @override
  Future<List<AgentSummary>> fetchAgents() async => fixtureAgents;

  @override
  Future<AgentDetail> fetchAgent(String id) async {
    final agent = fixtureAgentById(id);
    if (agent != null) return agent;

    throw ApiErrorException(
      statusCode: 404,
      body: const ApiErrorBody(
        code: ApiErrorCode.notFound,
        message: 'Agent not found',
      ),
    );
  }

  @override
  Future<List<Ad>> fetchAgentAds(String agentId) async =>
      fixtureAgentAds(agentId);
}
