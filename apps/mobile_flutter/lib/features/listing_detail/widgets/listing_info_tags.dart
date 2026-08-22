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
import '../../../l10n/generated/app_localizations.dart';
import '../formatters/listing_detail_formatters.dart';
import 'listing_detail_section.dart';
import 'listing_tag_chip.dart';

class ListingInfoTags extends StatelessWidget {
  const ListingInfoTags({super.key, required this.ad});

  final Ad ad;

  /// The tag wrap, or null when the ad states none of the four attributes —
  /// the same drop-if-empty contract [tagWrapOrNull] gives every other chip
  /// list here. The Description pane calls this directly so it can decide
  /// whether it has any body at all (the mockup nests `.tags` inside
  /// `<div class="pane" data-pane-body="description">`, after the paragraph).
  static Widget? buildOrNull(BuildContext context, Ad ad) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[
      ?ListingDetailFormatters.typeLabel(l10n, ad.type),
      ?ListingDetailFormatters.categoryLabel(l10n, ad.category),
      ?ListingDetailFormatters.repairmentLabel(l10n, ad.repairment),
      ?ListingDetailFormatters.furnitureLabel(l10n, ad.furniture),
    ];

    return tagWrapOrNull([
      // Bounded at four — the one chip list on this screen that keeps the
      // mockup's glass material. See `listing_tag_chip.dart`.
      for (final label in labels) ListingTagChip(label: label, glass: true),
    ]);
  }

  @override
  Widget build(BuildContext context) =>
      buildOrNull(context, ad) ?? const SizedBox.shrink();
}
