/// SCREENS.md §3.7's **Sizes** section — Area `{area} m²`, Rooms
/// `{rooms} room`, Floor `{storey}/{floors}` — rendered as the mockup's
/// `.rows` definition list: a label/value pair per row, hairline-separated,
/// last row unruled.
///
/// Rows for attributes the ad doesn't state are omitted rather than shown
/// as "—", and the section disappears entirely when none of the three
/// resolve. The strings come from `Formatters` (shared) rather than being
/// rebuilt here, so this section and the listing cards can't disagree about
/// what "65 m²" looks like.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../formatters/listing_detail_formatters.dart';
import 'listing_detail_section.dart';

class ListingSizesSection extends StatelessWidget {
  const ListingSizesSection({super.key, required this.ad});

  final Ad ad;

  /// Null when the ad states none of area/rooms/floor — hand straight to
  /// [ListingDetailSection.child] to drop the heading with it.
  ///
  /// Takes [AppLocalizations] as a parameter (rather than a [BuildContext])
  /// because it is called from `listing_detail_screen.dart`'s `build`,
  /// which already has one to pass — see `_rows`'s own doc comment for why
  /// this static helper layer threads the resolved object rather than the
  /// context itself.
  static Widget? buildOrNull(AppLocalizations l10n, Ad ad) {
    final rows = _rows(l10n, ad);
    if (rows.isEmpty) return null;
    return ListingSizesSection(ad: ad);
  }

  /// Takes [AppLocalizations] rather than [BuildContext]: this static
  /// helper is called both from [buildOrNull] (no widget tree, so no
  /// context to read) and from [build] below, and threading the already-
  /// resolved localizations object through both call sites is the smaller
  /// surface — [build] just passes `AppLocalizations.of(context)`.
  static List<({String label, String value})> _rows(
    AppLocalizations l10n,
    Ad ad,
  ) {
    final area = Formatters.area(ad.area);
    final rooms = Formatters.rooms(ad.rooms);
    final floor = Formatters.floor(ad.storey, ad.floors);
    final sizeRows = <({String label, String value})>[
      if (area != null) (label: l10n.listingSizesAreaLabel, value: area),
      if (rooms != null) (label: l10n.listingSizesRoomsLabel, value: rooms),
      // The mockup renders this one spaced — "4 / 9", not "4/9".
      if (floor != null)
        (label: l10n.listingSizesFloorLabel, value: floor.replaceAll('/', ' / ')),
    ];

    // Type is the mockup's own closing row of this pane and reads naturally
    // as the last line of a property table — but it is not a size, and
    // `type` almost always resolves (the wire only fails to produce a label
    // for a value this build predates). Appending it unconditionally would
    // therefore keep the Sizes heading alive on an ad that states no sizes
    // at all, over a single row saying "Type: Residential" — exactly the
    // empty-section-that-reads-as-a-loading-failure this screen's
    // honest-gap rule exists to prevent. So it rides along with real size
    // rows and is dropped with them. Nothing is lost either way: the same
    // value is already an Info tag above.
    if (sizeRows.isEmpty) return const [];

    final type = ListingDetailFormatters.typeLabel(l10n, ad.type);
    return [
      ...sizeRows,
      if (type != null) (label: l10n.listingSizesTypeLabel, value: type),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows(AppLocalizations.of(context), ad);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          _SizesRow(
            label: rows[i].label,
            value: rows[i].value,
            isLast: i == rows.length - 1,
          ),
      ],
    );
  }
}

/// `.row{padding:11px 2px;border-bottom:1px solid var(--line)}`.
class _SizesRow extends StatelessWidget {
  const _SizesRow({
    required this.label,
    required this.value,
    required this.isLast,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.line, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: type.bodySmall.copyWith(color: colors.muted)),
          const SizedBox(width: AppSpacing.base),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: LaCasaTypography.tabular(
                type.rowTitle,
              ).copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
