/// SCREENS.md §25: "Rows: thumbnail; #{id}; Created At; City; Status pill;
/// Author; {rooms} room; {area} m²; edit icon → `edit-listing`." Empty
/// state: **"Ads not found."** (verbatim — SCREENS.md's own override of the
/// generic shared-widget empty copy, build contract §4.2) for an agent who
/// genuinely has no ads. **A second empty state was added** for the case
/// §25 does not describe: filters that matched nothing (UX audit §9.4).
/// Printing "Ads not found." for both told a brand-new agent and an agent
/// with a Status=Sold filter the identical, unactionable sentence — and for
/// the second one it was simply false, since the ads exist and are one tap
/// from being visible again. `myListingsFilteredEmptyStateMessage` +
/// "Clear filters" is that tap; the un-filtered branch keeps §25's copy
/// verbatim and gains the "Create New Post" action a brand-new agent's
/// first Work screen otherwise lacked entirely (its only way forward was an
/// unlabelled 38px "+" in the header).
///
/// Both empty branches and the error branch pass `actionLabel`/`onAction`
/// to [FullWidthState], which has always taken them — the error branch here
/// already did, which is what makes the empty branch's omission a
/// regression rather than a missing feature.
///
/// The error branch routes through [describeReadError] (UX audit §9.5) so a
/// connectivity failure says "No connection" instead of the tenth identical
/// "Couldn't load X." card. `myListingsLoadErrorMessage` survives as the
/// fallback, which is still the right copy for a 500 or a malformed body.
///
/// [RefreshIndicator] wraps all three branches (UX audit §9.3), not just
/// the populated one: an agent staring at a stale empty state or a failed
/// load is *more* likely to pull down than one looking at rows, and the
/// error branch's Retry only re-fetches the ads, whereas a pull refreshes
/// the stage counts and channel badges too (see [refreshMyListings]). Every
/// branch's [ListView] therefore carries [AlwaysScrollableScrollPhysics] —
/// without it, a short list has nothing to overscroll and the gesture never
/// reaches the indicator. `my_listings_screen.dart`'s
/// `ScrollConfiguration(overscroll: false)` is unaffected: that replaces
/// the overscroll *glow*, which is a different mechanism from the
/// pull-to-refresh gesture.
///
/// "Infinite scroll" is a real paginated fetch loop —
/// [myListingsResultsProvider]'s [MyListingsPageState.hasMore] drives the
/// trailing loading-sentinel row below, and `my_listings_screen.dart`'s
/// scroll listener is what actually calls
/// [MyListingsResultsNotifier.loadMore] to fetch the next page (see
/// `state/my_listings_providers.dart`'s doc comment). That sentinel is the
/// shared `LoadMoreFooter` (`lib/shared/widgets/load_more_footer.dart`,
/// promoted out of `features/search`'s identical row) — a spinner normally,
/// a tappable "Couldn't load more — Retry" once [MyListingsPageState
/// .loadMoreFailed] is set, since a scroll-triggered fetch failure has no
/// other way to tell the user anything went wrong.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/my_listings_providers.dart';
import 'my_listing_row.dart';

class MyListingsList extends ConsumerWidget {
  const MyListingsList({
    super.key,
    required this.scrollController,
    required this.onTapAd,
    required this.onTapEdit,
    required this.onTapPublishStatus,
    required this.onCreate,
  });

  final ScrollController scrollController;
  final void Function(Ad ad) onTapAd;
  final void Function(Ad ad) onTapEdit;
  final void Function(Ad ad) onTapPublishStatus;

  /// The empty state's "Create New Post" action — the same destination the
  /// header's "+" reaches, wired from the screen so this widget stays free
  /// of routing.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(myListingsResultsProvider);
    // Independent of `results` on purpose (build contract §6): a
    // coworkers-roster failure only degrades the Author cell (falls back
    // to an em dash below), it must never blank the ads list itself.
    final coworkers = ref.watch(myListingsCoworkersProvider).value ?? const [];
    // Same independence for the channel badges — `.value` (not `.when`)
    // because an unresolved batch is rendered as *no badges*, never as an
    // error on top of a list that loaded fine. `null` here propagates to
    // every row as "unknown", which `MyListingChannelStrip` documents.
    final publishStatuses = ref.watch(myListingsPublishStatusesProvider).value;
    final currentUser = ref.watch(authSessionProvider.select((s) => s.user));

    return RefreshIndicator(
      key: const ValueKey('myListingsRefreshIndicator'),
      onRefresh: () => refreshMyListings(ref),
      child: results.when(
        loading: () => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          itemCount: 6,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.base),
          itemBuilder: (context, index) => ShimmerBox(
            height: 68,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
        ),
        error: (error, stackTrace) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          children: [
            FullWidthState(
              icon: readErrorIcon(error),
              message: describeReadError(
                l10n,
                error,
                fallback: l10n.myListingsLoadErrorMessage,
              ),
              actionLabel: l10n.sharedRetryLabel,
              onAction: () => ref.invalidate(myListingsResultsProvider),
            ),
          ],
        ),
        data: (pageState) {
          final ads = pageState.ads;
          if (ads.isEmpty) {
            // Read here rather than at the top of `build` so the whole list
            // does not rebuild on every filter change — it already rebuilds
            // via `results`, which watches the same three providers.
            final filtered = ref.watch(activeMyListingsFilterCountProvider) > 0;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              children: [
                FullWidthState(
                  key: ValueKey(
                    filtered
                        ? 'myListingsFilteredEmptyState'
                        : 'myListingsEmptyState',
                  ),
                  icon: filtered
                      ? Icons.filter_alt_off_outlined
                      : Icons.home_work_outlined,
                  message: filtered
                      ? l10n.myListingsFilteredEmptyStateMessage
                      : l10n.myListingsEmptyStateMessage,
                  actionLabel: filtered
                      ? l10n.sharedClearFiltersActionLabel
                      : l10n.myListingsEmptyStateActionLabel,
                  onAction: filtered
                      ? () => clearMyListingsFilters(ref)
                      : onCreate,
                ),
              ],
            );
          }

          return ListView.separated(
            key: const ValueKey('myListingsListView'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
              vertical: AppSpacing.base,
            ),
            // `hasMore` (not `isLoadingMore`) drives whether the sentinel row
            // exists at all — unlike search, this row is always present while
            // there's a next page, so it doubles as the near-bottom scroll
            // trigger itself; `hasMore` stays true through a load-more
            // failure (`nextCursor` is left unchanged, see
            // `MyListingsResultsNotifier.loadMore`'s catch block), so the
            // sentinel doesn't disappear when `LoadMoreFooter` below switches
            // it from a spinner to a "Couldn't load more — Retry" row.
            itemCount: ads.length + (pageState.hasMore ? 1 : 0),
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.base),
            itemBuilder: (context, index) {
              if (index >= ads.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.base,
                  ),
                  child: LoadMoreFooter(
                    failed: pageState.loadMoreFailed,
                    onRetry: () =>
                        ref.read(myListingsResultsProvider.notifier).loadMore(),
                    retryKey: const ValueKey('myListingsLoadMoreRetry'),
                    spinnerKey: const ValueKey('myListingsLoadMoreSpinner'),
                  ),
                );
              }

              final ad = ads[index];
              return MyListingRow(
                ad: ad,
                authorName:
                    resolveAdAuthorName(ad, coworkers, currentUser) ?? '—',
                channelStatuses: publishStatuses?[ad.id],
                onTap: () => onTapAd(ad),
                onEdit: () => onTapEdit(ad),
                onTapChannels: () => onTapPublishStatus(ad),
              );
            },
          );
        },
      ),
    );
  }
}
