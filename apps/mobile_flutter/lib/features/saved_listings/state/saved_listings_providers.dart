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
///
/// **The half of the diff (2) originally ignored — a failed unsave.**
/// [FavouriteAdIdsNotifier.toggle] is *optimistic*: it flips the shared set
/// first and, if the `DELETE /saved-ads/:id` throws, puts the id straight
/// back (`shared/state/favourite_ad_ids_provider.dart`) while
/// [FavouriteButton] toasts the failure. Watching removals only, this screen
/// saw the optimistic half of that sequence and never the revert — so an
/// unsave that failed offline left the ad still saved on the server, its
/// heart still filled on every other surface, and its card missing from the
/// one screen whose entire job is listing saved ads, until a pull-to-refresh
/// or a remount. So the listener now reads the diff in both directions: an
/// id *coming back* into the shared set after this screen pruned it is
/// exactly the revert signal, and it re-reads the list from the server
/// ([_refetchAfterRevert]) rather than re-inserting the [Ad] object it
/// happened to be holding — the server is the authority on what is saved,
/// and the round trip also picks up anything else that changed while the
/// screen was open. The re-read deliberately does **not** move [state] to
/// [AsyncLoading]: this is a correction to a list the user is already
/// looking at, not a fresh load, and blanking the grid into skeletons on top
/// of an error toast would read as a second failure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import 'saved_listings_repository_provider.dart';

class SavedListingsNotifier extends AsyncNotifier<List<Ad>> {
  /// Ids this screen has taken out of its own list because
  /// [favouriteAdIdsProvider] reported them leaving the shared set. Kept so
  /// that an id *re-entering* that set can be told apart from an ordinary
  /// save made on some other screen: only a previously-pruned id coming back
  /// means "the removal this grid already performed turned out to be wrong".
  /// (A genuine re-save of a long-since-unsaved ad also re-reads the list,
  /// which is the correct outcome too — it is saved again, so it belongs
  /// here again.)
  final Set<String> _prunedIds = <String>{};

  @override
  Future<List<Ad>> build() async {
    // A rebuild (Retry, pull-to-refresh, invalidate) re-reads the whole list
    // from the server, so nothing pruned before it is still pending
    // reconciliation.
    _prunedIds.clear();

    // See this file's doc comment for why this diffs rather than filters,
    // and why it now reads the diff in both directions.
    ref.listen<Set<String>>(favouriteAdIdsProvider, (previous, next) {
      if (previous == null) return;
      _pruneUnsaved(previous.difference(next));
      _reconcileRestored(next.difference(previous));
    });

    return ref.read(savedListingsRepositoryProvider).fetchSavedAds();
  }

  void _pruneUnsaved(Set<String> removed) {
    if (removed.isEmpty) return;

    final current = state.value;
    if (current == null) return;

    final pruned = current.where((ad) => !removed.contains(ad.id)).toList();
    if (pruned.length != current.length) {
      _prunedIds.addAll(removed);
      state = AsyncData(pruned);
    }
  }

  void _reconcileRestored(Set<String> added) {
    if (added.isEmpty) return;
    // Drop every restored id from the pending set first, unconditionally and
    // eagerly (a lazy `where` would stop at the first match and leave the
    // rest behind): whether or not the re-read succeeds, these ids have had
    // their one chance to trigger one, and a pruned id left in the set would
    // fire another round trip on the next unrelated diff.
    var wasPruned = false;
    for (final id in added) {
      if (_prunedIds.remove(id)) wasPruned = true;
    }
    if (!wasPruned) return;

    _refetchAfterRevert();
  }

  /// Re-reads the saved list *in place* — no [AsyncLoading], so the grid
  /// keeps showing its cards (see this file's doc comment). A failure here is
  /// swallowed on purpose: the user is already being toasted about the
  /// mutation that failed, and replacing a merely-incomplete grid with a
  /// full-width error state would lose the cards that are still perfectly
  /// good. The next pull-to-refresh reconciles it.
  Future<void> _refetchAfterRevert() async {
    try {
      final ads = await ref
          .read(savedListingsRepositoryProvider)
          .fetchSavedAds();
      // The screen can be popped while this is in flight — same guard
      // `FavouriteAdIdsNotifier`'s seed fetch uses.
      if (ref.mounted) state = AsyncData(ads);
    } catch (_) {
      // Intentionally ignored — see above.
    }
  }
}

final savedListingsProvider =
    AsyncNotifierProvider<SavedListingsNotifier, List<Ad>>(
      SavedListingsNotifier.new,
    );
