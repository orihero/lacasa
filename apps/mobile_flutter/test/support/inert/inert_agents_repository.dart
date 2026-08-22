/// A deliberately empty [AgentsRepository] for tests that mount the agents
/// providers without being *about* agents.
///
/// **Why this exists.** `lib/api/app_mode.dart` used to force a bundled
/// `FixtureAgentsRepository` under `flutter test`. The fixture repositories
/// are gone, so `agentsRepositoryProvider` now unconditionally builds
/// `LiveAgentsRepository` around `LaCasaApi.create()`. Any widget test that
/// builds the real router — which mounts a shell touching nearly every
/// repository — therefore fires real HTTP out of the test process the moment
/// an agents surface is reached. That does not fail cleanly; it hangs, and
/// the test dies on `pumpAndSettle timed out` with nothing pointing at the
/// cause. Overriding the provider with this class is what keeps that from
/// happening.
///
/// **Everything here answers with the emptiest value its signature allows,
/// and nothing throws.** No agents, no ads, no reviews, and the write paths
/// succeed silently. That is a deliberate choice, not an unfinished one: an
/// inert repository can never be the thing a test accidentally asserts
/// against, so a passing assertion always traces back to a fake the test
/// supplied on purpose.
///
/// Two members cannot express "empty" and so return the smallest valid
/// instance instead — [fetchAgent] hands back an [AgentDetail] with blank
/// strings and zero counts, and [postAgentReview] an [AgentReview] with a
/// zero rating and an epoch timestamp. Neither is meant to be read; a test
/// that cares what a profile or a posted review contains wants real
/// behaviour, which is the next paragraph's job.
///
/// **A test that wants real behaviour must not extend or subclass this.**
/// Override `agentsRepositoryProvider` with a purpose-built fake from
/// `test/features/agents/support/` instead — those record their calls and
/// return data the test chose, which is exactly what this class refuses to
/// do.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/data/agents_repository.dart';

/// See this library's doc comment. Field-free, so it is `const`-constructible
/// and a single instance can be shared by every override that needs one.
class InertAgentsRepository implements AgentsRepository {
  const InertAgentsRepository();

  @override
  Future<List<AgentSummary>> fetchAgents() async => const <AgentSummary>[];

  @override
  Future<AgentDetail> fetchAgent(String id) async => const AgentDetail(
    id: '',
    fullName: '',
    email: '',
    phoneNumber: null,
    avatar: null,
    adsCount: 0,
    dealsClosedCount: 0,
  );

  @override
  Future<List<Ad>> fetchAgentAds(String agentId) async => const <Ad>[];

  @override
  Future<AgentReviewPage> fetchAgentReviews(
    String agentId, {
    int? limit,
    String? cursor,
  }) async => const AgentReviewPage(reviews: <AgentReview>[], nextCursor: null);

  @override
  Future<AgentReview> postAgentReview(
    String agentId, {
    required int rating,
    String? comment,
    required ReviewAuthor actingAs,
  }) async => AgentReview(
    id: '',
    rating: 0,
    comment: null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    author: actingAs,
  );

  @override
  Future<void> deleteMyAgentReview(
    String agentId, {
    required ReviewAuthor actingAs,
  }) async {}
}
