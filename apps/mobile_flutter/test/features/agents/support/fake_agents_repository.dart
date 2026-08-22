/// A controllable [AgentsRepository] fake for widget tests — no network, no
/// coupling to `agents_fixtures.dart`, so a test hands it exactly the
/// agents/ads/reviews it wants to assert against or makes any one of the six
/// methods throw.
///
/// The error hooks are separate per method on purpose: the whole point of
/// the repository's method split is that (for instance) an ads failure must
/// not take the profile down with it, and a fake with one shared error flag
/// could not express that case at all.
///
/// **Reviews are a flat, mutable, single-agent list — unlike
/// [FixtureAgentsRepository]'s `agentId -> reviews` map.** Every test in
/// `agent_reviews_section_test.dart` exercises exactly one agent per
/// `pumpSection` call (the `agentId` parameter just labels the [AgentDetail]
/// handed to the widget; it is never consulted here), so partitioning by id
/// would only add ceremony no test needs. [postAgentReview]/
/// [deleteMyAgentReview] mutate [_reviews] in place — upsert-by-author and
/// newest-first insertion, mirroring [FixtureAgentsRepository] — so the full
/// leave -> edit -> delete round trip is observable through
/// [fetchAgentReviews] afterwards, the same way a real backend would show
/// its own write back on the next read.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/data/agents_repository.dart';

class FakeAgentsRepository implements AgentsRepository {
  FakeAgentsRepository({
    List<AgentSummary>? agents,
    this.agent,
    List<Ad>? ads,
    List<AgentReview>? reviews,
    this.agentsError,
    this.agentError,
    this.adsError,
    this.reviewsError,
    this.postReviewError,
    this.deleteReviewError,
    this.hold,
  }) : agents = agents ?? const [],
       ads = ads ?? const [],
       _reviews = List.of(reviews ?? const []);

  /// When set, every method awaits this before returning — the only way to
  /// observe a loading state in a widget test. A bare `async` method with no
  /// `await` inside completes on the very next microtask, which `pump()`
  /// drains before it builds the frame, so the loading branch would never be
  /// on screen to assert against.
  final Completer<void>? hold;

  final List<AgentSummary> agents;
  final AgentDetail? agent;
  final List<Ad> ads;

  /// Seeded from the constructor's `reviews:` list, newest-first like the
  /// real endpoint, and mutated in place by [postAgentReview]/
  /// [deleteMyAgentReview]. Not exposed directly — a test asserts against
  /// [fetchAgentReviews]'s output (the same seam the widget under test
  /// reads through), not this field.
  final List<AgentReview> _reviews;

  final Object? agentsError;
  final Object? agentError;
  final Object? adsError;
  final Object? reviewsError;
  final Object? postReviewError;
  final Object? deleteReviewError;

  int fetchAgentsCallCount = 0;
  int fetchAgentCallCount = 0;
  int fetchAgentAdsCallCount = 0;
  int fetchAgentReviewsCallCount = 0;
  int postAgentReviewCallCount = 0;
  int deleteMyAgentReviewCallCount = 0;

  int _nextReviewId = 0;

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

  @override
  Future<AgentReviewPage> fetchAgentReviews(
    String agentId, {
    int? limit,
    String? cursor,
  }) async {
    fetchAgentReviewsCallCount++;
    if (hold != null) await hold!.future;
    if (reviewsError != null) throw reviewsError!;

    // Same clamp and "one-past-the-page" cursor trick as
    // FixtureAgentsRepository.fetchAgentReviews — a fake whose paging
    // behaves differently would make a paging bug (e.g. `agentReviewsPageSize`
    // drifting out of sync with `AgentReviewsNotifier`) impossible to catch
    // in a widget test.
    final take = (limit ?? 20).clamp(1, 50);

    var start = 0;
    if (cursor != null) {
      final at = _reviews.indexWhere((r) => r.id == cursor);
      start = at == -1 ? _reviews.length : at + 1;
    }

    final window = _reviews.skip(start).take(take + 1).toList();
    final hasMore = window.length > take;
    final page = hasMore ? window.sublist(0, take) : window;
    return AgentReviewPage(
      reviews: page,
      nextCursor: hasMore ? page.last.id : null,
    );
  }

  @override
  Future<AgentReview> postAgentReview(
    String agentId, {
    required int rating,
    String? comment,
    required ReviewAuthor actingAs,
  }) async {
    postAgentReviewCallCount++;
    if (hold != null) await hold!.future;
    // An injected error takes priority over this fake's own business-rule
    // checks below — it exists specifically so a test can reach failure
    // branches (`forbidden`/`notFound`/an arbitrary `validation` message)
    // that this fake's own happy-path logic has no organic way to produce,
    // like a coworker id that happens not to be a real agent.
    if (postReviewError != null) throw postReviewError!;

    // Same check order as `AgentsRepository.postAgentReview`'s doc comment
    // and `FixtureAgentsRepository`: cheapest first.
    if (rating < 1 || rating > 5) {
      throw ApiErrorException(
        statusCode: 400,
        body: const ApiErrorBody(
          code: ApiErrorCode.validation,
          message: 'Rating must be between 1 and 5',
        ),
      );
    }
    if (agentId == actingAs.id) {
      throw ApiErrorException(
        statusCode: 403,
        body: const ApiErrorBody(
          code: ApiErrorCode.forbidden,
          message: 'You may not review yourself',
        ),
      );
    }

    final existingIndex = _reviews.indexWhere((r) => r.author.id == actingAs.id);
    final AgentReview saved;
    if (existingIndex != -1) {
      // Upsert: same id/createdAt, new rating/comment — mirrors
      // FixtureAgentsRepository's own upsert, which in turn mirrors
      // `agentRepository.js#upsertReview`'s Prisma `update`.
      final existing = _reviews[existingIndex];
      saved = AgentReview(
        id: existing.id,
        rating: rating,
        comment: comment,
        createdAt: existing.createdAt,
        author: actingAs,
      );
      _reviews[existingIndex] = saved;
    } else {
      saved = AgentReview(
        id: 'fake-review-${_nextReviewId++}',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now().toUtc(),
        author: actingAs,
      );
      // Newest-first, matching the live endpoint's `createdAt desc` order —
      // so a freshly-posted review is the one a test sees at the top of the
      // reloaded list, same as `FixtureAgentsRepository`.
      _reviews.insert(0, saved);
    }
    return saved;
  }

  @override
  Future<void> deleteMyAgentReview(
    String agentId, {
    required ReviewAuthor actingAs,
  }) async {
    deleteMyAgentReviewCallCount++;
    if (hold != null) await hold!.future;
    if (deleteReviewError != null) throw deleteReviewError!;
    // Always succeeds, including for a caller with nothing to delete —
    // matching the live endpoint's always-204 `deleteMany` contract, which
    // `AgentsRepository.deleteMyAgentReview`'s doc comment calls out
    // explicitly.
    _reviews.removeWhere((r) => r.author.id == actingAs.id);
  }
}
