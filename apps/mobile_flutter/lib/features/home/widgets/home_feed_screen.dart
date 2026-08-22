/// `home-feed` — build spec Part 2. Render order follows the shipped
/// mockup's actual DOM (`data-screen="home-feed"`), not SCREENS.md §3.3's
/// prose, which the build spec documents as describing an earlier draft
/// (see this file's own doc trail in the build report: no 3D-tour banner,
/// no single "Latest Listings" rail with "View More" — instead Featured
/// Listings (horizontal) + Explore Nearby (grid), "View all"/"Explore"
/// link copy).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';
import 'agent_pitch_banner.dart';
import 'category_chip_row.dart';
import 'explore_nearby_grid.dart';
import 'featured_listings_rail.dart';
import 'home_header_row.dart';
import 'promo_carousel.dart';
import 'top_agents_rail.dart';
import 'top_districts_rail.dart';
import 'top_fade_bar.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  /// Pull-to-refresh. [homeFeedAdsProvider] and [topAgentsProvider] are both
  /// plain (non-`autoDispose`) `AsyncNotifierProvider`s, so once Home has
  /// loaded they are never rebuilt again: switching tabs keeps them alive,
  /// backgrounding the app keeps them alive, and the only
  /// `ref.invalidate(homeFeedAdsProvider)` anywhere else in the codebase
  /// sits inside a [RailRetryCard], which renders solely on failure. The
  /// practical result was that a session that started this morning was still
  /// showing this morning's feed at 6pm with no user-reachable way to say so.
  ///
  /// **Both providers, not just the feed.** The audit names
  /// [homeFeedAdsProvider]; refreshing only it would leave the Top Agents
  /// rail — an independent fetch on the identical never-disposed lifetime,
  /// sitting in the middle of the same scroll — visibly stale under a
  /// gesture the user just watched complete. `selectedCategoryChipProvider`
  /// is deliberately *not* invalidated: it is the user's own current choice,
  /// not fetched state, and resetting the lit chip to "All" mid-refresh
  /// would silently discard a filter.
  ///
  /// Awaiting `.future` rather than returning immediately is what keeps the
  /// spinner on screen until the new data actually lands — `ref.invalidate`
  /// is synchronous and would otherwise retract the indicator the same
  /// frame. `Future.wait` so a slow rail doesn't serialize behind the feed.
  /// Errors are swallowed here on purpose: each rail already renders its own
  /// [RailRetryCard] from the same [AsyncValue], and letting the future
  /// reject would surface an unhandled zone error on top of it.
  ///
  /// **No `asReload: true` here, and that omission is load-bearing.** The
  /// two [RailRetryCard]s pass it (see `featured_listings_rail.dart`), so
  /// the flag now looks like something this call forgot. It is not: a plain
  /// invalidate is a *refresh*, which keeps each provider's previous value
  /// attached, and `AsyncValue.when`'s `skipLoadingOnRefresh` defaults to
  /// true — so every rail keeps rendering the listings the user is currently
  /// looking at while the new ones are fetched, with the [RefreshIndicator]
  /// spinner as the feedback. Reloading instead would blank the whole feed
  /// into skeletons under the user's finger, which is what pull-to-refresh
  /// exists *not* to do. Retry can afford the skeletons because its previous
  /// state is an error, i.e. there is no content to throw away.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(homeFeedAdsProvider);
    ref.invalidate(topAgentsProvider);
    await Future.wait([
      _settled(ref.read(homeFeedAdsProvider.future)),
      _settled(ref.read(topAgentsProvider.future)),
    ]);
  }

  /// Completes when [future] does, however it does — see [_refresh] on why a
  /// rail's failure must not reject the refresh itself.
  static Future<void> _settled(Future<void> future) async {
    try {
      await future;
    } catch (_) {
      // Rendered by the rail's own error branch.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      // Android's stretch overscroll isolates a scrollable into its own
      // layer, which makes the backdrop-sampling lenses inside this feed
      // (price pills, favourite buttons, chips, the pitch banner) render
      // black at the scroll edges. Disabling the overscroll indicator is
      // the fix `liquid_glass_easy` prescribes; it is inherited by the
      // nested horizontal rails too, which carry lenses of their own. It
      // matters twice over now that the header is pinned: the header's own
      // two lenses sample the viewport's backdrop on every frame of a
      // scroll, so they sit in exactly the layer that isolation breaks.
      //
      // `overscroll: false` suppresses the stretch/glow *indicator* only;
      // the [RefreshIndicator] below is a separate widget over the same
      // scroll notifications and is unaffected by it.
      body: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
        child: RefreshIndicator(
          key: const ValueKey('homeFeed-refresh'),
          onRefresh: () => _refresh(ref),
          // The header is *pinned*, so it occupies the top of this scroll
          // view at every offset. Without an edge offset the spinner would
          // ride down over the location pill and the two icon buttons —
          // and over the header's own glass lenses, which sample whatever
          // is behind them. `edgeOffset` moves the indicator's origin below
          // the pinned extent instead, which is what that parameter is for.
          edgeOffset: _PinnedHomeHeader.extentFor(topInset),
          color: AppAccent.color,
          backgroundColor: colors.card,
          child: CustomScrollView(
            // The feed is taller than any phone once it has data, but the
            // very first frame (every rail in shimmer) can be short enough
            // on a tablet to have no scroll extent — and that is exactly
            // when someone reaches for a refresh.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHomeHeader(topInset: topInset),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section),
              ),
              const SliverToBoxAdapter(child: CategoryChipRow()),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section),
              ),
              const SliverToBoxAdapter(child: PromoCarousel()),
              // No spacer here: `AgentPitchBanner` carries its own
              // `.pitch{margin-top:16px}` so that both collapse together
              // for a signed-in session.
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
      ),
    );
  }
}

/// The `.hdr` row, pinned to the top of the feed.
///
/// **This is a deliberate deviation from the mockup, not a transcription of
/// it.** `.hdr` is the first child of the `.feed` scroller and carries no
/// `position` (mockup :307, markup :1143-1152); `position:sticky` appears
/// nowhere in the prototype. Home-feed is the one tab root the source wrote
/// that way — every other one (`agents-directory` :1757, `dashboard` :2494)
/// uses the fixed `.nav{position:absolute;top:0;z-index:55}` + `.body
/// {padding-top:calc(var(--fh) + 6px)}` pair. Pinning the header here was a
/// product decision; it is built out of the source's own `.nav` parts so it
/// stays consistent with the screens that were drawn pinned.
///
/// Two of those parts matter:
/// - `.topfade{height:var(--fh)}` (:193) sized to `.nav{height:var(--fh)}`
///   (:196-198). The header has no background of its own — only its two
///   `.gl` lenses do — so without a full-height strip behind it the promo
///   cards and listing photos would slide visibly through the gaps between
///   the location pill and the two icon buttons. [TopFadeBar] is that strip,
///   grown from the status-bar-only `--fh:64px` this screen used to declare
///   (`data-fade="sm"`, :127) to the header's full height.
/// - The strip goes *behind* the row, as a sibling painted first, never
///   around it. It is a [BackdropFilter]; wrapping the row's lenses in one
///   is the nested-lens case `theme/glass_surface.dart` forbids, where each
///   lens re-refracts what the one beneath already bent.
///
/// [minExtent] == [maxExtent] because `.nav` has no collapse behaviour, and
/// a header that resized on scroll would drag its two lenses through the
/// backdrop they are sampling — a shimmer on every frame.
class _PinnedHomeHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHomeHeader({required this.topInset});

  /// `MediaQuery.padding.top`, read in [HomeFeedScreen.build] because
  /// [minExtent]/[maxExtent] are context-free getters.
  final double topInset;

  /// `.iconbtn{width:38px;height:38px}` drawn at 40 here, which is what
  /// sets the row's height — the 38px `.locpill` is the shorter of the two.
  static const double _rowHeight = 40;

  /// The status-bar inset is folded into the pinned extent rather than left
  /// as the separate leading spacer sliver it used to be. That is required,
  /// not tidying: a pinned sliver lays out at scroll offset 0, i.e. flush
  /// under the status bar, so a spacer left scrolling would slide out from
  /// under the header and leave the location pill sitting on the clock.
  ///
  /// `AppSpacing.md` is that spacer's own gap; `AppSpacing.base` is
  /// [HomeHeaderRow]'s top padding, kept inside the row so the row still
  /// lays out identically anywhere else it might be dropped.
  ///
  /// Exposed as a static so [HomeFeedScreen] can hand the same number to its
  /// [RefreshIndicator]'s `edgeOffset` without instantiating a delegate —
  /// the spinner has to start below a header that never scrolls away, and
  /// two independent copies of this arithmetic would drift apart the first
  /// time the row's height changed.
  static double extentFor(double topInset) =>
      topInset + AppSpacing.md + AppSpacing.base + _rowHeight;

  double get _extent => extentFor(topInset);

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  bool shouldRebuild(_PinnedHomeHeader oldDelegate) =>
      oldDelegate.topInset != topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Stack(
      children: [
        // Tight constraints, so the strip takes the header's full height
        // rather than its own status-bar-only intrinsic one.
        const Positioned.fill(child: TopFadeBar()),
        // Loose in the vertical axis: the row keeps its intrinsic
        // `AppSpacing.base + 40`, so the extent above and the layout here
        // cannot drift apart.
        Positioned(
          top: topInset + AppSpacing.md,
          left: 0,
          right: 0,
          child: const HomeHeaderRow(),
        ),
      ],
    );
  }
}
