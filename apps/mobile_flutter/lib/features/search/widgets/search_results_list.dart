/// SCREENS.md §3.4: "Results: vertical Listing Card list, infinite scroll."
/// The empty-state copy is §4's own literal text — "No listings match your
/// search." — which is also the sentence `map-view` already showed for the
/// same empty result set (`mapNoResultsMessage`), map-view being this
/// search rendered on a map. §1's formatting convention (3), which corrects
/// the web app's misspelled "Not fount post" to "No listings found",
/// governs the screens that have no wording of their own — §10's Ads List
/// (`agent_ads_grid.dart`) — not this one, which §4 spells out.
///
/// This used to read the other way round, following convention (3) here
/// too and rendering "No listings found."; that was a real divergence from
/// §4, corrected in the mockup-parity pass.
///
/// **The empty state now branches on whether filters are active**, and only
/// the unfiltered branch keeps §4's sentence. "No listings match your
/// search." is a statement about the market; when the buyer has a price
/// ceiling and three chips applied it is a statement about their own filter
/// set, and saying the first when the second is true sends them away from a
/// market that does have what they want. The filtered branch also carries
/// the screen's only route back out — "Clear filters", wired to
/// [AppliedSearchFiltersNotifier.reset] — because until now the empty state
/// offered nothing to tap at all. See the `build` body for why the free-text
/// query is deliberately *not* cleared by it.
///
/// Uses [RowListingCard] (`row_listing_card.dart`), the mockup's `.lcard`
/// full-width row. It used to use the shared [FullListingCard], which is
/// `.fcard` — a fixed 230-logical-pixel column built for Home's horizontal
/// rail — so results rendered as a left-aligned half-width column with a
/// dead right gutter. `.fcard` is still correct for its own caller, so the
/// fix was the missing second card shape, not a change to the shared one.
///
/// **This widget renders as a sliver, not as a box.** It is one of several
/// slivers in `search_screen.dart`'s single `CustomScrollView` — the
/// mockup's one `.body` scroller, which also holds the recent-search chips
/// and the sort toolbar above the results and the tab-bar clearance below
/// them. It therefore takes no padding of its own beyond the screen gutter
/// (its callers own the lead-in and the bottom clearance) and does not
/// create a `ScrollController`: [scrollController] is the enclosing
/// scroller's, handed down so the infinite-scroll listener below watches
/// the scrollable the results actually live in.
///
/// **"Infinite scroll" is a real paged fetch loop now**, not just lazy
/// widget building over an already-complete list — `GET /ads` gained
/// opt-in keyset paging (`search_repository.dart`), and
/// [SearchResultsNotifier.loadMore] extends the current page in place.
/// This widget triggers it two ways:
///  - [_onScroll] — the normal case: the scroller is dragged to within
///    [_loadMoreThreshold] logical pixels of its end.
///  - [_maybeTopUpShortPage] — the edge case a pure scroll listener misses:
///    the current page is short enough that the scroller already sits
///    within [_loadMoreThreshold] of its end at rest, so no scroll
///    notification is ever posted even though a next page exists. (Before
///    the results became a sliver this was the narrower "`maxScrollExtent
///    == 0`, the list never overflows the viewport" test; sharing a
///    scroller with the header content means a short page can now leave a
///    little scrollable slack while still never reaching the threshold, so
///    the check is the same predicate [_onScroll] uses.) Checked once per
///    frame after layout; [SearchResultsNotifier.loadMore] is its own
///    re-entrant guard (`SearchResultsPage.isLoadingMore`), so calling it
///    every frame while a short page sits on screen is harmless.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

class SearchResultsList extends ConsumerStatefulWidget {
  const SearchResultsList({
    super.key,
    required this.onTapAd,
    required this.scrollController,
  });

  final void Function(Ad ad) onTapAd;

  /// The enclosing `CustomScrollView`'s controller — owned and disposed by
  /// `search_screen.dart`, never by this widget.
  final ScrollController scrollController;

  @override
  ConsumerState<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends ConsumerState<SearchResultsList> {
  static const double _loadMoreThreshold = 400;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  /// True when the scroller is close enough to its end that the next page
  /// should already be in flight. Shared by the drag-driven [_onScroll] and
  /// the at-rest [_maybeTopUpShortPage] so the two can never disagree about
  /// where "the end" is.
  bool _isNearEnd() {
    if (!widget.scrollController.hasClients) return false;
    final metrics = widget.scrollController.position;
    return metrics.maxScrollExtent - metrics.pixels < _loadMoreThreshold;
  }

  void _onScroll() {
    if (!_isNearEnd()) return;
    ref.read(searchResultsProvider.notifier).loadMore();
  }

  void _maybeTopUpShortPage(SearchResultsPage page) {
    // `loadMoreFailed` is the load-bearing guard here: without it, a failed
    // top-up leaves `nextCursor` unchanged (by design — see
    // `SearchResultsNotifier.loadMore`'s doc comment), so the very next
    // frame would see the same "short page, more to fetch" shape and retry
    // immediately — forever, hammering a failing endpoint every frame
    // instead of waiting for the user to tap the footer's own Retry (real
    // bug, caught by a widget test timing out on `pumpAndSettle`).
    if (page.nextCursor == null || page.isLoadingMore || page.loadMoreFailed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isNearEnd()) {
        ref.read(searchResultsProvider.notifier).loadMore();
      }
    });
  }

  /// The four-row placeholder shown while page 1 is in flight. Extracted
  /// from the `loading:` branch because the `error:` branch needs the very
  /// same sliver: tapping Retry re-runs the fetch through
  /// `ref.invalidate`, which Riverpod treats as a *refresh* rather than a
  /// reload — the new state is an `AsyncError` carrying `isLoading: true`,
  /// not an `AsyncLoading`, so `when`'s `skipLoadingOnRefresh` (true by
  /// default) skips `loading:` entirely and re-renders the same error card
  /// for the whole duration of the request. Without this the Retry button
  /// is a dead tap: nothing on screen changes until the answer lands.
  Widget _skeletonSliver() {
    return SliverList.separated(
      itemCount: 4,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.base),
      // Matches a `RowListingCard`'s height (9px padding + a 96px photo),
      // so the list doesn't jump when the real rows land.
      itemBuilder: (context, index) => ShimmerBox(
        height: 114,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final l10n = AppLocalizations.of(context);

    // Every state is wrapped in the same `SliverPadding` so the gutter never
    // shifts as one replaces another; the vertical rhythm above and below
    // belongs to `search_screen.dart`'s own spacer slivers.
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      sliver: results.when<Widget>(
        loading: _skeletonSliver,
        error: (error, stackTrace) {
          // A retry that is already in flight is still an `AsyncError` (see
          // [_skeletonSliver]) — `isLoading` is the only thing that
          // distinguishes it from a settled failure, and it is exactly the
          // window in which the user is waiting on a tap they just made. The
          // check is scoped to this branch on purpose: the `data:` branch is
          // untouched, so pull-to-refresh and load-more still keep the list
          // on screen behind their own indicators.
          if (results.isLoading) return _skeletonSliver();

          return SliverToBoxAdapter(
            child: FullWidthState(
              key: const ValueKey('searchResultsErrorState'),
              // Offline is a fact about the whole app, not about this list,
              // so it wins over the per-screen sentence — see
              // `shared/widgets/read_error.dart` for why a dozen screens each
              // saying "Couldn't load X" is worse than all of them saying the
              // one thing that is actually true.
              icon: readErrorIcon(error),
              message: describeReadError(
                l10n,
                error,
                fallback: l10n.searchResultsRetryMessage,
              ),
              actionLabel: l10n.sharedRetryLabel,
              onAction: () => ref.invalidate(searchResultsProvider),
            ),
          );
        },
        data: (page) {
          if (page.items.isEmpty) {
            // "No listings match your search." and "No listings match your
            // filters." are different facts with different exits, and the
            // screen knows which one it is: `activeFilterCountProvider` is
            // the same count the toolbar's Filters badge shows. Saying
            // "no matches" to someone whose price ceiling is simply too low
            // sends them away from a market that has what they want.
            //
            // The action resets `appliedSearchFiltersProvider` **only** —
            // deliberately not `searchQueryProvider`. The query is visible
            // in the search field the user is looking at; a "Clear filters"
            // button that also silently emptied a field they can see would
            // be its own version of this same defect.
            final hasFilters = ref.watch(activeFilterCountProvider) > 0;

            return SliverToBoxAdapter(
              child: FullWidthState(
                key: const ValueKey('searchResultsEmptyState'),
                icon: Icons.search_off_rounded,
                message: hasFilters
                    ? l10n.searchResultsFilteredEmptyMessage
                    : l10n.searchResultsEmptyMessage,
                actionLabel: hasFilters
                    ? l10n.sharedClearFiltersActionLabel
                    : null,
                onAction: hasFilters
                    ? () => ref
                          .read(appliedSearchFiltersProvider.notifier)
                          .reset()
                    : null,
              ),
            );
          }

          _maybeTopUpShortPage(page);
          final showFooter = page.isLoadingMore || page.loadMoreFailed;

          return SliverList.separated(
            key: const ValueKey('searchResultsListView'),
            itemCount: page.items.length + (showFooter ? 1 : 0),
            // `.stack{gap:11px}` — 12 is the token whose source range
            // (11–12px) covers it, and the same gap the shimmer above uses,
            // so the list doesn't re-space itself when the real rows land.
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.base),
            itemBuilder: (context, index) {
              if (index >= page.items.length) {
                return LoadMoreFooter(
                  failed: page.loadMoreFailed,
                  onRetry: () =>
                      ref.read(searchResultsProvider.notifier).loadMore(),
                  retryKey: const ValueKey('searchLoadMoreRetry'),
                  spinnerKey: const ValueKey('searchLoadMoreSpinner'),
                );
              }
              final ad = page.items[index];
              return RowListingCard(ad: ad, onTap: () => widget.onTapAd(ad));
            },
          );
        },
      ),
    );
  }
}
