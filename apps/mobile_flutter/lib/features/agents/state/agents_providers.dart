/// Riverpod state for the two agent screens. Three providers, matching
/// `agents_repository.dart`'s three methods one-for-one — the split is the
/// failure-isolation boundary that file documents, not an arbitrary one.
///
/// **[agentsDirectoryProvider] is not `.autoDispose`**, unlike the two
/// families below. It backs a *tab root* that a user leaves and returns to
/// constantly (the tab shell keeps each branch's `Navigator` alive, so the
/// screen is not even rebuilt on a tab switch — but an autoDispose provider
/// would still be torn down the moment nothing watched it). Re-fetching the
/// whole agent list every time someone glances at another tab is the one
/// thing this screen should not do. Home's feed provider is plain for the
/// same reason.
///
/// **The two families are `.autoDispose`**, matching
/// `listing_detail_providers.dart` exactly and for the same reason: they are
/// keyed by an id from a pushed route, several can be alive on one back
/// stack at once, and the state should die with the route rather than
/// accumulate one entry per agent the user ever opened.
///
/// **[agentAdsProvider] never becomes the screen's error state.** It can
/// still throw — that is not swallowed here — but `agent_ads_grid.dart`
/// renders its own scoped retry from the `AsyncError`, so a failed ads
/// fetch leaves the identity block above it standing.
///
/// **[agentReviewsProvider] is a fourth, `.autoDispose.family` shape** —
/// [AgentReviewsNotifier], not a plain [FutureProvider], because unlike the
/// three fetch-only providers above it needs to hold onto state across a
/// call a screen makes on it: [AgentReviewsNotifier.loadMore] appends a
/// page rather than replacing one, mirroring
/// `features/my_listings/state/my_listings_providers.dart`'s
/// `MyListingsResultsNotifier` exactly (see that file's doc comment for the
/// full reasoning — `isLoadingMore`/`hasMore`/a failed `loadMore` degrading
/// to "stop spinning, keep what's on screen" rather than blanking the list,
/// all apply here unchanged). Posting/deleting a review does not go through
/// this notifier at all — `agent_reviews_section.dart` calls
/// [AgentsRepository.postAgentReview]/[AgentsRepository.deleteMyAgentReview]
/// directly and then invalidates this provider (and [agentDetailProvider],
/// for the rating row) to reload page one from scratch, which is simpler
/// and just as correct as patching the in-memory list by hand would be.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'agents_repository_provider.dart';

/// The whole agent directory — `agents-directory`'s only fetch.
class AgentsDirectoryNotifier extends AsyncNotifier<List<AgentSummary>> {
  @override
  Future<List<AgentSummary>> build() =>
      ref.read(agentsRepositoryProvider).fetchAgents();
}

final agentsDirectoryProvider =
    AsyncNotifierProvider<AgentsDirectoryNotifier, List<AgentSummary>>(
      AgentsDirectoryNotifier.new,
    );

/// One agent's profile header. Fatal for `agent-profile`: an error here
/// means there is no person to render, and the screen shows a full-width
/// not-found/retry state rather than an empty identity block.
final agentDetailProvider = FutureProvider.autoDispose
    .family<AgentDetail, String>((ref, agentId) {
      return ref.read(agentsRepositoryProvider).fetchAgent(agentId);
    });

/// One agent's active listings, for the profile's "Ads List" grid.
final agentAdsProvider = FutureProvider.autoDispose.family<List<Ad>, String>((
  ref,
  agentId,
) {
  return ref.read(agentsRepositoryProvider).fetchAgentAds(agentId);
});

/// The number of reviews requested per real `GET /agents/:id/reviews`
/// page — both the first [AgentReviewsNotifier.build] fetch and every
/// [AgentReviewsNotifier.loadMore] call send this as `limit`. Same value
/// `my_listings_providers.dart`'s `myListingsPageSize` picks, for the same
/// reason: enough for the infinite-scroll feel without a large over-fetch
/// on a section most profiles will only ever partially open.
const int agentReviewsPageSize = 10;

/// [agentReviewsProvider]'s value — the reviews loaded so far (across
/// however many pages [AgentReviewsNotifier.loadMore] has fetched) plus the
/// cursor for the next one. Same shape as `my_listings_providers.dart`'s
/// `MyListingsPageState`, for the same reasons documented there.
class AgentReviewsPageState {
  const AgentReviewsPageState({
    required this.reviews,
    required this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<AgentReview> reviews;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  AgentReviewsPageState copyWith({
    List<AgentReview>? reviews,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) {
    return AgentReviewsPageState(
      reviews: reviews ?? this.reviews,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AgentReviewsNotifier extends AsyncNotifier<AgentReviewsPageState> {
  AgentReviewsNotifier(this.agentId);

  final String agentId;

  @override
  Future<AgentReviewsPageState> build() async {
    final page = await ref
        .read(agentsRepositoryProvider)
        .fetchAgentReviews(agentId, limit: agentReviewsPageSize);
    return AgentReviewsPageState(
      reviews: page.reviews,
      nextCursor: page.nextCursor,
    );
  }

  /// Fetches the next page and appends it. A no-op if there's no current
  /// data, no next page, or a fetch is already in flight — see
  /// `MyListingsResultsNotifier.loadMore`'s identical doc comment.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref
          .read(agentsRepositoryProvider)
          .fetchAgentReviews(
            agentId,
            limit: agentReviewsPageSize,
            cursor: current.nextCursor,
          );
      state = AsyncData(
        AgentReviewsPageState(
          reviews: [...current.reviews, ...page.reviews],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      // Same degrade as MyListingsResultsNotifier.loadMore: keep the reviews
      // already on screen, just stop spinning. `nextCursor` is left as-is,
      // so trying again is a normal retry rather than a dead end.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final agentReviewsProvider = AsyncNotifierProvider.autoDispose
    .family<AgentReviewsNotifier, AgentReviewsPageState, String>(
      AgentReviewsNotifier.new,
    );
