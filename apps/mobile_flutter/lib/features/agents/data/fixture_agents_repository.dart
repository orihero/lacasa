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
///
/// **Reviews are real, in-memory, for the lifetime of this instance** —
/// same choice `fixture_coworkers_repository.dart` makes for
/// create/update/delete, and for the same reason: a "post a review" button
/// that silently no-ops would make the leave-a-review surface impossible
/// to exercise with no network at all. [postAgentReview]/
/// [deleteMyAgentReview] mutate a private `agentId -> reviews` map seeded
/// from [fixtureAgentReviewSeed], and every mutation recomputes that
/// agent's `ratingAverage`/`ratingCount` the same way
/// `apps/api/src/services/agentService.js#ratingFor` does (average rounded
/// to one decimal, `null`/`0` for zero reviews) — so a posted review shows
/// up in the star row immediately, not just in the reviews list below it.
///
/// **Self-review and upsert-by-author both need to know who is asking**,
/// which this repository — unlike the live endpoint — has no auth token to
/// derive on its own. See [AgentsRepository.postAgentReview]'s doc comment
/// for why that context arrives as the caller-supplied `actingAs` parameter
/// instead.
library;

import '../../../api/api.dart';
import 'agents_fixtures.dart';
import 'agents_repository.dart';

class FixtureAgentsRepository implements AgentsRepository {
  FixtureAgentsRepository()
    : _details = {for (final a in fixtureAgentDetails) a.id: a},
      _reviews = {
        for (final entry in fixtureAgentReviewSeed.entries)
          entry.key: List.of(entry.value),
      } {
    // Seeded ratings are derived, not hand-typed — see this file's doc
    // comment — so every agent that starts with reviews also starts with a
    // rating consistent with them, computed by the exact same code path a
    // runtime mutation uses.
    for (final agentId in _reviews.keys) {
      _recomputeRating(agentId);
    }
  }

  final Map<String, AgentDetail> _details;
  final Map<String, List<AgentReview>> _reviews;
  int _nextReviewId = 0;

  @override
  Future<List<AgentSummary>> fetchAgents() async =>
      _details.values.map(_toSummary).toList(growable: false);

  @override
  Future<AgentDetail> fetchAgent(String id) async {
    final agent = _details[id];
    if (agent != null) return agent;
    throw _notFound;
  }

  @override
  Future<List<Ad>> fetchAgentAds(String agentId) async =>
      fixtureAgentAds(agentId);

  @override
  Future<AgentReviewPage> fetchAgentReviews(
    String agentId, {
    int? limit,
    String? cursor,
  }) async {
    // Same clamp the server applies (`reviewService.js`'s DEFAULT_LIMIT/
    // MAX_LIMIT) — a fixture whose paging behaves differently would make a
    // paging bug impossible to catch offline.
    final take = (limit ?? 20).clamp(1, 50);
    final all = _reviews[agentId] ?? const <AgentReview>[];

    var start = 0;
    if (cursor != null) {
      final at = all.indexWhere((r) => r.id == cursor);
      // An unrecognized cursor (a stale one, or a review that was since
      // deleted) has nothing sensible to resume from — treat it as "no more
      // pages" rather than silently restarting at page one, which would
      // repeat rows the caller has already seen.
      start = at == -1 ? all.length : at + 1;
    }

    final window = all.skip(start).take(take + 1).toList();
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
    // Same check order as `reviewService.js#createOrUpdateReview`: cheapest
    // first, database-shaped lookup last.
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
    if (!_details.containsKey(agentId)) throw _notFound;

    final list = _reviews.putIfAbsent(agentId, () => []);
    final existingIndex = list.indexWhere((r) => r.author.id == actingAs.id);

    final AgentReview saved;
    if (existingIndex != -1) {
      // Upsert: same id/createdAt, new rating/comment — mirrors
      // `agentRepository.js#upsertReview`'s Prisma `update: { rating,
      // comment }`, which never touches `createdAt`.
      final existing = list[existingIndex];
      saved = AgentReview(
        id: existing.id,
        rating: rating,
        comment: comment,
        createdAt: existing.createdAt,
        author: actingAs,
      );
      list[existingIndex] = saved;
    } else {
      saved = AgentReview(
        id: 'fixture-review-${_nextReviewId++}',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now().toUtc(),
        author: actingAs,
      );
      // Newest-first, matching the live endpoint's `createdAt desc` order.
      list.insert(0, saved);
    }

    _recomputeRating(agentId);
    return saved;
  }

  @override
  Future<void> deleteMyAgentReview(
    String agentId, {
    required ReviewAuthor actingAs,
  }) async {
    // Always succeeds, including for a caller with nothing to delete —
    // matching `deleteReview`'s `deleteMany` (never a 404), and
    // `_reviews[agentId]` may not even exist yet if this agent has never
    // had a review posted at all.
    _reviews[agentId]?.removeWhere((r) => r.author.id == actingAs.id);
    _recomputeRating(agentId);
  }

  /// Recomputes `ratingAverage`/`ratingCount` for one agent from
  /// [_reviews] and writes the result back into [_details] — the fixture
  /// equivalent of `agentService.js#ratingFor` reading a fresh `groupBy`
  /// aggregate on every request. `average == null` for zero reviews, never
  /// `0`/`0.0` — the same rule [AgentSummary.ratingAverage]'s doc comment
  /// requires of the live server.
  void _recomputeRating(String agentId) {
    final current = _details[agentId];
    if (current == null) return; // Not a real fixture agent; nothing to update.

    final list = _reviews[agentId] ?? const <AgentReview>[];
    if (list.isEmpty) {
      _details[agentId] = _withRating(current, average: null, count: 0);
      return;
    }
    final sum = list.fold<int>(0, (total, r) => total + r.rating);
    final rounded = (sum / list.length * 10).round() / 10;
    _details[agentId] = _withRating(current, average: rounded, count: list.length);
  }

  AgentDetail _withRating(
    AgentDetail agent, {
    required double? average,
    required int count,
  }) {
    return AgentDetail(
      id: agent.id,
      fullName: agent.fullName,
      email: agent.email,
      phoneNumber: agent.phoneNumber,
      avatar: agent.avatar,
      adsCount: agent.adsCount,
      dealsClosedCount: agent.dealsClosedCount,
      address: agent.address,
      ratingAverage: average,
      ratingCount: count,
    );
  }

  AgentSummary _toSummary(AgentDetail agent) {
    return AgentSummary(
      id: agent.id,
      fullName: agent.fullName,
      email: agent.email,
      phoneNumber: agent.phoneNumber,
      avatar: agent.avatar,
      adsCount: agent.adsCount,
      address: agent.address,
      ratingAverage: agent.ratingAverage,
      ratingCount: agent.ratingCount,
    );
  }

  static final ApiErrorException _notFound = ApiErrorException(
    statusCode: 404,
    body: const ApiErrorBody(
      code: ApiErrorCode.notFound,
      message: 'Agent not found',
    ),
  );
}
