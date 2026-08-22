/// The one saved/favourited-ad-id set every heart control in the app reads
/// and writes through — [FavouriteButton] (`shared/widgets/favourite_button.dart`)
/// is its only intended caller, but any screen may `ref.watch` the id set
/// directly if it needs to know favourited-ness without rendering the
/// control itself.
///
/// Promoted out of `features/home/state/home_feed_providers.dart`, where
/// this used to be one of four independent Home-scoped providers, once a
/// second feature needed the identical set — see
/// `favourite_ad_ids_repository.dart`'s doc comment for why a per-feature
/// copy was rejected. Every other piece of Home's own screen state
/// (`homeFeedAdsProvider`, `topAgentsProvider`,
/// `selectedCategoryChipProvider`) stays feature-scoped; this is the one
/// exception, and it stays here rather than back in `features/home/`
/// specifically so it has no feature owner at all.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import 'favourite_ad_ids_repository.dart';
import 'live_favourite_ad_ids_repository.dart';

final favouriteAdIdsRepositoryProvider = Provider<FavouriteAdIdsRepository>((
  ref,
) {
  return LiveFavouriteAdIdsRepository(LaCasaApi.create());
});

/// Optimistic favourite/save toggle: flips [state] immediately, then
/// confirms with the repository; a failure reverts the flip and rethrows
/// so the caller (a widget with a [BuildContext]) can surface a toast.
/// Unchanged from its original Home-only version — only the repository
/// seam underneath it moved.
class FavouriteAdIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Seed asynchronously: start empty (unfavourited) rather than blocking
    // the calling screen's first frame on this secondary fetch, then fill
    // in once it resolves. `fetchInitialSavedAdIds` itself never throws
    // (see its doc comment), so no error handling is needed here.
    Future(() async {
      final ids = await ref
          .read(favouriteAdIdsRepositoryProvider)
          .fetchInitialSavedAdIds();
      // Guard against a state write after this provider was disposed
      // (e.g. the screen was popped while the seed fetch was in flight).
      if (ref.mounted) state = ids;
    });
    return const <String>{};
  }

  Future<void> toggle(String adId) async {
    final repository = ref.read(favouriteAdIdsRepositoryProvider);
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
