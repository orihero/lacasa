/// SCREENS.md §25: "Rows: thumbnail; #{id}; Created At; City; Status pill;
/// Author; {rooms} room; {area} m²; edit icon → `edit-listing`." Empty
/// state: **"Ads not found."** (verbatim — SCREENS.md's own override of the
/// generic shared-widget empty copy, build contract §4.2).
///
/// "Infinite scroll" is [myListingsVisibleCountProvider]'s client-side
/// paging window over the complete, already-fetched result set — see
/// `data/my_listings_repository.dart`'s doc comment (build contract §7.7)
/// for why there is no paginated fetch loop to drive instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
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
    final results = ref.watch(displayedMyListingsProvider);
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
            message: "Couldn't load your ads.",
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(myListingsResultsProvider),
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
                icon: Icons.home_work_outlined,
                message: 'Ads not found.',
              ),
            ],
          );
        }

        final visibleCount = ref
            .watch(myListingsVisibleCountProvider)
            .clamp(0, ads.length);
        final hasMore = visibleCount < ads.length;

        return ListView.separated(
          key: const ValueKey('myListingsListView'),
          controller: scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
            vertical: AppSpacing.base,
          ),
          itemCount: visibleCount + (hasMore ? 1 : 0),
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.base),
          itemBuilder: (context, index) {
            if (index >= visibleCount) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.base),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
