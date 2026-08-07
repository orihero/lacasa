/// Display rules used only by `listing-detail` — the enum→label mapping
/// SCREENS.md §3.7 fixes for the Info tags, the defensive `optionList`
/// parse behind the Additional Information section, and the two derived
/// strings (coordinates, price per m²) that section headers show.
///
/// Rules shared with other screens live in
/// `shared/formatters/formatters.dart` instead — price, date, phone, the id
/// badge, and the `{rooms} · {area} · {floor}` stat line all belong to more
/// than one screen and are not duplicated here.
///
/// Every label function returns `String?`, never a placeholder like "—" or
/// "Unknown": the caller drops the tag entirely when a value is absent.
/// That is what makes `ad-1003` (no `repairment`, no `furniture`) render
/// two tags instead of four with two of them lying.
library;

import '../../../api/api.dart';
import '../../../shared/shared.dart';

/// One parsed row of `Ad.optionList` — SCREENS.md's "dynamic key/value chip
/// list". A record rather than a class: it has no behaviour, no identity,
/// and never leaves this feature.
typedef AdditionalInfoEntry = ({String key, String value});

abstract final class ListingDetailFormatters {
  /// SCREENS.md §3.7 Info tags: **Type** — "Residential"/"Nonresidential".
  /// `null` for [AdType.unknown], i.e. a type this build doesn't recognize
  /// — showing the raw wire string would leak an enum value into the UI,
  /// and inventing a label would be worse.
  static String? typeLabel(AdType type) => switch (type) {
    AdType.residential => 'Residential',
    AdType.nonresidential => 'Nonresidential',
    AdType.unknown => null,
  };

  /// **Category** — "Sale"/"Rent".
  static String? categoryLabel(AdCategory category) => switch (category) {
    AdCategory.sale => 'Sale',
    AdCategory.rent => 'Rent',
    AdCategory.unknown => null,
  };

  /// **Repair** — "Not repaired"/"Normal"/"Good"/"Excellent". `null` both
  /// when the key was absent from the wire (a genuinely unstated repair
  /// state, `Ad.repairment == null`) and for [Repairment.unknown]; the tag
  /// is dropped either way.
  static String? repairmentLabel(Repairment? repairment) =>
      switch (repairment) {
        Repairment.notRepaired => 'Not repaired',
        Repairment.normal => 'Normal',
        Repairment.good => 'Good',
        Repairment.excellent => 'Excellent',
        Repairment.unknown || null => null,
      };

  /// **Furniture** — "With furniture"/"Without Furniture". The
  /// inconsistent capitalization is SCREENS.md's own (§3.7 writes exactly
  /// "With furniture"/"Without Furniture") and is reproduced rather than
  /// silently tidied, since the spec is the binding copy source for all
  /// three implementations and they must agree character for character.
  static String? furnitureLabel(Furniture? furniture) => switch (furniture) {
    Furniture.withFurniture => 'With furniture',
    Furniture.withoutFurniture => 'Without Furniture',
    Furniture.unknown || null => null,
  };

  /// Parses `Ad.optionList` into the Additional Information rows.
  ///
  /// `optionList` is untyped passthrough on the wire (see [Ad.optionList]):
  /// the write side produces `{id?, key?, value?}[]` but the read side is
  /// never re-validated, so anything can arrive here — `null`, a bare
  /// string, a list of non-maps, maps missing either half of the pair. All
  /// of it degrades to "this ad has no additional information" rather than
  /// throwing, because a malformed `optionList` must not take down a screen
  /// whose other nine sections are fine. `listing_detail_fixtures.dart`
  /// ships `ad-1003` with a deliberately malformed value to keep this path
  /// exercised.
  ///
  /// Entries missing a key or a value are dropped individually — a partial
  /// list still shows whatever rows are well-formed.
  static List<AdditionalInfoEntry> additionalInfo(Object? optionList) {
    if (optionList is! List) return const [];

    final entries = <AdditionalInfoEntry>[];
    for (final raw in optionList) {
      if (raw is! Map) continue;
      final key = raw['key'];
      final value = raw['value'];
      if (key is! String || key.trim().isEmpty) continue;
      // Value is stringified rather than type-checked: a number or bool is
      // a perfectly sensible thing for an option to hold ("Balcony: 2"),
      // and the write side never promised a string.
      if (value == null) continue;
      final valueText = value.toString().trim();
      if (valueText.isEmpty) continue;
      entries.add((key: key.trim(), value: valueText));
    }
    return entries;
  }

  /// `41.2810, 69.2050` — the Location section's coordinate readout, 4
  /// decimal places (~11 m, more precision than a district-level pin
  /// deserves). Returns `null` unless the ad has both halves of a pin; see
  /// [Ad.hasPin] for why truthiness is the wrong test.
  static String? coordinates(Ad ad) {
    if (!ad.hasPin) return null;
    return '${ad.lat!.toStringAsFixed(4)}, ${ad.lng!.toStringAsFixed(4)}';
  }

  /// `$ 1,200 / m²` for the price footer's secondary figure, or `null`
  /// when the ad states no usable area. Reuses [Ad.pricePerSqm], which is
  /// a port of web's own `computePricePerSqm` — the figure this screen
  /// shows and the one web shows can't drift apart.
  static String? pricePerSqm(Ad ad) {
    final value = ad.pricePerSqm;
    if (value == null) return null;
    return '\$ ${Formatters.groupedNumber(value)} / m²';
  }
}
