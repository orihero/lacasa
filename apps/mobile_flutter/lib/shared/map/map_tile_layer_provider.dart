/// The seam between the app's map surfaces and the tile server.
///
/// Every map in the app gets its base layer from here rather than
/// constructing a [TileLayer] inline. Two reasons, in order of importance:
///
/// 1. **Tiles are a network dependency, and this codebase puts every
///    network dependency behind an overridable provider** — that is the
///    same rule `home_feed_repository_provider.dart` and its siblings
///    follow. A widget test that pumps a map otherwise fires real HTTP
///    requests at OpenStreetMap's servers from CI, which is both slow and
///    a straightforward violation of their usage policy.
/// 2. The OSM attribution and User-Agent are licence obligations
///    ([MapDefaults]), and a single construction site is the only way to
///    be sure no map surface ships without them.
/// 3. **Every map surface needs the same Impeller workaround** — see
///    [TileCompositingPrimer] below — and a shared construction site is
///    what lets `map-view` and `listing-detail`'s Location preview both get
///    it for free instead of each screen remembering to wire it up itself.
///
/// Tests override this with a plain coloured box; nothing about the widget
/// under test changes, because a base layer is a base layer.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../api/app_mode.dart';
import 'map_defaults.dart';

final mapTileLayerProvider = Provider<Widget>((ref) {
  return TileCompositingPrimer(
    child: TileLayer(
      urlTemplate: MapDefaults.osmTileUrl,
      userAgentPackageName: MapDefaults.tileUserAgent,
      // A tile that fails to load leaves its cell empty rather than throwing
      // — a patchy connection should dim the map, not take the screen down.
      errorTileCallback: (tile, error, stackTrace) {},
    ),
  );
});

/// Works around a flutter_map 8.3.1 + Impeller gap on Android where a tile
/// that finishes loading while the engine is otherwise idle gets rasterised
/// but never composited to the screen — confirmed by a live device sweep
/// (N1): tiles fetch with a 200 OK, `TileImage` calls `notifyListeners()`,
/// which reaches `Tile`'s own `setState` — but nothing paints until the
/// user's next touch.
///
/// **A single programmatic camera move is not enough.** `map_view_screen.dart`
/// already frames the camera imperatively the moment pins arrive
/// (`MapController.move`/`fitCamera`), and a live sweep still found grey
/// tiles after that. A first attempt at fixing this ran a content-free
/// `Ticker` in `map_view_screen.dart` purely to keep `SchedulerBinding`
/// producing frames — it changed no pixels and moved nothing. **That did
/// not work on device either**, and a follow-up sweep pinned down why: a
/// second live test isolated the two variables separately —
///   * a plain **tap** on the map (a real, engine-level touch event, no
///     camera movement) left the tiles grey;
///   * a small **drag** (real geometry change to the map's transform across
///     several consecutive frames) painted every tile instantly.
/// So the deciding factor was never "a real touch happened" (the content-
/// free ticker's frames were real engine frames too, and a bare tap is a
/// real touch) — it is specifically **the map's own transform changing
/// across a sequence of separate frames**. `FlutterMap` wraps its whole
/// subtree in one `RepaintBoundary` (`flutter_map`'s `widget.dart`); the
/// working theory is that Impeller's cache for that boundary's composited
/// output isn't being invalidated by a leaf `Tile`'s own repaint alone on
/// this engine/device combination, but reliably is once something upstream
/// of it — the camera transform — genuinely changes.
///
/// **The fix**: manufacture that sequence programmatically. A few times a
/// second, for a short priming window after this layer first has a
/// `MapController` to drive, nudge the camera centre by a sub-pixel epsilon
/// and back — a two-frame "wobble" too small to ever be seen, but which is
/// a *bona fide* [MapController.move] on each half (a different `LatLng`
/// each call, so `flutter_map` doesn't no-op it — see `MapControllerImpl
/// .moveRaw`'s early return when the new camera equals the old one) and so
/// drives the same real, multi-frame transform-change path a drag does.
/// Reading [MapController.camera] fresh before every "nudge out" step
/// (rather than caching a target once) means this rides alongside whatever
/// legitimate camera move `map_view_screen.dart`'s own framing logic is
/// doing at the same time instead of fighting it — it always corrects back
/// to wherever the real camera actually is, not a stale snapshot.
///
/// **Why this lives here and not in `map_view_screen.dart`.** `map-view`
/// and `listing-detail`'s Location preview both hit the same bug (same
/// sweep, both surfaces), and only this file — the shared construction
/// site for every `TileLayer` in the app — is visible to both. A fix
/// living in one screen's `State` would never reach the other.
///
/// **What was considered and set aside:**
///  * `TileLayer.reset` — replays the exact same "tile completes, calls
///    `setState`" path that's already established not to composite on its
///    own; it doesn't touch the camera transform, so the sweep's own
///    tap-vs-drag result predicts (and a dry run confirmed by inspection of
///    `_resetStreamHandler` agrees) it would not have helped.
///  * `TileLayer.tileBuilder` — wraps how a tile is *built*, not whether an
///    already-built tile gets composited; orthogonal to this bug.
///  * A `RepaintBoundary` placement change — the one that matters
///    (`FlutterMap`'s own) lives inside the `flutter_map` package, outside
///    every file this fix is allowed to touch.
///
/// Skipped under `flutter test`: [isRunningUnderFlutterTest] mirrors the
/// same guard `app_mode.dart` uses for network calls. `flutter test`'s
/// binding never touches a real GPU/Impeller surface, so there is nothing
/// here to prime, only pointless virtual-clock churn to add to every map
/// widget test — and `MapController.of(context)` only resolves once this
/// widget is a real descendant of a mounted `FlutterMap`, which a bare
/// widget test around this file in isolation wouldn't have.
///
/// If a future flutter_map/Impeller release closes the gap, this primer
/// becomes a no-op cost (a few harmless sub-pixel `move()` calls), not a
/// correctness dependency, and can be deleted outright.
///
/// **Public, not `_`-prefixed, on purpose.** [mapTileLayerProvider] is the
/// only production call site, but the real `TileLayer` it wraps fires real
/// HTTP requests at OpenStreetMap the instant it's pumped (see this file's
/// top doc comment) — exactly what tests must not do. Making this class
/// visible lets `map_tile_layer_provider_test.dart` wrap an inert test
/// child instead, so the actual guard behaviour (does the ticker really
/// stay off under `flutter test`, even with a genuine `MapController` to
/// drive) is tested directly rather than asserted about code a test can't
/// reach — the trap the previous, misleading version of this test fell
/// into (see that test file's comment for the history).
class TileCompositingPrimer extends StatefulWidget {
  const TileCompositingPrimer({super.key, required this.child});

  final Widget child;

  @override
  State<TileCompositingPrimer> createState() => TileCompositingPrimerState();
}

@visibleForTesting
class TileCompositingPrimerState extends State<TileCompositingPrimer>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  MapController? _mapController;

  /// Whether the camera currently sits at `_lastBase` shifted by
  /// [_nudgeEpsilonDegrees] ("out") or back at `_lastBase` itself ("in").
  /// Starts `false`: the very first step nudges out.
  bool _nudgedOut = false;

  /// The centre the last "nudge out" step read from the live camera and is
  /// responsible for restoring — always the real camera position from just
  /// before that step, never a value cached at [initState] time.
  LatLng? _lastBase;

  /// How long to keep priming after the first frame this widget can reach a
  /// `MapController`. Generous relative to typical tile-fetch latency
  /// without pinning the raster thread awake indefinitely on a screen a
  /// user might sit on for a while — see this class's doc comment.
  static const _primerDuration = Duration(seconds: 4);

  /// One wobble step roughly every 5 frames at 60Hz — frequent enough to
  /// land inside most tiles' fetch-to-decode window, infrequent enough that
  /// this isn't spending every single frame on camera churn.
  static const _stepInterval = Duration(milliseconds: 80);
  Duration _lastStepAt = Duration.zero;

  /// Sub-pixel at any zoom this app uses (city zoom 11 through the closest
  /// listing zoom of 15, see [MapDefaults]) — roughly a centimetre of
  /// ground distance, which never resolves to a different screen pixel, so
  /// the wobble this class performs is never visible. Comfortably above
  /// `double` precision at these coordinate magnitudes, so
  /// `MapControllerImpl.moveRaw`'s "new camera equals old camera" check
  /// never treats a nudge as a no-op.
  static const _nudgeEpsilonDegrees = 0.000001;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `MapController.of` needs a `FlutterMap` ancestor, which only exists
    // once this widget is actually mounted inside one — `didChangeDependencies`
    // is the first point that's guaranteed true, unlike `initState`.
    _mapController ??= MapController.maybeOf(context);
    if (_ticker == null && !isRunningUnderFlutterTest) {
      final controller = _mapController;
      if (controller != null) {
        _ticker = createTicker(_onTick)..start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastStepAt < _stepInterval) return;
    _lastStepAt = elapsed;

    final controller = _mapController;
    if (elapsed >= _primerDuration || controller == null) {
      _stopAndSettle();
      return;
    }

    if (_nudgedOut) {
      // Second half of the wobble: restore the exact centre the first half
      // read, not wherever the map happens to be now — `move` below is the
      // one making the camera match `_lastBase` again.
      final base = _lastBase;
      if (base != null) controller.move(base, controller.camera.zoom);
      _nudgedOut = false;
    } else {
      // First half: capture the *current* real centre fresh (so this rides
      // alongside any legitimate camera move happening independently) and
      // nudge a sub-pixel amount away from it.
      final base = controller.camera.center;
      _lastBase = base;
      controller.move(
        LatLng(base.latitude + _nudgeEpsilonDegrees, base.longitude),
        controller.camera.zoom,
      );
      _nudgedOut = true;
    }
  }

  void _stopAndSettle() {
    // Never leave the camera mid-wobble: if the priming window ends while
    // nudged out, correct back before stopping so this primer has zero
    // lasting effect on where the map is centred.
    final controller = _mapController;
    final base = _lastBase;
    if (_nudgedOut && controller != null && base != null) {
      controller.move(base, controller.camera.zoom);
    }
    _nudgedOut = false;
    _ticker?.stop();
  }

  @override
  void dispose() {
    _stopAndSettle();
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
