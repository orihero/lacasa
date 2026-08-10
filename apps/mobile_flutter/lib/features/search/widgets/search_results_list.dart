/// SCREENS.md §3.4: "Results: vertical Listing Card list, infinite scroll."
/// The empty-state copy itself follows §1's formatting convention (3)
/// instead of §3.4's own literal text — that convention corrects the web
/// app's misspelled "Not fount post" to "No listings found" **everywhere**,
/// which supersedes any per-screen wording left over from before that rule
/// was written. `agent_ads_grid.dart`'s Ads List empty state already
/// follows the corrected copy; this list didn't, and disagreed with it
/// (real bug, found while writing this screen's first tests).
///
/// Uses the shared [FullListingCard] (`lib/shared/widgets/
/// full_listing_card.dart`) — its own doc comment names this exact screen
/// as the second caller it was promoted out of Home for. That card has a
/// fixed 230-logical-pixel width (built for a horizontal rail), so in this
/// vertical list it renders as a left-aligned column of fixed-width cards
/// rather than an edge-to-edge row; reusing the shared component as-is
/// (never forking it — hard rule) was chosen over a full-width card shape
/// unique to this screen. Flagged in the build report as a minor visual
/// compromise, not a functional one.
///
/// "Infinite scroll" is real lazy widget building (`ListView.builder` only
/// builds items as they scroll into view) over the complete, already-
/// fetched result set — there is no paginated fetch loop to drive, because
/// `GET /ads` returns everything in one response (see
/// `search_repository.dart`). This is one of the two honest options the
/// build spec allows ("chunked reveal ... or just render the full list");
/// rendering the full list was chosen for simplicity, since chunked reveal
/// would need to fabricate a fake "page boundary" over data that has none.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

class SearchResultsList extends ConsumerWidget {
  const SearchResultsList({super.key, required this.onTapAd});

  final void Function(Ad ad) onTapAd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(displayedSearchResultsProvider);

    return results.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        itemCount: 4,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.base),
        itemBuilder: (context, index) => ShimmerBox(
          height: 260,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      error: (error, stackTrace) => ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        children: [
          FullWidthState(
            icon: Icons.error_outline_rounded,
            message: "Couldn't load listings.",
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(searchResultsProvider),
          ),
        ],
      ),
      data: (ads) {
        if (ads.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            children: const [
              FullWidthState(
                icon: Icons.search_off_rounded,
                message: 'No listings found.',
              ),
            ],
          );
        }

        return ListView.separated(
          key: const ValueKey('searchResultsListView'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
            vertical: AppSpacing.base,
          ),
          itemCount: ads.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.lg),
          itemBuilder: (context, index) {
            final ad = ads[index];
            return Align(
              alignment: Alignment.centerLeft,
              child: FullListingCard(ad: ad, onTap: () => onTapAd(ad)),
            );
          },
        );
      },
    );
  }
}
