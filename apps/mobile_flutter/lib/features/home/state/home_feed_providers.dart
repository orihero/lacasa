/// Riverpod state for the Home feed screen. Three independent pieces of
/// state, deliberately not merged into one "screen state" provider, so a
/// failure/retry in one (e.g. Top Agents) never touches the others (build
/// spec: "a rail that fails must degrade on its own without taking the
/// screen down with it"):
///
/// - [homeFeedAdsProvider] — the one browse-feed list backing both the
///   Featured Listings rail and the Explore Nearby grid.
/// - [topAgentsProvider] — the Top Agents rail's own independent fetch.
/// - [selectedCategoryChipProvider] — purely local UI state for the
///   decorative category chip row (build spec: selecting a chip "must only
///   update local state — it must not fire a fetch").
///
/// A fourth piece used to live here too: the saved/favourited ad id set.
/// It moved to `lib/shared/state/favourite_ad_ids_provider.dart` once a
/// second feature needed the exact same set a Home listing card's heart
/// already reflects — see that file's doc comment. `FavouriteButton`
/// (`lib/shared/widgets/favourite_button.dart`) reads it from there now;
/// nothing in this file references favourites any more.
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
