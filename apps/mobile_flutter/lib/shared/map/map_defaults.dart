/// The map constants every map surface in the app shares, in one place so
/// `map-view` and `listing-detail`'s Location preview can't disagree about
/// where "no location" points or which tile server they're citing.
///
/// **Tashkent is the default centre, not Coventry.** SCREENS.md's own
/// preamble calls this out as one of two web bugs the mobile spec
/// deliberately fixes: `apps/web` still carries a leftover `51.50, -0.12`-
/// era default from a template. Any map here that has nothing to centre on
/// opens over the city the listings are actually in.
library;

import 'package:latlong2/latlong.dart';

abstract final class MapDefaults {
  /// SCREENS.md §3.6, quoted: `41.2995, 69.2401`.
  static const LatLng tashkent = LatLng(41.2995, 69.2401);

  /// Whole-city view — the right zoom for a result set spread across
  /// Tashkent, and the fallback when there are no pins to fit.
  static const double cityZoom = 11;

  /// A single listing's preview zoom: close enough to read the street
  /// layout, not so close the surroundings vanish.
  static const double listingZoom = 15;

  /// OpenStreetMap's standard tiles — the same source `apps/web`'s Leaflet
  /// map uses, and the reason no API key or billing account is needed on
  /// either surface.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// OSM's tile usage policy requires a genuine identifying User-Agent;
  /// `flutter_map` builds one from this. A generic or absent agent is what
  /// gets clients blocked.
  static const String tileUserAgent = 'uz.lacasa.mobile';

  /// Required attribution for OSM tiles — not decoration, a licence term.
  static const String osmAttribution = '© OpenStreetMap contributors';
}
