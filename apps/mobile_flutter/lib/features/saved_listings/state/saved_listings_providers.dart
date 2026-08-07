/// Riverpod state for `saved-listings` (SCREENS.md §3.17).
///
/// **On "un-hearting a card here should make it leave the list" — the
/// judgment call this file exists to make honestly.**
///
/// This screen is the one place in the app where
/// `shared/state/favourite_ad_ids_provider.dart`'s shared favourite-id set
/// *is* the content, not just a decoration on top of it (every other
/// listing-card grid keeps showing a card whether its heart is filled or
/// not). [CompactListingCard] already wires its heart through that shared
/// [favouriteAdIdsProvider] — every other card in the app does the same — so
/// the honest thing is to let the *existing* control drive removal rather
/// than growing a second, screen-local unsave path. Two options were
/// considered for how:
///
/// 1. **Reactive filter**: render `fetchedList.where((ad) =>
///    favouriteAdIdsProvider.contains(ad.id))` on every build. Simplest
///    code, but wrong: [FavouriteAdIdsNotifier] seeds its set
///    *asynchronously* (its own doc comment: "start empty ... then fill in
///    once it resolves"), so on a cold navigation straight to this screen —
///    the deep-link case this build explicitly has to handle — the shared
///    set can still be `{}` for a moment after this screen's own fetch has
///    already landed a full list. A plain membership filter would flash
///    every freshly-loaded card as "not actually saved" and hide the whole
///    grid for a frame, which is a worse lie than the one this screen is
///    trying to avoid.
/// 2. **Diff-based pruning** (what [SavedListingsNotifier] does): keep this
///    screen's own fetched list as the source of truth for what to display,
///    and only ever *remove* an id when [favouriteAdIdsProvider] reports
///    that id specifically leaving its set (`previous.difference(next)`) —
///    never re-derive the displayed set from current membership. A favourite
///    set that is still empty because it hasn't seeded yet contributes no
///    diff, so it can never spuriously hide anything this screen already
///    confirmed is saved. A real unsave (optimistic toggle in
///    [FavouriteButton]) always does produce a genuine
///    previous-had-it/next-doesn't diff, so removal is still immediate.
///
/// (2) is what's implemented. The trade-off it accepts: if a fixture's own
/// saved-ad seed ever disagreed with `favourite_ad_ids`'s fixture seed, the
/// first seed-arrival diff would wrongly look like a removal — which is
/// exactly why `saved_listings_fixtures.dart` is pinned to the same id as
/// `fixture_favourite_ad_ids_repository.dart`'s seed rather than inventing
/// its own.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import 'saved_listings_repository_provider.dart';

class SavedListingsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() async {
    // See this file's doc comment for why this diffs rather than filters.
    ref.listen<Set<String>>(favouriteAdIdsProvider, (previous, next) {
      if (previous == null) return;
      final removed = previous.difference(next);
      if (removed.isEmpty) return;

      final current = state.value;
      if (current == null) return;

      final pruned = current.where((ad) => !removed.contains(ad.id)).toList();
      if (pruned.length != current.length) {
        state = AsyncData(pruned);
      }
    });

    return ref.read(savedListingsRepositoryProvider).fetchSavedAds();
  }
}

final savedListingsProvider =
    AsyncNotifierProvider<SavedListingsNotifier, List<Ad>>(
      SavedListingsNotifier.new,
    );
