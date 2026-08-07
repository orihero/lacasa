/// SCREENS.md §3.7's Info tags row: **Type**, **Category**, **Repair**,
/// **Furniture**, in that order.
///
/// Each tag is dropped when the ad doesn't state that attribute (see
/// [ListingDetailFormatters], where every label function answers `null`
/// rather than a placeholder), so an ad with no repair state and no
/// furniture state shows two tags — not four, two of them guessing. The
/// whole row disappears when nothing at all resolves, which the wire makes
/// possible: `type` and `category` both fall back to their `unknown` member
/// for a value this build doesn't recognize.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../formatters/listing_detail_formatters.dart';
import 'listing_detail_section.dart';
import 'listing_tag_chip.dart';

class ListingInfoTags extends StatelessWidget {
  const ListingInfoTags({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      ?ListingDetailFormatters.typeLabel(ad.type),
      ?ListingDetailFormatters.categoryLabel(ad.category),
      ?ListingDetailFormatters.repairmentLabel(ad.repairment),
      ?ListingDetailFormatters.furnitureLabel(ad.furniture),
    ];

    return tagWrapOrNull([
      // Bounded at four — the one chip list on this screen that keeps the
      // mockup's glass material. See `listing_tag_chip.dart`.
      for (final label in labels) ListingTagChip(label: label, glass: true),
    ]) ??
        const SizedBox.shrink();
  }
}
