/// `listing-search` (SCREENS.md §3.4) — the Search tab's root page,
/// `RoutePaths.search`. Merges web's `/list`: search bar, recent searches,
/// inline sort, and the results list, plus entry points to `filter-sheet`
/// (a bottom sheet — `features/filter`'s `showFilterSheet`) and `map-view`
/// (a top-level route reached via `extra:`, see this file's `_openMap`).
///
/// **Router wiring (for the integration agent)**: this screen takes no
/// constructor arguments and reads no path params — swap
/// `app_router.dart`'s `/search` branch-root placeholder for
/// `const SearchScreen()`:
/// ```dart
/// import 'package:lacasa_mobile/features/search/search.dart';
/// // ...
/// GoRoute(
///   path: RoutePaths.search,
///   builder: (context, state) => const SearchScreen(),
///   routes: [ ...unchanged... ],
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../../filter/filter.dart';
// The args type only — see the note on the same import in
// `listing_location_section.dart`.
import '../../map_view/map_view_args.dart';
import '../state/search_providers.dart';
import 'recent_searches_row.dart';
import 'search_bar_row.dart';
import 'search_results_list.dart';
import 'search_toolbar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Owned here rather than by [SearchResultsList] because the results are
  /// one sliver among several in this screen's single `CustomScrollView`
  /// (the mockup's `.body`), so the scroller the infinite-scroll listener
  /// has to watch is this screen's, not the list's own.
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectRecent(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    ref.read(searchQueryProvider.notifier).setQuery(query);
    ref.read(recentSearchesProvider.notifier).addQuery(query);
  }

  /// `filter-sheet`'s half of the seam `search_providers.dart` documents:
  /// the sheet owns its own form state and hands back an [AdFilters] on
  /// "Apply Filters", or null on any dismissal. Applying it here is what
  /// re-triggers `searchResultsProvider`'s fetch, since that notifier
  /// watches `appliedSearchFiltersProvider`.
  Future<void> _openFilters() async {
    final applied = await showFilterSheet(
      context,
      initialFilters: ref.read(appliedSearchFiltersProvider),
    );
    if (applied == null || !mounted) return;
    ref.read(appliedSearchFiltersProvider.notifier).apply(applied);
  }

  void _openMap() {
    final currentResults =
        ref.read(displayedSearchResultsProvider).value ?? const <Ad>[];
    // Search mode is the default, so this snapshot is still only the
    // fallback the screen falls back *to* — it keeps preferring live search
    // state. Sent as `MapViewArgs` rather than a bare list purely so the
    // route has one payload type to read; behaviour here is unchanged.
    context.push(RoutePaths.mapView, extra: MapViewArgs(ads: currentResults));
  }

  void _openListingDetail(Ad ad) {
    context.push('/search/listing/${ad.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // No screen title: the mockup's `<header class="nav nav--stack">`
            // holds only the search field and the Cancel link — unlike
            // `agents-directory`, this screen has no `.nav__t`. The header is
            // the *only* thing pinned above the scroller; everything the
            // mockup puts inside `.body` scrolls together below it.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                0,
              ),
              child: SearchBarRow(
                controller: _controller,
                focusNode: _focusNode,
              ),
            ),
            Expanded(
              // Pull-to-refresh over the *whole* scroller, not just the
              // results sliver: it is one gesture and it reloads one thing
              // (`searchResultsProvider`), which is the shape a
              // [RefreshIndicator] models honestly — the same reasoning
              // `agents_directory_screen.dart` records for its own.
              //
              // Search is the weakest case for this in the app (any query,
              // sort or filter change already re-fetches page 1), and it is
              // still worth having: nothing else on this screen re-runs a
              // search whose *inputs* haven't changed, so a listing that
              // went live a minute ago is otherwise unreachable without
              // typing something and typing it back.
              //
              // `ScrollConfiguration(overscroll: false)` sits *inside* the
              // indicator deliberately. It suppresses Android's stretch
              // overscroll glow — see `glass_surface.dart`'s doc comment:
              // any Scrollable holding a GlassSurface (RowListingCard's
              // badge/favourite overlays) renders the lens black at the
              // scroll edges without it — and it does not touch the
              // [RefreshIndicator], which is a separate widget above the
              // scrollable rather than a scroll-behaviour indicator.
              child: RefreshIndicator(
                key: const ValueKey('searchRefreshIndicator'),
                onRefresh: () => ref.refresh(searchResultsProvider.future),
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: CustomScrollView(
                    controller: _scrollController,
                    // Without this the pull gesture is dead exactly when it
                    // is most wanted: an empty or errored result set leaves
                    // the scroller shorter than its viewport, and the
                    // default physics refuse to overscroll content that
                    // doesn't fill the screen.
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Recents, the toolbar and the results are all
                      // children of the mockup's one `.body` scroller, so
                      // the chips and the sort strip scroll away with the
                      // results instead of holding ~200px of a phone
                      // viewport permanently.
                      //
                      // The leading gap lives inside `RecentSearchesRow`'s
                      // data branch so it collapses with the row when there
                      // are no recents, instead of stacking two section gaps
                      // into a dead band.
                      SliverToBoxAdapter(
                        child: RecentSearchesRow(onSelect: _onSelectRecent),
                      ),
                      // `.tools{margin-top:16px}`.
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenGutter,
                          ),
                          child: SearchToolbar(
                            onOpenFilters: _openFilters,
                            onOpenMap: _openMap,
                          ),
                        ),
                      ),
                      // `<div class="stack" style="margin-top:14px">` — the
                      // toolbar-to-first-card lead-in, for which `base` is
                      // the nearest token. The results sliver adds no
                      // vertical padding of its own, so this is the whole
                      // gap.
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.base),
                      ),
                      SearchResultsList(
                        onTapAd: _openListingDetail,
                        scrollController: _scrollController,
                      ),
                      // `.body{padding-bottom:var(--pb,104px)}` — inside the
                      // scroller, not below it, so the last card passes
                      // *under* the floating glass tab bar (see
                      // `tab_shell_scaffold.dart`) instead of stopping above
                      // a permanent band of bare screen.
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 100,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
