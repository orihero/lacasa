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
import '../../../l10n/generated/app_localizations.dart';
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
  ///
  /// Takes [AppLocalizations] rather than a [BuildContext]: this is a pure
  /// function called from other pure code (`_rows` in
  /// `listing_sizes_section.dart`) as well as from widget `build` methods,
  /// and passing the already-resolved localizations object is the narrower
  /// dependency of the two — callers that do have a `BuildContext` just
  /// pass `AppLocalizations.of(context)`.
  static String? typeLabel(AppLocalizations l10n, AdType type) =>
      switch (type) {
        AdType.residential => l10n.listingTypeResidentialLabel,
        AdType.nonresidential => l10n.listingTypeNonresidentialLabel,
        AdType.unknown => null,
      };

  /// **Category** — "Sale"/"Rent".
  static String? categoryLabel(AppLocalizations l10n, AdCategory category) =>
      switch (category) {
        AdCategory.sale => l10n.listingCategorySaleLabel,
        AdCategory.rent => l10n.listingCategoryRentLabel,
        AdCategory.unknown => null,
      };

  /// **Repair** — "Not repaired"/"Normal"/"Good"/"Excellent". `null` both
  /// when the key was absent from the wire (a genuinely unstated repair
  /// state, `Ad.repairment == null`) and for [Repairment.unknown]; the tag
  /// is dropped either way.
  static String? repairmentLabel(
    AppLocalizations l10n,
    Repairment? repairment,
  ) => switch (repairment) {
    Repairment.notRepaired => l10n.listingRepairmentNotRepairedLabel,
    Repairment.normal => l10n.listingRepairmentNormalLabel,
    Repairment.good => l10n.listingRepairmentGoodLabel,
    Repairment.excellent => l10n.listingRepairmentExcellentLabel,
    Repairment.unknown || null => null,
  };

  /// **Furniture** — "With furniture"/"Without Furniture". The
  /// inconsistent capitalization is SCREENS.md's own (§3.7 writes exactly
  /// "With furniture"/"Without Furniture") and is reproduced rather than
  /// silently tidied, since the spec is the binding copy source for all
  /// three implementations and they must agree character for character.
  static String? furnitureLabel(AppLocalizations l10n, Furniture? furniture) =>
      switch (furniture) {
        Furniture.withFurniture => l10n.listingFurnitureWithLabel,
        Furniture.withoutFurniture => l10n.listingFurnitureWithoutLabel,
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

  /// `$ 1,200 / m²` for a USD ad, `1,200 so'm / m²` for a UZS one, or
  /// `null` when the ad states no usable area. Reuses [Ad.pricePerSqm],
  /// which is a port of web's own `computePricePerSqm` — the figure this
  /// screen shows and the one web shows can't drift apart.
  ///
  /// **Why this branches on [Ad.priceType] at all.** [Ad.pricePerSqm] is
  /// just `price / area` in whatever currency the ad's own price is
  /// already in — it was never a USD-only figure, so hardcoding the `$`
  /// prefix here mischaracterized every UZS ad's per-m² figure by the same
  /// ~13x this file's sibling fix ([Formatters.price]) already corrected
  /// for the headline price. That first pass fixed the headline and the
  /// card pill but missed this one because it lives behind its own call
  /// site ([ListingPriceFooter]) rather than sharing [Formatters.price]'s —
  /// confirmed on device on the Chilonzor commercial UZS listing, where the
  /// asking-price line read "3,650,000,000 so'm · $ 6,083,333 / m²" with
  /// the two halves of the same line disagreeing on currency. Mirrors
  /// [Formatters.price]'s branch and reuses the same
  /// `listingEditorPriceTypeUzsOption` ("so'm") suffix rather than
  /// inventing a second UZS convention for this one figure.
  ///
  /// Takes [AppLocalizations] rather than a [BuildContext], matching every
  /// other label function in this file — [ListingPriceFooter.build] always
  /// has a [BuildContext] on hand to resolve one from.
  static String? pricePerSqm(AppLocalizations l10n, Ad ad) {
    final value = ad.pricePerSqm;
    if (value == null) return null;
    final grouped = Formatters.groupedNumber(value);
    final body = ad.priceType == CurrencyCode.uzs
        ? '$grouped ${l10n.listingEditorPriceTypeUzsOption}'
        : '\$$grouped';
    return '$body / m²';
  }
}
