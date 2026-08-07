/// Riverpod state for the Home feed screen. Four independent pieces of
/// state, deliberately not merged into one "screen state" provider, so a
/// failure/retry in one (e.g. Top Agents) never touches the others (build
/// spec: "a rail that fails must degrade on its own without taking the
/// screen down with it"):
///
/// - [homeFeedAdsProvider] — the one browse-feed list backing both the
///   Featured Listings rail and the Explore Nearby grid.
/// - [topAgentsProvider] — the Top Agents rail's own independent fetch.
/// - [favouriteAdIdsProvider] — the saved/favourited ad id set, with
///   optimistic toggle + revert-on-failure.
/// - [selectedCategoryChipProvider] — purely local UI state for the
///   decorative category chip row (build spec: selecting a chip "must only
///   update local state — it must not fire a fetch").
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'home_feed_repository_provider.dart';

class HomeFeedAdsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() => ref.read(homeFeedRepositoryProvider).fetchFeed();
}

final homeFeedAdsProvider =
    AsyncNotifierProvider<HomeFeedAdsNotifier, List<Ad>>(
      HomeFeedAdsNotifier.new,
    );

class TopAgentsNotifier extends AsyncNotifier<List<AgentSummary>> {
  @override
  Future<List<AgentSummary>> build() =>
      ref.read(homeFeedRepositoryProvider).fetchTopAgents();
}

final topAgentsProvider =
    AsyncNotifierProvider<TopAgentsNotifier, List<AgentSummary>>(
      TopAgentsNotifier.new,
    );

/// Optimistic favourite/save toggle (build spec, "Favourite / heart control
/// — Behavior"): flips [state] immediately, then confirms with the
/// repository; a failure reverts the flip and rethrows so the caller (a
/// widget with access to a [BuildContext]) can surface a toast.
class FavouriteAdIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Seed asynchronously: start empty (unfavourited) rather than blocking
    // the whole screen's first frame on this secondary fetch, then fill in
    // once it resolves. `fetchInitialSavedAdIds` itself never throws (see
    // its doc comment), so no error handling is needed here.
    Future(() async {
      final ids = await ref
          .read(homeFeedRepositoryProvider)
          .fetchInitialSavedAdIds();
      // Guard against a state write after this provider was disposed
      // (e.g. the screen was popped while the seed fetch was in flight).
      if (ref.mounted) state = ids;
    });
    return const <String>{};
  }

  Future<void> toggle(String adId) async {
    final repository = ref.read(homeFeedRepositoryProvider);
    final wasFavourite = state.contains(adId);
    state = wasFavourite ? ({...state}..remove(adId)) : ({...state}..add(adId));

    try {
      if (wasFavourite) {
        await repository.unsaveAd(adId);
      } else {
        await repository.saveAd(adId);
      }
    } catch (_) {
      // Revert the optimistic flip and let the caller show a toast.
      state = wasFavourite
          ? ({...state}..add(adId))
          : ({...state}..remove(adId));
      rethrow;
    }
  }
}

final favouriteAdIdsProvider =
    NotifierProvider<FavouriteAdIdsNotifier, Set<String>>(
      FavouriteAdIdsNotifier.new,
    );

/// Local-only selection index into the category chip row. "All" (index 0)
/// is selected by default. Never drives a fetch — see this file's doc
/// comment.
class SelectedCategoryChipNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedCategoryChipProvider =
    NotifierProvider<SelectedCategoryChipNotifier, int>(
      SelectedCategoryChipNotifier.new,
    );
