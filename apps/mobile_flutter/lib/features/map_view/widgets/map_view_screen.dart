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
/// ## What it does not do
///
/// Nothing here clusters overlapping pins. At Tashkent-wide zoom a dense
/// result set will overlap, and the honest fix is a clustering package, not
/// a hand-rolled approximation — flagged in the README rather than faked.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/map/map_attribution.dart';
import '../../../shared/map/map_defaults.dart';
import '../../../shared/map/map_tile_layer_provider.dart';
import '../../../theme/theme.dart';
import '../../filter/filter.dart';
import '../../search/state/search_providers.dart';
import '../data/map_pin.dart';
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
                MarkerLayer(
                  markers: [
                    for (final pin in pins)
                      Marker(
                        key: ValueKey('mapPin-${pin.ad.id}'),
                        point: pin.point,
                        width: MapPinMetrics.width,
                        height: MapPinMetrics.height,
                        child: MapPinMarker(
                          ad: pin.ad,
                          selected: pin.ad.id == _selectedAdId,
                          onTap: () =>
                              setState(() => _selectedAdId = pin.ad.id),
                        ),
                      ),
                  ],
                ),
                // OSM's licence requires visible attribution — not optional
                // chrome. Sits above the pins so it is never covered.
                const MapAttribution(),
              ],
            ),
          ),
          _MapTopBar(onBack: _close, onShowList: _close),
          if (results.isLoading && ads.isEmpty)
            const Positioned.fill(child: _MapLoadingVeil()),
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
              semanticLabel: 'Back',
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
                'Map',
                style: type.rowTitle.copyWith(color: Colors.white),
              ),
            ),
            const Spacer(),
            _RoundGlassButton(
              icon: Icons.format_list_bulleted_rounded,
              semanticLabel: 'Show list',
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
                ? '$pinnedCount on the map'
                : '$pinnedCount of $totalCount on the map',
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
                    'Filters',
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
