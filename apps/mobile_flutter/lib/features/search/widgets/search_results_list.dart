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
/// **"Infinite scroll" is a real paged fetch loop now**, not just lazy
/// widget building over an already-complete list — `GET /ads` gained
/// opt-in keyset paging (`search_repository.dart`), and
/// [SearchResultsNotifier.loadMore] extends the current page in place.
/// This widget triggers it two ways:
///  - [_onScroll] — the normal case: the list is scrolled within
///    [_loadMoreThreshold] logical pixels of its end.
///  - [_maybeTopUpShortPage] — the edge case a pure scroll listener misses:
///    the current page is short enough that its `ListView` never actually
///    overflows the viewport (`maxScrollExtent == 0`), so no scroll
///    notification is ever posted even though a next page exists. Checked
///    once per frame after layout; [SearchResultsNotifier.loadMore] is its
///    own re-entrant guard (`SearchResultsPage.isLoadingMore`), so calling
///    it every frame while a short page sits on screen is harmless.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

class SearchResultsList extends ConsumerStatefulWidget {
  const SearchResultsList({super.key, required this.onTapAd});

  final void Function(Ad ad) onTapAd;

  @override
  ConsumerState<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends ConsumerState<SearchResultsList> {
  static const double _loadMoreThreshold = 400;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final metrics = _scrollController.position;
    if (metrics.maxScrollExtent - metrics.pixels < _loadMoreThreshold) {
      ref.read(searchResultsProvider.notifier).loadMore();
    }
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
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        ref.read(searchResultsProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final l10n = AppLocalizations.of(context);

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
            message: l10n.searchResultsRetryMessage,
            actionLabel: l10n.sharedRetryLabel,
            onAction: () => ref.invalidate(searchResultsProvider),
          ),
        ],
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            children: [
              FullWidthState(
                icon: Icons.search_off_rounded,
                message: l10n.searchResultsEmptyMessage,
              ),
            ],
          );
        }

        _maybeTopUpShortPage(page);
        final showFooter = page.isLoadingMore || page.loadMoreFailed;

        return ListView.separated(
          key: const ValueKey('searchResultsListView'),
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
            vertical: AppSpacing.base,
          ),
          itemCount: page.items.length + (showFooter ? 1 : 0),
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.lg),
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
            return Align(
              alignment: Alignment.centerLeft,
              child: FullListingCard(ad: ad, onTap: () => widget.onTapAd(ad)),
            );
          },
        );
      },
    );
  }
}

