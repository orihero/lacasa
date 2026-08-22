/// The Explore Nearby grid: the final section, 2-column [GridView] of
/// compact listing cards, bound to the same [homeFeedAdsProvider] as
/// [FeaturedListingsRail] (items after the first 3 — build spec's "On the
/// source data for rails 5 and 8"). No "view all"/"Explore" link — build
/// spec: "full pagination lives in `listing-search`, not here."
///
/// Owns the *terminal* row of the loading/error/empty table: full-width
/// skeleton grid, full-width retry state, and full-width "No listings
/// available yet." — except the whole-feed-empty case, which
/// [FeaturedListingsRail] already renders in its own position ("below the
/// chips"); this renders nothing extra for that case to avoid a duplicate
/// message.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';

/// `.grid{gap:13px;grid-template-columns:1fr 1fr}` with a fixed
/// `.vcard__ph{height:116px}` photo band over `.vcard__b{padding:8px 2px 0}`
/// — at the mockup's 390px viewport that is a 168.5x189 cell. The photo
/// stays [Expanded] rather than fixed-height (see [CompactListingCard]), so
/// the band is reproduced by the cell ratio instead.
const double _cellAspectRatio = 0.88;

class ExploreNearbyGrid extends ConsumerWidget {
  const ExploreNearbyGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedAdsProvider);

    return feed.when(
      loading: () => _Shell(
        child: _grid(
          List.generate(
            4,
            (index) => AspectRatio(
              aspectRatio: _cellAspectRatio,
              child: ShimmerBox(
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
            ),
          ),
        ),
      ),
      // Whole-feed error already surfaced (with its retry action) by
      // FeaturedListingsRail above; avoid asking the user to retry twice
      // for the one underlying fetch.
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (ads) {
        // Whole-feed-empty: FeaturedListingsRail already rendered the
        // canonical combined message in its own position.
        if (ads.isEmpty) return const SizedBox.shrink();

        final explore = ads.skip(3).toList();
        if (explore.isEmpty) {
          // Featured has content but nothing is left for this slice — no
          // guidance in the build spec for this exact edge case (it assumes
          // Explore is independently paginated); rendering nothing here is
          // this build's own judgment call rather than an odd empty grid.
          return const SizedBox.shrink();
        }

        return _Shell(
          child: _grid(
            explore
                .map(
                  (ad) => CompactListingCard(
                    ad: ad,
                    onTap: () => context.push('/home/listing/${ad.id}'),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      // Not redundant. With a null `padding`, `BoxScrollView.buildSlivers`
      // adopts the ambient `MediaQuery.padding`'s vertical insets as the
      // grid's own — sensible for a scroller that *is* the page, wrong for one
      // nested mid-feed, where the status bar and the tab bar's height reappear
      // as dead space under the `.sec` heading and below the last row. Only
      // `.grid{margin-top:12px}` (the [AppSpacing.base] gap in [_Shell]) sits
      // between the heading and the first cell.
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 13,
      crossAxisSpacing: 13,
      childAspectRatio: _cellAspectRatio,
      children: children,
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context).homeExploreNearbySectionTitle,
        ),
        const SizedBox(height: AppSpacing.base),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          child: child,
        ),
      ],
    );
  }
}
