/// The Top Districts rail — real data now, and a deliberate redesign of the
/// mockup's tile.
///
/// ## Data
/// Bound to [topDistrictsProvider], which tallies `Ad.district` across
/// [homeFeedAdsProvider] (the same feed Featured Listings and Explore
/// Nearby render) and sorts by count. It used to be four hardcoded
/// Tashkent names paired with invented gradients, and this file used to
/// claim "no loading/error/empty states apply" — both are gone: "Top
/// Districts" now means, literally, *the districts with the most active
/// listings right now*, which is the only popularity signal that exists
/// anywhere in this system. See `state/top_districts_provider.dart` for
/// why that derivation is exact rather than a sample, and
/// `data/district_tally.dart` for why the names come from the feed rather
/// than `regions.json`.
///
/// - loading: 3 tile-shaped [ShimmerBox]es (same convention as
///   [FeaturedListingsRail]).
/// - error: nothing at all. This shares one fetch with Featured Listings,
///   which already rendered a [RailRetryCard] two sections above — exactly
///   the reasoning `explore_nearby_grid.dart` states for the same provider.
/// - empty, **or a single district**: hide the rail *and its header*. A
///   one-tile "ranking" is not a ranking, and an empty rail under a "Top
///   Districts" heading is a promise the data cannot keep. Same judgment
///   call [TopAgentsRail] makes for its own empty case.
///
/// ## Why the tile no longer looks like `.dist`
/// The mockup's tile is `.dist{width:78px;height:96px;border-radius:20px}`
/// wrapping a full-bleed `object-fit:cover` photograph, the five-stop
/// `.scrim`, and `.dist__n{left:5px;right:5px;bottom:5px;height:24px}` — a
/// `.g` glass pill holding a 9.5px name. Every one of those three devices
/// exists *to survive a photograph*: 78x96 is a photo crop, the scrim makes
/// white text legible over arbitrary imagery, and the glass pill is there
/// because a photo is too busy for bare text.
///
/// This app has no district photography and will not get 203 of them —
/// the mockup's own art is Unsplash JPEGs inlined into its `window.PHOTOS`
/// registry, and nothing in the API serves a district image. Ported
/// literally, all three devices became decoration with no job, and the
/// glass pill in particular became a lens over a flat gradient — refraction
/// with nothing to refract, which is what read as a sticker.
///
/// So the card *is* the glass now: a [GlassVariant.onSurface] tile at
/// [AppRadii.card] (the radius `.dist` itself uses), carrying a `.where`-
/// style pin glyph, the district name at the standard card-title tier, and
/// the listing count at the `.spec` tier. Nothing is painted over
/// photography any more, so nothing needs to defend itself from one.
///
/// ## Tap
/// The mockup's `data-go="listing-search"` is unconditional and carries no
/// district. This build improves on it: a tap applies
/// `AdFilters(district:)` to [appliedSearchFiltersProvider] before
/// navigating, so the Search tab lands pre-filtered (with a "1" on its
/// Filters badge) and the count on the tile is a promise the next screen
/// actually keeps. The header's "Explore" link is left unfiltered, matching
/// the mockup.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../search/state/search_providers.dart';
import '../data/district_tally.dart';
import '../state/top_districts_provider.dart';

/// Wide enough for two lines of a real district string (`Mirzo Ulugʻbek
/// tumani`, `Shayxontohur tumani`) at [LaCasaTypography.rowTitle], and
/// deliberately not a whole number of screens' worth: at 390pt the rail's
/// strip runs x=20..390, so 132+10 puts tiles at 20/162/304 and the third
/// peeks past the edge — the scroll affordance the mockup's exactly-four-fit
/// 78px tiles never had.
const double _tileWidth = 132;

/// Generous rather than exact, for the same reason [FeaturedListingsRail]'s
/// card height is: 12 padding + 28 glyph well + 8 + two lines of `rowTitle`
/// + 2 + one line of `specMeta` + 12 padding lands near 105, and a fixed
/// height inside a horizontal [ListView] must never let its [Column]
/// overflow at a larger system font scale.
const double _tileHeight = 116;

/// `.dists{gap:10px}` — the one piece of the mockup's rail geometry the
/// redesign keeps unchanged.
const double _railGap = 10;

const double _glyphWellSize = 28;

class TopDistrictsRail extends ConsumerWidget {
  const TopDistrictsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districts = ref.watch(topDistrictsProvider);

    return districts.when(
      loading: () => _Shell(
        child: SizedBox(
          height: _tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            itemCount: 3,
            separatorBuilder: (context, index) =>
                const SizedBox(width: _railGap),
            itemBuilder: (context, index) => ShimmerBox(
              width: _tileWidth,
              height: _tileHeight,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
        ),
      ),
      // See this file's doc comment: one fetch, one retry card, and
      // Featured Listings already owns it.
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (tallies) {
        if (tallies.length < 2) return const SizedBox.shrink();

        return _Shell(
          child: SizedBox(
            height: _tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              itemCount: tallies.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: _railGap),
              itemBuilder: (context, index) => _DistrictTile(tallies[index]),
            ),
          ),
        );
      },
    );
  }
}

class _DistrictTile extends ConsumerWidget {
  const _DistrictTile(this.tally);

  final DistrictTally tally;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    // Merged into one node so a screen reader announces the tile as
    // "<district>, N listings, button" instead of two unrelated fragments,
    // with the *action* carried by the hint rather than by an
    // `excludeSemantics` label that would have hidden the count.
    return MergeSemantics(
      child: Semantics(
        button: true,
        hint: l10n.homeDistrictTapSemanticsLabel(tally.name),
        child: GestureDetector(
          key: ValueKey('district-${tally.name}'),
          onTap: () {
            // The verbatim feed string, which is what `GET /ads?district=`
            // matches on — see `data/district_tally.dart`.
            ref
                .read(appliedSearchFiltersProvider.notifier)
                .apply(AdFilters(district: tally.name));
            context.go(RoutePaths.search);
          },
          child: GlassSurface(
            variant: GlassVariant.onSurface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            width: _tileWidth,
            height: _tileHeight,
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The same circular glyph well `.chip.on .chip__ic` uses,
                // holding the map pin every listing card's `.where` line
                // carries — the tile reads as part of the family rather
                // than as a new shape.
                Container(
                  width: _glyphWellSize,
                  height: _glyphWellSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.sunk,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: colors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  tally.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeDistrictListingsCount(tally.count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.specMeta.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
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
          title: l10n.homeTopDistrictsSectionTitle,
          linkLabel: l10n.homeTopDistrictsExploreLinkLabel,
          onLink: () => context.go(RoutePaths.search),
        ),
        const SizedBox(height: AppSpacing.base),
        child,
      ],
    );
  }
}
