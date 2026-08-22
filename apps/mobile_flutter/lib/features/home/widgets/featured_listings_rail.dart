/// The Featured Listings rail: header + horizontal rail of the first 3
/// items from [homeFeedAdsProvider] (build spec, "Featured Listings rail"
/// and "On the source data for rails 5 and 8"). Owns its slice of the
/// loading/error/empty table:
/// - loading: 3 shimmer [FullListingCard]-shaped placeholders.
/// - error: compact, rail-scoped [RailRetryCard].
/// - the whole-feed-empty case renders here (the build spec's "below the
///   chips" position) — Explore Nearby renders nothing extra for that same
///   case, avoiding a duplicate message (see `explore_nearby_grid.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';

const double _cardWidth = 230;
// Photo (148) + the title/spec/where text block below it. Generous rather
// than exact: text metrics vary with the platform's font-rendering/scale
// factor, and a fixed-height ListView item must never let its Column
// overflow — this is a safe upper bound measured against a 2-line title,
// not a tight fit.
const double _cardHeight = 148 + 112;

class FeaturedListingsRail extends ConsumerWidget {
  const FeaturedListingsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedAdsProvider);
    final l10n = AppLocalizations.of(context);

    return feed.when(
      loading: () => _Shell(
        child: SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            itemCount: 3,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.base),
            itemBuilder: (context, index) => ShimmerBox(
              width: _cardWidth,
              height: _cardHeight,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => _Shell(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          child: RailRetryCard(
            width: _cardWidth,
            message: l10n.homeFeaturedListingsRetryMessage,
            // `asReload: true`, and the flag is the entire point of this
            // line. A plain `ref.invalidate` is a *refresh*: Riverpod
            // rebuilds with `AsyncError.copyWithPrevious(isRefresh: true)`,
            // whose runtime type is still `AsyncError`, so `isRefreshing`
            // is true, `when`'s `skipLoadingOnRefresh` (which defaults to
            // **true**) skips the `loading:` arm, and the `error:` arm
            // above re-renders byte-identically. [RailRetryCard] carries no
            // in-flight state of its own, so the screen stayed pixel-perfect
            // still from the tap until the network answered — the user's
            // only evidence that Retry did anything was that it eventually
            // stopped being broken.
            //
            // `asReload: true` marks the rebuild as a *reload* instead,
            // which yields a real `AsyncLoading`; `isReloading` is then true
            // and `skipLoadingOnReload` defaults to **false**, so the three
            // shimmer cards above run and the rail visibly goes to work.
            //
            // This is deliberately the opposite of what pull-to-refresh
            // does with the same provider — see
            // `HomeFeedScreen._refresh`, which must *not* reload, because
            // blanking a list the user is looking at into skeletons is a
            // regression, not feedback. Retry has no list to preserve: the
            // previous state is an error, so there is nothing to lose.
            onRetry: () => ref.invalidate(homeFeedAdsProvider, asReload: true),
          ),
        ),
      ),
      data: (ads) {
        if (ads.isEmpty) {
          // Whole-feed empty: the canonical centered state lives here, in
          // Featured Listings' position (build spec: "below the chips").
          //
          // Which of the two messages depends on whether a category chip
          // narrowed the request. "No listings available yet." states that
          // the catalogue is empty; with a chip active that is simply
          // false — clearing the chip brings listings straight back — and
          // it would send the user away from a screen that still has plenty
          // on it, one tap up.
          final filtered = ref.watch(selectedCategoryChipProvider).type != null;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            child: FullWidthState(
              icon: Icons.home_work_outlined,
              message: filtered
                  ? l10n.homeFeedCategoryEmptyMessage
                  : l10n.homeFeedEmptyMessage,
            ),
          );
        }

        final featured = ads.take(3).toList();

        return _Shell(
          child: SizedBox(
            height: _cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              itemCount: featured.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.base),
              itemBuilder: (context, index) {
                final ad = featured[index];
                return FullListingCard(
                  ad: ad,
                  onTap: () => context.push('/home/listing/${ad.id}'),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeFeaturedListingsSectionTitle,
          linkLabel: l10n.homeFeaturedListingsViewAllLabel,
          onLink: () => context.go(RoutePaths.search),
        ),
        const SizedBox(height: AppSpacing.base),
        child,
      ],
    );
  }
}
