/// `map-view` (SCREENS.md §3.6) — the pin map of the current search result
/// set, reached from `listing-search`'s map toggle.
///
/// **A full-screen, no-chrome page on the root navigator** (§1's "Full-screen
/// modal (no chrome)" bucket, alongside `photo-gallery`): it paints above
/// the shell's `Scaffold`, so the tab bar is not in its tree at all. That
/// placement is the whole tab-bar-hiding mechanism — see `app_router.dart`.
///
/// ## Where its listings come from
///
/// It **watches [displayedSearchResultsProvider]**, the same provider the
/// results list renders from, rather than treating the `List<Ad>` handed to
/// it via `extra:` as its content. That is what makes the "Filters" button
/// mean anything: applying filters updates the shared provider, and the
/// pins change under the user without a round trip back to the list. A
/// snapshot passed by value would have left the button applying filters to
/// a screen that could not show the result.
///
/// The `extra:` payload is still honoured, as a **fallback** for the cases
/// no caller controls — a deep link straight to `/map-view`, or a restored
/// route stack — exactly the defensive reading `photo_gallery`'s route does
/// with its own untyped `extra`. It is never preferred over live state.
///
/// ## Clustering
///
/// Overlapping pins are merged by `flutter_map_marker_cluster` rather than
/// a hand-rolled density approximation — README.md flagged the honest fix
/// as "a clustering package, not a hand-rolled approximation" and this is
/// that package, restyled in this app's tokens via [MapClusterMarker]. A
/// tap zooms to the cluster's bounds (the package's own default,
/// `zoomToBoundsOnClick`); a tap on a lone pin still reaches
/// [MapPinMarker]'s own `onTap` directly — see `markerChildBehavior` below.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/map/map_attribution.dart';
import '../../../shared/map/map_defaults.dart';
import '../../../shared/map/map_tile_layer_provider.dart';
import '../../../theme/theme.dart';
import '../../filter/filter.dart';
import '../../search/state/search_providers.dart';
import '../data/map_pin.dart';
import 'map_cluster_marker.dart';
import 'map_pin_marker.dart';
import 'map_preview_card.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key, this.fallbackAds = const []});

  /// The `extra:` payload, used only when live search state has nothing —
  /// see this file's doc comment.
  final List<Ad> fallbackAds;

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  /// The ad whose preview card is showing, by id. Held as an id rather than
  /// an [Ad] so a re-fetch that returns a new instance of the same listing
  /// keeps the card open instead of silently closing it.
  String? _selectedAdId;

  final _controller = MapController();

  /// The camera is framed **imperatively, once**, the first time there is a
  /// non-empty pin set — not through `MapOptions.initialCenter`.
  ///
  /// `MapOptions`' initial camera is read exactly once, when [FlutterMap] is
  /// first built, and the first build here routinely has the wrong content:
  /// live results are still in flight, so the frame shows the `extra:`
  /// fallback (or nothing at all). Framing from that and never correcting
  /// left the real pins tens of kilometres off screen with the map sitting
  /// over a stale snapshot — a live-vs-fallback case the widget tests
  /// caught. Moving the camera when the pins actually arrive is the fix.
  ///
  /// Only the *first settled* pin set frames the map, and [settled] is load-
  /// bearing: framing from the fallback while the live fetch is still in
  /// flight points the camera at a stale snapshot, and the real pins then
  /// arrive tens of kilometres outside the viewport — where `MarkerLayer`
  /// culls them and the map looks empty. Waiting for the results provider
  /// to resolve costs one render at city zoom and gets the framing right.
  ///
  /// A later filter change deliberately leaves the camera where the user
  /// put it rather than yanking it out from under them mid-browse.
  bool _cameraFramed = false;

  void _frameCamera(List<MapPin> pins, {required bool settled}) {
    if (_cameraFramed || pins.isEmpty || !settled) return;
    _cameraFramed = true;

    final fit = cameraFitFor(pins);
    // Deferred: this runs during build, and the controller drives the map
    // that build is still producing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (fit != null) {
        _controller.fitCamera(fit);
      } else {
        _controller.move(initialCenterFor(pins), initialZoomFor(pins));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final applied = await showFilterSheet(
      context,
      initialFilters: ref.read(appliedSearchFiltersProvider),
    );
    if (applied == null || !mounted) return;
    ref.read(appliedSearchFiltersProvider.notifier).apply(applied);
    // The previously selected pin may not survive the new filter set.
    setState(() => _selectedAdId = null);
  }

  void _close() {
    // The list is where this screen came from and the only sensible "up".
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final results = ref.watch(displayedSearchResultsProvider);

    final ads = results.value ?? widget.fallbackAds;
    final pins = pinnableAds(ads);
    _frameCamera(pins, settled: !results.isLoading);

    final selected = _selectedAdId == null
        ? null
        : ads.where((ad) => ad.id == _selectedAdId).firstOrNull;

    return Scaffold(
      backgroundColor: colors.screen,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                // Always the whole-city default; the real framing happens in
                // `_frameCamera` once there are pins to frame.
                initialCenter: MapDefaults.tashkent,
                initialZoom: MapDefaults.cityZoom,
                // Tapping bare map dismisses the preview card — the
                // gesture a user reaches for before hunting for a close
                // button.
                onTap: (tapPosition, point) =>
                    setState(() => _selectedAdId = null),
              ),
              children: [
                ref.watch(mapTileLayerProvider),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    // The key lives on the child (MapPinMarker), not on the
                    // Marker itself: the cluster package stamps
                    // `Marker.key` onto two different internal wrapper
                    // widgets it builds per pin, so a `find.byKey` in tests
                    // would match both and `findsOneWidget` would fail.
                    // Keying the actual visible widget keeps one key, one
                    // match.
                    markers: [
                      for (final pin in pins)
                        Marker(
                          point: pin.point,
                          width: MapPinMetrics.width,
                          height: MapPinMetrics.height,
                          child: MapPinMarker(
                            key: ValueKey('mapPin-${pin.ad.id}'),
                            ad: pin.ad,
                            selected: pin.ad.id == _selectedAdId,
                            onTap: () =>
                                setState(() => _selectedAdId = pin.ad.id),
                          ),
                        ),
                    ],
                    // Same padding `cameraFitFor` uses for the initial
                    // multi-pin fit, so a cluster tap frames its bounds the
                    // same way the screen frames the whole result set.
                    padding: const EdgeInsets.all(56),
                    computeSize: (markers) =>
                        Size.square(MapClusterMetrics.sizeFor(markers.length)),
                    // MapPinMarker already carries its own GestureDetector
                    // (selection has to work the same whether a pin ever
                    // clusters or not); this stops the package from
                    // wrapping it in a second, competing one. Cluster taps
                    // are unaffected — that gesture lives in ClusterWidget,
                    // one level up, not on markerChildBehavior.
                    markerChildBehavior: true,
                    builder: (context, markers) =>
                        MapClusterMarker(count: markers.length),
                  ),
                ),
                // OSM's licence requires visible attribution — not optional
                // chrome. Sits above the pins so it is never covered.
                const MapAttribution(),
              ],
            ),
          ),
          _MapTopBar(onBack: _close, onShowList: _close),
          if (results.isLoading && ads.isEmpty)
            const Positioned.fill(child: _MapLoadingVeil())
          else if (pins.isEmpty)
            // An empty map centred on Tashkent with no pins and no
            // explanation reads as broken, not as "no matches" — see
            // README.md's map-view gap note this closes.
            Positioned.fill(child: _MapEmptyState(hasResults: ads.isNotEmpty)),
          Positioned(
            left: AppSpacing.screenGutter,
            right: AppSpacing.screenGutter,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.section,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selected != null) ...[
                  MapPreviewCard(
                    ad: selected,
                    onTap: () =>
                        context.push('/search/listing/${selected.id}'),
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
                _MapFooterRow(
                  pinnedCount: pins.length,
                  totalCount: ads.length,
                  onFilters: _openFilters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Back and list-toggle, both of which do the same thing — SCREENS.md §3.6
/// specifies "back arrow → `listing-search`" *and* a "list-icon toggle back
/// to list", which from a pushed full-screen page are the same journey. Both
/// are rendered because both are in the spec and a user reaches for
/// whichever they expect; neither is a different destination.
class _MapTopBar extends StatelessWidget {
  const _MapTopBar({required this.onBack, required this.onShowList});

  final VoidCallback onBack;
  final VoidCallback onShowList;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Positioned(
      top: AppSpacing.base,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _RoundGlassButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: l10n.mapNavBackSemanticsLabel,
              onTap: onBack,
            ),
            const SizedBox(width: AppSpacing.base),
            GlassSurface(
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Text(
                l10n.mapTitleLabel,
                style: type.rowTitle.copyWith(color: Colors.white),
              ),
            ),
            const Spacer(),
            _RoundGlassButton(
              icon: Icons.format_list_bulleted_rounded,
              semanticLabel: l10n.mapShowListSemanticsLabel,
              onTap: onShowList,
            ),
          ],
        ),
      ),
    );
  }
}

/// The floating "Filters" button §3.6 asks for, plus the pin count.
///
/// **The count is two numbers, not one**, whenever they differ: an ad with
/// no coordinates cannot be drawn (see `map_pin.dart`), and a map silently
/// showing 6 pins for 8 results is a map that lies about the result set.
/// "6 of 8 on the map" is the smallest honest way to say it.
class _MapFooterRow extends StatelessWidget {
  const _MapFooterRow({
    required this.pinnedCount,
    required this.totalCount,
    required this.onFilters,
  });

  final int pinnedCount;
  final int totalCount;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        GlassSurface(
          borderRadius: AppRadii.pill,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            pinnedCount == totalCount
                ? l10n.mapPinnedAllCountLabel(pinnedCount)
                : l10n.mapPinnedPartialCountLabel(pinnedCount, totalCount),
            style: type.micro.copyWith(color: Colors.white),
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: AppAccent.color,
                borderRadius: AppRadii.pill,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.mapFiltersButtonLabel,
                    style: type.label.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Covers the map while the very first result set is still in flight, so
/// the user isn't looking at an empty city wondering whether that is the
/// answer. Only shown when there is genuinely nothing to draw yet — a
/// filter change over existing pins re-renders in place instead.
class _MapLoadingVeil extends StatelessWidget {
  const _MapLoadingVeil();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return ColoredBox(
      color: colors.screen.withValues(alpha: 0.72),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Shown centred over the map once loading has settled and there is
/// genuinely nothing to plot — a silent map at the Tashkent default reads as
/// broken, not as "no matches", and the footer's "0 of N on the map" chip
/// alone is too easy to miss against a full screen of empty tiles.
///
/// Deliberately a small floating card rather than [FullWidthState]: that
/// widget assumes a scrollable list's own background, and the surface here
/// is map imagery a plain icon+text pair would be unreadable against.
class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.hasResults});

  /// True when the search returned listings but none carried coordinates;
  /// false when the search itself returned nothing. "No matches" and
  /// "matches with no saved location" are different problems and get
  /// different copy.
  final bool hasResults;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadii.cardLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasResults
                      ? Icons.location_off_rounded
                      : Icons.search_off_rounded,
                  color: colors.faint,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  hasResults
                      ? AppLocalizations.of(
                          context,
                        ).mapNoLocationResultsMessage
                      : AppLocalizations.of(context).mapNoResultsMessage,
                  textAlign: TextAlign.center,
                  style: type.body.copyWith(color: colors.ink2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.rnd` over the map — same 42px glass circle `listing_detail_nav.dart`
/// floats over its hero, for the same reason: the surface underneath is
/// imagery, not app chrome.
class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onPhoto,
          borderRadius: AppRadii.pill,
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
