/// The two free-form chip lists on `listing-detail` — **Additional
/// Information** (`Ad.optionList`, key/value pairs) and **Nearby Places**
/// (`Ad.nearPlacesList`, plain strings). SCREENS.md §3.7 calls both
/// "dynamic … chip list"; they differ only in what a chip's label is built
/// from, which is why they share a file rather than each getting a widget
/// class of their own.
///
/// Both return `null` when the ad carries nothing for them, so the caller
/// hands the result to [ListingDetailSection.child] and the heading
/// disappears along with the content. `listing_detail_fixtures.dart` ships
/// one ad with an empty `nearPlacesList` and one with a deliberately
/// malformed `optionList` precisely to keep both of those paths honest.
///
/// Neither list uses the glass chip — both are unbounded in length. See
/// `listing_tag_chip.dart` for that call.
library;

import 'package:flutter/widgets.dart';

import '../../../api/api.dart';
import '../formatters/listing_detail_formatters.dart';
import 'listing_detail_section.dart';
import 'listing_tag_chip.dart';

/// `{key} · {value}` chips, or null when `optionList` parses to nothing —
/// which covers a null, a malformed, and an empty-but-well-formed wire
/// value identically. All three mean the same thing to a reader.
Widget? buildAdditionalInfoOrNull(Ad ad) {
  final entries = ListingDetailFormatters.additionalInfo(ad.optionList);
  return tagWrapOrNull([
    for (final entry in entries)
      ListingTagChip(label: '${entry.key} · ${entry.value}'),
  ]);
}

/// One chip per nearby place. Blank entries are skipped — the array is
/// free text an agent typed, and an empty string is not a place.
Widget? buildNearbyPlacesOrNull(Ad ad) {
  final places = ad.nearPlacesList
      .map((place) => place.trim())
      .where((place) => place.isNotEmpty);

  return tagWrapOrNull([
    for (final place in places) ListingTagChip(label: place),
  ]);
}
