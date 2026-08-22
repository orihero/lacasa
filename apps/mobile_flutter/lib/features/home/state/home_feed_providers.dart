/// Riverpod state for the Home feed screen. Three independent pieces of
/// state, deliberately not merged into one "screen state" provider, so a
/// failure/retry in one (e.g. Top Agents) never touches the others (build
/// spec: "a rail that fails must degrade on its own without taking the
/// screen down with it"):
///
/// - [homeFeedAdsProvider] — the one browse-feed list backing both the
///   Featured Listings rail and the Explore Nearby grid.
/// - [topAgentsProvider] — the Top Agents rail's own independent fetch.
/// - [selectedCategoryChipProvider] — which category chip is active. This
///   one *does* drive [homeFeedAdsProvider]'s fetch: a category chip
///   filters the Home feed where it stands, on Home, rather than handing
///   its filter to the Search tab. See `widgets/category_chip_row.dart`.
///
/// A fourth piece used to live here too: the saved/favourited ad id set.
/// It moved to `lib/shared/state/favourite_ad_ids_provider.dart` once a
/// second feature needed the exact same set a Home listing card's heart
/// already reflects — see that file's doc comment. `FavouriteButton`
/// (`lib/shared/widgets/favourite_button.dart`) reads it from there now;
/// nothing in this file references favourites any more.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'home_feed_repository_provider.dart';

class HomeFeedAdsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() {
    // `.select(type)`, not the whole selection: Apartment and House both
    // map to `AdType.residential` (see `widgets/category_chip_row.dart` on
    // why, and what it costs), so moving the lit chip between those two
    // must not throw the feed back to shimmer and re-request an identical
    // list. Watching the axis the request is actually built from is what
    // makes that a no-op.
    final type = ref.watch(selectedCategoryChipProvider.select((s) => s.type));
    return ref
        .read(homeFeedRepositoryProvider)
        .fetchFeed(filters: AdFilters(type: type));
  }
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

/// Which category chip is active, as both halves of what a tap decides:
/// the [index] the row lights, and the [type] the feed is fetched with.
///
/// They are stored together rather than derived from one another because
/// neither direction is a function: two indices (Apartment and House)
/// share one [AdType], so an index cannot be recovered from a
/// type, and the label/icon/type table that maps the other way is the
/// widget's (`widgets/category_chip_row.dart`), not this layer's. Keeping
/// the pair means the row never has to guess which chip a filter came
/// from.
@immutable
class HomeCategorySelection {
  const HomeCategorySelection({required this.index, required this.type});

  /// "All" — index 0, no constraint. The feed's initial state.
  static const all = HomeCategorySelection(index: 0, type: null);

  final int index;

  /// `AdFilters.type` for this chip; `null` for "All", which applies no
  /// constraint at all.
  final AdType? type;

  @override
  bool operator ==(Object other) =>
      other is HomeCategorySelection &&
      other.index == index &&
      other.type == type;

  @override
  int get hashCode => Object.hash(index, type);
}

/// The active category chip. Unlike the plain index this used to hold, it
/// *is* a fetch input: [HomeFeedAdsNotifier] watches its [type] and
/// re-requests the feed, so Top Districts (derived from the same list) and
/// both listing rails follow the chip without leaving Home.
class SelectedCategoryChipNotifier extends Notifier<HomeCategorySelection> {
  @override
  HomeCategorySelection build() => HomeCategorySelection.all;

  void select(int index, AdType? type) =>
      state = HomeCategorySelection(index: index, type: type);
}

final selectedCategoryChipProvider =
    NotifierProvider<SelectedCategoryChipNotifier, HomeCategorySelection>(
      SelectedCategoryChipNotifier.new,
    );
