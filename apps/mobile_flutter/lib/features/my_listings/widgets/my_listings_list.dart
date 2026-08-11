/// SCREENS.md §25: "Rows: thumbnail; #{id}; Created At; City; Status pill;
/// Author; {rooms} room; {area} m²; edit icon → `edit-listing`." Empty
/// state: **"Ads not found."** (verbatim — SCREENS.md's own override of the
/// generic shared-widget empty copy, build contract §4.2).
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
  });

  final ScrollController scrollController;
  final void Function(Ad ad) onTapAd;
  final void Function(Ad ad) onTapEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(myListingsResultsProvider);
    // Independent of `results` on purpose (build contract §6): a
    // coworkers-roster failure only degrades the Author cell (falls back
    // to an em dash below), it must never blank the ads list itself.
    final coworkers = ref.watch(myListingsCoworkersProvider).value ?? const [];
    final currentUser = ref.watch(authSessionProvider.select((s) => s.user));

    return results.when(
      loading: () => ListView.separated(
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        children: [
          FullWidthState(
            icon: Icons.error_outline_rounded,
            message: l10n.myListingsLoadErrorMessage,
            actionLabel: l10n.sharedRetryLabel,
            onAction: () => ref.invalidate(myListingsResultsProvider),
          ),
        ],
      ),
      data: (pageState) {
        final ads = pageState.ads;
        if (ads.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            children: [
              FullWidthState(
                icon: Icons.home_work_outlined,
                message: l10n.myListingsEmptyStateMessage,
              ),
            ],
          );
        }

        return ListView.separated(
          key: const ValueKey('myListingsListView'),
          controller: scrollController,
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
              onTap: () => onTapAd(ad),
              onEdit: () => onTapEdit(ad),
            );
          },
        );
      },
    );
  }
}
