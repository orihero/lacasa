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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
    context.push(RoutePaths.mapView, extra: currentResults);
  }

  void _openListingDetail(Ad ad) {
    context.push('/search/listing/${ad.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                0,
              ),
              child: Text(
                'Search',
                style: type.navTitle.copyWith(color: colors.ink),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: SearchBarRow(controller: _controller, focusNode: _focusNode),
            ),
            const SizedBox(height: AppSpacing.section),
            RecentSearchesRow(onSelect: _onSelectRecent),
            const SizedBox(height: AppSpacing.section),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: SearchToolbar(
                onOpenFilters: _openFilters,
                onOpenMap: _openMap,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Expanded(
              // See `glass_surface.dart`'s doc comment: any Scrollable
              // holding a GlassSurface (FullListingCard's favourite/price
              // pills) must disable Android's stretch overscroll or the
              // lens renders black at the scroll edges.
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: SearchResultsList(onTapAd: _openListingDetail),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
          ],
        ),
      ),
    );
  }
}
