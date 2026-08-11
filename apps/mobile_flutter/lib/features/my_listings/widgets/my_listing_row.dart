/// One row of `my-listings` (SCREENS.md §25's exact row anatomy:
/// "thumbnail; #{id}; Created At; City; Status pill; Author; {rooms} room;
/// {area} m²; edit icon"). Built on the shared [CrmListTile]/[AdStagePill]
/// (build contract: "reuse ... rather than rebuilding them") — nine pieces
/// of information map onto that widget's four slots as follows:
///
/// - **leading** → the thumbnail ([ListingPhoto]).
/// - **title** → the id badge ([Formatters.adIdBadge]), the row's own
///   short identifier — SCREENS.md's anatomy names no separate listing
///   title for this dense, table-like row (unlike `apps/console`'s wider
///   "Listing" column, which shows thumb + title together).
/// - **subtitle** → Created At, City, Author, rooms, area, `·`-joined —
///   truncates with an ellipsis on a narrow phone rather than overflowing
///   (see this file's "layout holds at real phone widths" test group);
///   density over a second/third line was chosen over cramming any of
///   these into [trailing], which — unlike [subtitle] — has no bounded
///   width to ellipsize against and would risk a real `RenderFlex`
///   overflow instead of a graceful truncation.
/// - **trailing** → the status pill ([AdStagePill]) plus the edit icon,
///   the row's other two genuinely separate controls/facts.
///
/// **Tap regions**: SCREENS.md §25 says "Row tap (outside thumbnail/edit)
/// → `listing-detail`". [CrmListTile]'s own single `onTap` covers its
/// whole row including the leading slot — forking it to carve out the
/// thumbnail specifically was rejected (build contract rule 3/§0: reuse,
/// don't rebuild, the shared widgets) — so a tap on the thumbnail also
/// opens `listing-detail` here; only the edit icon's own nested
/// [GestureDetector] genuinely wins the gesture arena and opens
/// `edit-listing` instead. Flagged as a minor, deliberate deviation from
/// the mockup's literal tap-region split, not an oversight.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class MyListingRow extends StatelessWidget {
  const MyListingRow({
    super.key,
    required this.ad,
    required this.authorName,
    required this.onTap,
    required this.onEdit,
  });

  final Ad ad;

  /// Already resolved by the caller (`resolveAdAuthorName`) — an em dash
  /// when unknown, never blank. See that function's own doc comment.
  final String authorName;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      Formatters.date(ad.createdAt),
      ad.city,
      authorName,
      Formatters.rooms(ad.rooms),
      Formatters.area(ad.area),
    ].whereType<String>().join(' · ');

    return CrmListTile(
      key: ValueKey('myListingRow-${ad.id}'),
      leading: ListingPhoto(url: ad.photos.firstOrNull),
      title: Formatters.adIdBadge(ad.id),
      subtitle: subtitle,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdStagePill(stage: ad.stage),
          const SizedBox(width: AppSpacing.sm),
          _EditButton(adId: ad.id, onTap: onEdit),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.adId, required this.onTap});

  final String adId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).myListingsEditButtonSemanticsLabel,
      child: GestureDetector(
        key: ValueKey('myListingEdit-$adId'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.edit_outlined, size: 18, color: colors.ink2),
        ),
      ),
    );
  }
}
