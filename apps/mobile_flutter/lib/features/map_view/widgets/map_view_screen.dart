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
/// In its default (search) mode it **watches [searchResultsProvider]**, the
/// same provider the results list renders from, rather than treating the
/// `List<Ad>` handed to it via `extra:` as its content. That is what makes
/// the "Filters" button mean anything: applying filters updates the shared
/// provider, and the pins change under the user without a round trip back
/// to the list. A snapshot passed by value would have left the button
/// applying filters to a screen that could not show the result.
///
/// It watches the *paged* provider rather than the unwrapped
/// `displayedSearchResultsProvider` specifically so it can see
/// [SearchResultsPage.nextCursor] — see "How much of the market is on the
/// map" below.
///
/// ## When the pins on screen are not the answer
///
/// Riverpod hands a *reloading* provider back as `AsyncLoading` that still
/// carries the previous value, and an `AsyncError` raised by a reload keeps
/// it too (`AsyncValue.copyWithPrevious`). Read naively that is a map which
/// answers a filter the user has already replaced — silently for the whole
/// round trip, and permanently if the re-fetch throws.
///
/// The fix is deliberately *not* to blank the pins into a skeleton the way
/// the results list does. A skeleton is right for a list, whose rows carry
/// no state of their own; this map carries the user's pan and zoom, and a
/// map with no pins is already this screen's picture for "no matches" — so
/// blanking it would throw away their orientation to show them a different,
/// possibly wrong, answer. Instead the stale pins stay and the chrome says
/// they are stale: [_MapUpdatingNote] while the re-fetch is in flight,
/// [_MapResultsErrorNote] (with a retry) when it failed. What does *not*
/// survive the window is [_MapPartialResultsNote] — see its gate in `build`.
///
/// The `extra:` payload is still honoured, as a **fallback** for the cases
/// no caller controls — a deep link straight to `/map-view`, or a restored
/// route stack — exactly the defensive reading `photo_gallery`'s route does
/// with its own untyped `extra`. It is never preferred over live state.
///
/// ## How much of the market is on the map
///
/// `GET /ads` answers 20 rows by default and the map has no scroll of its
/// own, so a search matching 500 listings used to open a map of 20 pins
/// with the camera fitted neatly around them — a picture that says "this is
/// the market" about 4% of it. The camera fit made it worse, not better:
/// the closer the frame hugs the pins, the more complete the extent looks.
///
/// So whenever the current page still has a [SearchResultsPage.nextCursor],
/// [_MapPartialResultsNote] says so above the Filters button — "Showing the
/// first 20 matches · Load more" — and its action calls the same
/// [SearchResultsNotifier.loadMore] the results list's infinite scroll
/// calls, so the pins the user asks for land on this screen and in the list
/// behind it at once.
///
/// **The dropped-pins note still counts loaded ads, not matched ones**, and
/// that is a wire limitation rather than a choice: `AdPage` carries `items`
/// and `nextCursor` and no total, so "17 of 500 on the map" is a number
/// this client cannot know. What it *can* know is "there are more than
/// these", which is exactly what [_MapPartialResultsNote] renders directly
/// beneath it — the two chips together read "17 of 20 on the map" /
/// "Showing the first 20 matches · Load more", which is honest. Give
/// `GET /ads?paged=true` a `total` and the note can take the real
/// denominator with no other change.
///
/// ## Opened from one listing ([MapViewScreen.focusAd])
///
/// SCREENS.md §3.7's Location section pushes here to answer one question —
/// "where is *this* flat?". Watching the search provider for that entry was
/// a defect: a buyer who tapped one listing's map got, a second later, up
/// to 20 unrelated listings, the camera framed around all of them, their
/// own listing unselected, and a Filters button for a search they never
/// ran. [focusAd] is that entry's mode. It suppresses the search watch
/// entirely (so no fetch is even started), plots and pre-selects the single
/// ad, and hides both the Filters button and the partial-results note,
/// neither of which means anything when the content is one property.
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
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../filter/filter.dart';
import '../../search/state/search_providers.dart';
import '../data/map_pin.dart';
import 'map_cluster_marker.dart';
import 'map_pin_marker.dart';
import 'map_preview_card.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({
    super.key,
    this.fallbackAds = const [],
    this.focusAd,
    this.branchPrefix = RoutePaths.search,
  });

  /// The `extra:` payload, used only when live search state has nothing —
  /// see this file's doc comment.
  final List<Ad> fallbackAds;

  /// Set by a caller that opened this map to answer "where is *this* one?"
  /// — `listing-detail`'s Location section. Non-null puts the screen in the
  /// single-listing mode described in this file's doc comment: the search
  /// provider is not watched at all, this ad is the whole content, and it
  /// opens pre-selected.
  final Ad? focusAd;

  /// The shell branch this map was opened from, used to build the preview
  /// card's push target — the same contract `ListingDetailScreen` and
  /// `AgentProfileScreen` already take. It used to be hardcoded `/search`,
  /// which grafted a detail page onto the Search tab's stack for a listing
  /// the user had reached from Home.
  final String branchPrefix;

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  /// The ad whose preview card is showing, by id. Held as an id rather than
  /// an [Ad] so a re-fetch that returns a new instance of the same listing
  /// keeps the card open instead of silently closing it.
  String? _selectedAdId;

  @override
  void initState() {
    super.initState();
    // Single-listing mode opens with its one ad already selected: the user
    // asked about that property, so making them hunt for and tap its pin to
    // see which one it is would be asking the question back at them. Gated
    // on `hasPin` because an ad with no coordinates draws no pin and gets
    // `_MapEmptyState` instead — a preview card floating over "we don't
    // know where this is" would be a second, contradictory answer.
    final focusAd = widget.focusAd;
    if (focusAd != null && focusAd.hasPin) _selectedAdId = focusAd.id;
  }

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
    final focusAd = widget.focusAd;

    // Deliberately a conditional watch: in single-listing mode subscribing
    // to `searchResultsProvider` would *start* the search fetch (its
    // `build` is the request), which is the whole defect §4.5 records.
    // Riverpod drops a dependency that a rebuild didn't re-watch, and
    // `focusAd` never changes for a given widget, so the subscription set
    // here is stable.
    final results = focusAd == null
        ? ref.watch(searchResultsProvider)
        : null;
    final page = results?.value;

    final ads = focusAd != null
        ? <Ad>[focusAd]
        : (page?.items ?? widget.fallbackAds);
    final isLoading = results?.isLoading ?? false;

    // The two flags that keep this screen from presenting a superseded
    // answer as the current one — see this file's "When the pins on screen
    // are not the answer".
    //
    // `isStale` is the case with something already drawn: the pins below are
    // the *previous* filter set's (or the `extra:` snapshot's) and a fetch is
    // in flight to replace them. When there is nothing drawn at all the
    // [_MapLoadingVeil] already covers the wait, which is why this is not
    // simply `isLoading`.
    //
    // `failure` is deliberately suppressed while a fetch is in flight:
    // Riverpod 3's AsyncValue can be `hasError` and `isLoading` at once (a
    // retry over a failed load), and an error a new attempt is already
    // answering is not worth putting in front of the user.
    final isStale = isLoading && ads.isNotEmpty;
    final failure = isLoading ? null : results?.error;

    final pins = pinnableAds(ads);
    _frameCamera(pins, settled: !isLoading);

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
          if (isLoading && ads.isEmpty)
            const Positioned.fill(child: _MapLoadingVeil())
          else if (pins.isEmpty && failure == null)
            // An empty map centred on Tashkent with no pins and no
            // explanation reads as broken, not as "no matches" — see
            // README.md's map-view gap note this closes.
            //
            // Gated on there being no [failure] because "No listings match
            // your search" is a claim about the market, and a fetch that
            // never came back is not evidence for it. That case gets
            // [_MapResultsErrorNote]'s sentence (and its retry) instead.
            Positioned.fill(child: _MapEmptyState(hasResults: ads.isNotEmpty)),
          Positioned(
            left: AppSpacing.screenGutter,
            right: AppSpacing.screenGutter,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.section,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // `.map__flt` is centred *above* the preview card
                // (`bottom:214px` vs the card's `bottom:96px`), not in a row
                // beside a count pill.
                if (pins.length != ads.length)
                  _DroppedPinsNote(
                    pinnedCount: pins.length,
                    totalCount: ads.length,
                  ),
                // One slot directly above the Filters button, for whatever
                // is currently true about the result set — they are the same
                // kind of statement ("there is more of this search than you
                // can see" / "this isn't the answer yet" / "we couldn't get
                // the answer") and sit next to the control that caused it.
                //
                // The order is not arbitrary. [_MapPartialResultsNote] must
                // not render while the set behind it is superseded: its tap
                // calls `SearchResultsNotifier.loadMore`, which reads
                // `state.value` — the old page — and immediately assigns
                // `AsyncData`, clearing the in-flight reload's loading flag,
                // firing a request against the *old* cursor, and getting
                // overwritten by the reload it just made invisible.
                if (isStale)
                  const _MapUpdatingNote()
                else if (failure != null)
                  _MapResultsErrorNote(
                    error: failure,
                    onRetry: () => ref.invalidate(searchResultsProvider),
                  )
                else if (page != null && page.nextCursor != null)
                  _MapPartialResultsNote(
                    loadedCount: ads.length,
                    isLoadingMore: page.isLoadingMore,
                    onLoadMore: () =>
                        ref.read(searchResultsProvider.notifier).loadMore(),
                  ),
                if (focusAd == null)
                  Center(child: _MapFiltersButton(onTap: _openFilters)),
                if (selected != null) ...[
                  const SizedBox(height: AppSpacing.base),
                  MapPreviewCard(
                    ad: selected,
                    onTap: () => context.push(
                      '${widget.branchPrefix}/listing/${selected.id}',
                    ),
                  ),
                ],
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
            // `.nav__t--pill{height:38px;border-radius:19px;padding:0 15px;
            // font-size:12.5px;font-weight:600;color:#1b1b23}` — dark ink on
            // light glass, not white: the glass is light and the tiles below
            // it are lighter still.
            GlassSurface(
              borderRadius: AppRadii.pill,
              height: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                l10n.mapTitleLabel,
                style: type.rowTitle.copyWith(
                  fontSize: 12.5,
                  color: mapChromeInk,
                ),
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

/// The floating "Filters" button §3.6 asks for: `<button class="btn btn--sm
/// btn--ink map__flt">` — `.btn--ink{background:var(--pill);color:var(
/// --pill-ink)}`, `.btn--sm{height:44px;border-radius:22px;padding:0 18px;
/// font-size:12.5px}` — centred over the map, not an accent-pink button
/// pushed to the right edge.
class _MapFiltersButton extends StatelessWidget {
  const _MapFiltersButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colors.pill,
            borderRadius: AppRadii.pill,
            boxShadow: AppShadows.selectedPillLarge,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16, color: colors.pillInk),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.mapFiltersButtonLabel,
                style: type.rowTitle.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.pillInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Only rendered when the two counts differ.** An ad with no coordinates
/// cannot be drawn (see `map_pin.dart`), and a map silently showing 6 pins
/// for 8 results is a map that lies about the result set — "6 of 8 on the
/// map" is the smallest honest way to say so.
///
/// The mockup has no counter of any kind, and it is right about the common
/// case: when every result *is* plotted, "8 on the map" restates what the
/// user can already see and costs a pill of chrome to do it. So the honest
/// note survives, and only in the case that makes it honest.
class _DroppedPinsNote extends StatelessWidget {
  const _DroppedPinsNote({required this.pinnedCount, required this.totalCount});

  final int pinnedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: GlassSurface(
          borderRadius: AppRadii.pill,
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            l10n.mapPinnedPartialCountLabel(pinnedCount, totalCount),
            style: type.micro.copyWith(color: mapChromeInk),
          ),
        ),
      ),
    );
  }
}

/// **The map's one admission that it is not showing the whole market**, and
/// the only way to make it show more.
///
/// `GET /ads` answers 20 rows a page; the results *list* hides that with an
/// infinite scroll, and the map, having no scroll at all, used to hide it
/// completely — 20 pins under a camera fitted snugly around them, with no
/// gesture anywhere on the screen that could add a 21st. This chip is
/// rendered exactly when [SearchResultsPage.nextCursor] is non-null, i.e.
/// exactly when the sentence is true.
///
/// **The whole chip is the button**, not just the "Load more" half: it is a
/// floating 34dp pill over map imagery, and splitting a 10px caption into a
/// dead part and a live part at that size gives the user a target they have
/// to aim at. [TapTarget] then lifts the hit box to 48dp of transparent
/// padding, same as every other small control in the app.
///
/// Tapping calls the same [SearchResultsNotifier.loadMore] the results
/// list's scroll listener calls — one cursor, one page, shared state — so
/// the pins the user asks for here are also in the list when they toggle
/// back to it. `loadMore` is its own re-entrancy guard, which is why the
/// in-flight spinner replaces the label without also blocking the tap.
class _MapPartialResultsNote extends StatelessWidget {
  const _MapPartialResultsNote({
    required this.loadedCount,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  /// How many matches are actually plotted-or-droppable right now — the
  /// loaded page, which is what "the first {n}" means. Not a total: the
  /// wire carries none (see this file's doc comment).
  final int loadedCount;

  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final countLabel = l10n.mapPartialResultsLabel(loadedCount);
    final actionLabel = l10n.sharedLoadMoreLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: TapTarget(
          key: const ValueKey('mapLoadMore'),
          semanticsLabel: '$countLabel · $actionLabel',
          onTap: onLoadMore,
          child: GlassSurface(
            borderRadius: AppRadii.pill,
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flexible + ellipsis so the ru/uz renderings of both
                // halves (~30% longer) shorten the caption rather than
                // overflowing the pill on a 360dp phone.
                Flexible(
                  child: Text(
                    countLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.micro.copyWith(color: mapChromeInk),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '·',
                  style: type.micro.copyWith(color: mapChromeInk),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (isLoadingMore)
                  const SizedBox(
                    key: ValueKey('mapLoadMoreSpinner'),
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.micro.copyWith(
                      color: AppAccent.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// **Says the pins under it belong to the filter set the user just
/// replaced.**
///
/// Applying filters re-runs [searchResultsProvider], and a reload keeps its
/// previous value, so for the whole round trip this map draws the *old*
/// answer. Before this chip existed the sheet simply closed and nothing
/// changed — no spinner, no veil, no dimming — and then, a second later, the
/// pins silently swapped. A user who filtered to 2-room flats spent that
/// window reading a map of 1-room ones with no way to tell.
///
/// Deliberately the smallest possible statement rather than the
/// [_MapLoadingVeil] or a skeleton: see this file's "When the pins on screen
/// are not the answer" for why blanking a map costs more than it buys. The
/// pill borrows [_MapPartialResultsNote]'s exact geometry because it takes
/// that widget's slot while it is showing.
class _MapUpdatingNote extends StatelessWidget {
  const _MapUpdatingNote();

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: GlassSurface(
          key: const ValueKey('mapUpdatingNote'),
          borderRadius: AppRadii.pill,
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.mapUpdatingResultsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.micro.copyWith(color: mapChromeInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **The failed-fetch half of the same problem.** An [AsyncError] raised by
/// a reload retains the previous value exactly as [AsyncLoading] does, so a
/// filter apply that throws used to leave the pre-filter pins, the
/// pre-filter counts and the Load-more chip on screen *forever*, with no
/// message and no way to try again — the one state where "re-render in
/// place" is indistinguishable from the app working.
///
/// The copy comes from [describeReadError], not from a string of this
/// screen's own, so that a connectivity failure says "you are offline" here
/// in the same words every other read surface uses (see
/// `shared/widgets/read_error.dart` for why one fact must not read as a
/// dozen unrelated ones). Its non-offline fallback is `search`'s own
/// [AppLocalizations.searchResultsRetryMessage] rather than a duplicate
/// `map`-prefixed key: this pill and `search_results_list`'s error state
/// report the *same failure of the same provider*, and giving the two
/// surfaces two different sentences for it would be the same defect at
/// smaller scale.
///
/// Sized by its content rather than pinned to the 34dp pill height: the
/// offline sentence is long, and a capsule that clips it to "No connection.
/// Check your netw…" would be a status chip that withholds the status.
class _MapResultsErrorNote extends StatelessWidget {
  const _MapResultsErrorNote({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final message = describeReadError(
      l10n,
      error,
      fallback: l10n.searchResultsRetryMessage,
    );
    final actionLabel = l10n.sharedRetryLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: TapTarget(
          key: const ValueKey('mapResultsError'),
          semanticsLabel: '$message · $actionLabel',
          onTap: onRetry,
          child: GlassSurface(
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(readErrorIcon(error), size: 14, color: mapChromeInk),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.micro.copyWith(color: mapChromeInk),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  actionLabel,
                  maxLines: 1,
                  style: type.micro.copyWith(
                    color: AppAccent.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Covers the map while the very first result set is still in flight, so
/// the user isn't looking at an empty city wondering whether that is the
/// answer. Only shown when there is genuinely nothing to draw yet — a
/// filter change over existing pins keeps those pins and labels them stale
/// with [_MapUpdatingNote] instead, for the reasons in this file's "When the
/// pins on screen are not the answer".
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
                      ? AppLocalizations.of(context).mapNoLocationResultsMessage
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

/// `.nav .rnd{width:38px;height:38px;font-size:18px;color:var(--ink)}` — the
/// map's chrome sits inside a `.nav`, so it takes the dark-ink treatment
/// rather than `.rnd`'s white-on-photo default. White glyphs on light glass
/// over light OSM tiles are close to invisible.
const Color mapChromeInk = Color(0xFF1B1B23);

/// `.nav .rnd` over the map — a 38px glass circle with a dark ink glyph.
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
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: mapChromeInk),
        ),
      ),
    );
  }
}
