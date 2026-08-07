// Unit tests for the pin/camera derivation (lib/features/map_view/data/).
// No widgets here — this is the pure decision layer about which ads can be
// drawn and where the camera opens, and it is worth testing without a map.

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:lacasa_mobile/features/map_view/data/map_pin.dart';
import 'package:lacasa_mobile/shared/map/map_defaults.dart';

import '../support/map_test_ads.dart';

void main() {
  group('pinnableAds', () {
    test('keeps ads with coordinates, in input order', () {
      final pins = pinnableAds([
        mapAd(id: 'a', lat: 41.31, lng: 69.24),
        mapAd(id: 'b', lat: 41.28, lng: 69.20),
      ]);

      expect(pins.map((p) => p.ad.id), ['a', 'b']);
      expect(pins.first.point, const LatLng(41.31, 69.24));
    });

    test('drops ads with no coordinates rather than guessing one', () {
      final pins = pinnableAds([
        mapAd(id: 'has-pin', lat: 41.31, lng: 69.24),
        mapAd(id: 'no-pin'),
      ]);

      expect(pins.map((p) => p.ad.id), ['has-pin']);
    });

    test('drops an ad carrying only one half of a coordinate pair', () {
      // `lat` without `lng` is not a location; plotting it at lng 0 would
      // put a Tashkent flat in the Gulf of Guinea.
      final pins = pinnableAds([
        mapAd(id: 'lat-only', lat: 41.31),
        mapAd(id: 'lng-only', lng: 69.24),
      ]);

      expect(pins, isEmpty);
    });

    test('an empty input yields no pins rather than throwing', () {
      expect(pinnableAds(const []), isEmpty);
    });
  });

  group('camera', () {
    test('no pins opens over Tashkent at city zoom', () {
      final pins = pinnableAds(const []);

      // SCREENS.md's own fix for web's leftover Coventry default.
      expect(initialCenterFor(pins), MapDefaults.tashkent);
      expect(initialZoomFor(pins), MapDefaults.cityZoom);
      expect(cameraFitFor(pins), isNull);
    });

    test('one pin centres on it at listing zoom, with no bounds fit', () {
      final pins = pinnableAds([mapAd(id: 'a', lat: 41.31, lng: 69.24)]);

      // A bounds fit around a single point degenerates to max zoom.
      expect(cameraFitFor(pins), isNull);
      expect(initialCenterFor(pins), const LatLng(41.31, 69.24));
      expect(initialZoomFor(pins), MapDefaults.listingZoom);
    });

    test('several pins produce a bounds fit covering all of them', () {
      final pins = pinnableAds([
        mapAd(id: 'a', lat: 41.31, lng: 69.24),
        mapAd(id: 'b', lat: 41.25, lng: 69.30),
        mapAd(id: 'c', lat: 41.35, lng: 69.18),
      ]);

      final fit = cameraFitFor(pins);
      expect(fit, isNotNull);

      final bounds = LatLngBounds.fromPoints([
        for (final pin in pins) pin.point,
      ]);
      expect(bounds.north, 41.35);
      expect(bounds.south, 41.25);
      expect(bounds.east, 69.30);
      expect(bounds.west, 69.18);
    });
  });
}
