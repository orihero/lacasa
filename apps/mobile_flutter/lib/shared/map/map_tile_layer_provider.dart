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
///
/// Tests override this with a plain coloured box; nothing about the widget
/// under test changes, because a base layer is a base layer.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_defaults.dart';

final mapTileLayerProvider = Provider<Widget>((ref) {
  return TileLayer(
    urlTemplate: MapDefaults.osmTileUrl,
    userAgentPackageName: MapDefaults.tileUserAgent,
    // A tile that fails to load leaves its cell empty rather than throwing
    // — a patchy connection should dim the map, not take the screen down.
    errorTileCallback: (tile, error, stackTrace) {},
  );
});
