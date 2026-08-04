/// `home-feed` — build spec Part 2. Render order follows the shipped
/// mockup's actual DOM (`data-screen="home-feed"`), not SCREENS.md §3.3's
/// prose, which the build spec documents as describing an earlier draft
/// (see this file's own doc trail in the build report: no 3D-tour banner,
/// no single "Latest Listings" rail with "View More" — instead Featured
/// Listings (horizontal) + Explore Nearby (grid), "View all"/"Explore"
/// link copy).
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'agent_pitch_banner.dart';
import 'category_chip_row.dart';
import 'explore_nearby_grid.dart';
import 'featured_listings_rail.dart';
import 'home_header_row.dart';
import 'promo_carousel.dart';
import 'top_agents_rail.dart';
import 'top_districts_rail.dart';
import 'top_fade_bar.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: Stack(
        children: [
          // Android's stretch overscroll isolates a scrollable into its own
          // layer, which makes the backdrop-sampling lenses inside this feed
          // (price pills, favourite buttons, chips, the pitch banner) render
          // black at the scroll edges. Disabling the overscroll indicator is
          // the fix `liquid_glass_easy` prescribes; it is inherited by the
          // nested horizontal rails too, which carry lenses of their own.
          ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              overscroll: false,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + AppSpacing.md,
                  ),
                ),
                const SliverToBoxAdapter(child: HomeHeaderRow()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: CategoryChipRow()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: PromoCarousel()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: AgentPitchBanner()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: FeaturedListingsRail()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: TopDistrictsRail()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: TopAgentsRail()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
                const SliverToBoxAdapter(child: ExploreNearbyGrid()),
                // Extra bottom padding so the floating glass tab bar
                // (`extendBody: true`) never permanently covers the last row
                // of the grid.
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 100,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: TopFadeBar()),
        ],
      ),
    );
  }
}
