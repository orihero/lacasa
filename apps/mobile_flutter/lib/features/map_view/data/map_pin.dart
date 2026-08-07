/// Turning a result set into map pins — the one place that decides which
/// ads a map can actually show and where the camera should open.
///
/// **Ads without coordinates are dropped, silently to the map but not to
/// the user.** `Ad.lat`/`lng` are nullable and a real listing may carry
/// neither (fixture `ad-1008` is exactly that case). A pin at a guessed or
/// zeroed location would put a property in the Gulf of Guinea; dropping it
/// is the only honest option. `map_view_screen.dart` is responsible for
/// telling the user how many were dropped — see its "n of m" count line.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../api/api.dart';
import '../../../shared/map/map_defaults.dart';

/// One mappable listing: the ad plus the point it sits at, so downstream
/// widgets never re-do the null checks [pinnableAds] already did.
class MapPin {
  const MapPin({required this.ad, required this.point});

  final Ad ad;
  final LatLng point;
}

/// The subset of [ads] that can be drawn, in input order.
List<MapPin> pinnableAds(List<Ad> ads) {
  return [
    for (final ad in ads)
      if (ad.hasPin) MapPin(ad: ad, point: LatLng(ad.lat!, ad.lng!)),
  ];
}

/// How the camera should open for [pins].
///
/// - No pins: centred on Tashkent at city zoom ([MapDefaults]) — the spec's
///   literal instruction, and the reason the screen is never blank-and-
///   nowhere even with an empty result set.
/// - One pin: centred on it at listing zoom, since a bounds fit around a
///   single point degenerates to maximum zoom.
/// - Several: fitted to their bounds with padding, so every result is on
///   screen without the user panning to discover there were more.
CameraFit? cameraFitFor(List<MapPin> pins) {
  if (pins.length < 2) return null;
  return CameraFit.bounds(
    bounds: LatLngBounds.fromPoints([for (final pin in pins) pin.point]),
    padding: const EdgeInsets.all(56),
  );
}

/// The centre to use when [cameraFitFor] returns null.
LatLng initialCenterFor(List<MapPin> pins) {
  if (pins.isEmpty) return MapDefaults.tashkent;
  return pins.first.point;
}

/// The zoom to use when [cameraFitFor] returns null.
double initialZoomFor(List<MapPin> pins) {
  if (pins.isEmpty) return MapDefaults.cityZoom;
  return MapDefaults.listingZoom;
}
