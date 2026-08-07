/// A controllable [AgentsRepository] fake for widget tests — no network, no
/// coupling to `agents_fixtures.dart`, so a test hands it exactly the
/// agents/ads it wants to assert against or makes any one of the three
/// methods throw.
///
/// The three error hooks are separate on purpose: the whole point of the
/// repository's three-method split is that an ads failure must not take the
/// profile down with it, and a fake with one shared error flag could not
/// express that case at all.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/data/agents_repository.dart';

class FakeAgentsRepository implements AgentsRepository {
  FakeAgentsRepository({
    List<AgentSummary>? agents,
    this.agent,
    List<Ad>? ads,
    this.agentsError,
    this.agentError,
    this.adsError,
    this.hold,
  }) : agents = agents ?? const [],
       ads = ads ?? const [];

  /// When set, every method awaits this before returning — the only way to
  /// observe a loading state in a widget test. A bare `async` method with no
  /// `await` inside completes on the very next microtask, which `pump()`
  /// drains before it builds the frame, so the loading branch would never be
  /// on screen to assert against.
  final Completer<void>? hold;

  final List<AgentSummary> agents;
  final AgentDetail? agent;
  final List<Ad> ads;

  final Object? agentsError;
  final Object? agentError;
  final Object? adsError;

  int fetchAgentsCallCount = 0;
  int fetchAgentCallCount = 0;
  int fetchAgentAdsCallCount = 0;

  @override
  Future<List<AgentSummary>> fetchAgents() async {
    fetchAgentsCallCount++;
    if (hold != null) await hold!.future;
    if (agentsError != null) throw agentsError!;
    return agents;
  }

  @override
  Future<AgentDetail> fetchAgent(String id) async {
    fetchAgentCallCount++;
    if (hold != null) await hold!.future;
    if (agentError != null) throw agentError!;
    final found = agent;
    if (found == null) {
      // Mirrors FixtureAgentsRepository (and the live 404) rather than
      // returning null, so a test that forgets to supply an agent fails the
      // same way production would.
      throw ApiErrorException(
        statusCode: 404,
        body: const ApiErrorBody(
          code: ApiErrorCode.notFound,
          message: 'Agent not found',
        ),
      );
    }
    return found;
  }

  @override
  Future<List<Ad>> fetchAgentAds(String agentId) async {
    fetchAgentAdsCallCount++;
    if (hold != null) await hold!.future;
    if (adsError != null) throw adsError!;
    return ads;
  }
}
