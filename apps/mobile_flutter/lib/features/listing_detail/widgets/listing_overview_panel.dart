/// `listing-detail`'s **Overview** panel — the mockup's first block inside
/// `.det__b`: a `.panel` card whose header pairs the "Overview" heading
/// with the floor line, over a `.panel__row` of the vertical `.rail-v`
/// fact toggles and the `.gal` block (the selected fact line plus a 3-up
/// photo grid that opens `photo-gallery`).
///
/// **Nothing here is new information.** Every value it shows is already
/// reachable elsewhere on this screen — the hero pills carry the spec
/// line, the Sizes pane carries area/rooms/floor, the hero carousel
/// carries the photos. This block exists because the mockup opens the body
/// with it, and `listing_detail_panes.dart`'s doc comment already settles
/// the general question the same way ("the mockup wins on visual form").
/// It is a summary, so it is allowed to repeat: the header's floor line
/// and the Floor toggle's own fact line say the same thing in the mockup
/// too.
///
/// **Wording is reused, not invented.** The rail's fact lines are built
/// from [Formatters] and the Sizes section's existing row labels rather
/// than from new prose keys, so this panel and the Sizes pane cannot
/// disagree about what "65 m²" or "4/9" looks like. The mockup's own
/// phrasings ("Floor 4 of 9", "65 m² total area") are therefore rendered
/// as "Floor 4/9" and "Area 65 m²" — the same facts in the words this app
/// already translates. Only the panel heading is new copy
/// ([AppLocalizations.listingOverviewSectionTitle]).
///
/// **Honest-gap rule**, the same one `listing_detail_section.dart`
/// documents for the body sections:
/// - a rail entry whose fact the ad doesn't state is dropped;
/// - the rail disappears below two entries — a lone toggle that can only
///   select what is already selected is a dead control, the same reason
///   `listing_hero.dart` suppresses a "1/1" slide counter;
/// - the photo grid is dropped below two photos, where it would read as a
///   broken 3-up rather than a gallery;
/// - and the whole panel renders away when the ad states no facts *and*
///   has no grid to show.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../photo_gallery/data/gallery_item.dart';

/// One `.rail-v .rnd` toggle and the `.gal__l` line it selects.
typedef _OverviewFact = ({IconData icon, String label, String line});

/// One `.gal__g` thumbnail: the photo's URL and its index in the *gallery's*
/// item list, so a tap opens `photo-gallery` on that exact slide rather
/// than on the nth photo of a differently-filtered list.
typedef _OverviewThumb = ({int index, String url});

class ListingOverviewPanel extends StatefulWidget {
  const ListingOverviewPanel({
    super.key,
    required this.ad,
    required this.onOpenGallery,
  });

  final Ad ad;

  /// Called with the index of the tapped thumbnail — the same callback the
  /// hero uses, so both routes into `photo-gallery` land on the same slide
  /// numbering.
  final void Function(int index) onOpenGallery;

  @override
  State<ListingOverviewPanel> createState() => _ListingOverviewPanelState();
}

class _ListingOverviewPanelState extends State<ListingOverviewPanel> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final facts = _facts(l10n, widget.ad);
    final thumbs = _thumbs(widget.ad);
    if (facts.isEmpty && thumbs.isEmpty) return const SizedBox.shrink();

    // A refreshed ad that lost a fact must not leave the selection pointing
    // past the end — the same guard `listing_detail_panes.dart` applies to
    // its segment index.
    final selected = facts.isEmpty ? 0 : _selected.clamp(0, facts.length - 1);
    final floor = Formatters.floor(widget.ad.storey, widget.ad.floors);

    return Container(
      // `.panel{background:var(--card);border-radius:22px;padding:16px 14px;
      // box-shadow:0 12px 26px -22px rgba(30,24,44,.6)}` — the 14px
      // horizontal padding is a literal for the same reason `.det__b`'s
      // gutter is: this screen runs narrower than the 20px body default.
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.panel__h{display:flex;align-items:baseline;
          // justify-content:space-between}`.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                // `.panel__h h3` — 15.5/700.
                child: Text(
                  l10n.listingOverviewSectionTitle,
                  style: type.panelHeading.copyWith(color: colors.ink),
                ),
              ),
              if (floor != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${l10n.listingSizesFloorLabel} $floor',
                  // `.link{font-size:11.5px;font-weight:500;
                  // color:var(--muted)}` — no size role is exactly
                  // 11.5/500, so `specMeta` (10.5/500) plus the size, the
                  // same substitution `section_header.dart` makes.
                  style: LaCasaTypography.tabular(
                    type.specMeta,
                  ).copyWith(fontSize: 11.5, color: colors.muted),
                ),
              ],
            ],
          ),
          // `.panel__row{margin-top:14px;display:flex;gap:11px}`.
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (facts.length > 1) ...[
                  _FactRail(
                    facts: facts,
                    selected: selected,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                  const SizedBox(width: 11),
                ],
                Expanded(
                  child: _GalleryBlock(
                    line: facts.isEmpty ? null : facts[selected].line,
                    thumbs: thumbs,
                    onOpenGallery: widget.onOpenGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The rail's entries, in the mockup's order (rooms, floor, area), each
  /// dropped when the ad doesn't state it.
  static List<_OverviewFact> _facts(AppLocalizations l10n, Ad ad) {
    // "3 rooms · 65 m²" — the mockup's own Rooms fact, which is the card
    // stat line minus the floor (the floor has its own toggle).
    final specLine = Formatters.statLine(ad, includeFloor: false, l10n: l10n);
    final floor = Formatters.floor(ad.storey, ad.floors);
    final area = Formatters.area(ad.area);

    return [
      if (ad.rooms != null && specLine.isNotEmpty)
        (
          icon: Icons.bed_rounded,
          label: l10n.listingSizesRoomsLabel,
          line: specLine,
        ),
      if (floor != null)
        (
          icon: Icons.elevator_rounded,
          label: l10n.listingSizesFloorLabel,
          line: '${l10n.listingSizesFloorLabel} $floor',
        ),
      if (area != null)
        (
          icon: Icons.straighten_rounded,
          label: l10n.listingSizesAreaLabel,
          line: '${l10n.listingSizesAreaLabel} $area',
        ),
    ];
  }

  /// The first three *photos* of the gallery, each keeping its index in the
  /// full item list. Videos are skipped — `.gal__g` is a row of `<img>`,
  /// and a video slide has no poster frame on the wire to put there (see
  /// `listing_hero.dart`). Below two photos the grid is dropped entirely.
  static List<_OverviewThumb> _thumbs(Ad ad) {
    final items = resolveGalleryItems(ad);
    final thumbs = <_OverviewThumb>[];
    for (var i = 0; i < items.length && thumbs.length < 3; i++) {
      if (items[i].isPhoto) thumbs.add((index: i, url: items[i].url));
    }
    return thumbs.length < 2 ? const [] : thumbs;
  }
}

/// `.rail-v{display:flex;flex-direction:column;justify-content:space-between}`
/// — the toggles spread over the `.gal` block's height rather than stacking
/// with a fixed gap.
class _FactRail extends StatelessWidget {
  const _FactRail({
    required this.facts,
    required this.selected,
    required this.onSelect,
  });

  final List<_OverviewFact> facts;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < facts.length; i++)
          _FactButton(
            fact: facts[i],
            isOn: i == selected,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

/// `.rail-v .rnd{width:38px;height:38px;font-size:18px;color:var(--ink);
/// background:var(--gl-bg);backdrop-filter:blur(12px) saturate(180%)}` and
/// `.rail-v .rnd.on{background:var(--pill);color:var(--pill-ink);
/// box-shadow:0 6px 14px -6px rgba(21,21,27,.6)}` — glass off, ink pill on,
/// the same two states `.opt`/`.chip` use (see `choice_chip_group.dart`).
class _FactButton extends StatelessWidget {
  const _FactButton({
    required this.fact,
    required this.isOn,
    required this.onTap,
  });

  final _OverviewFact fact;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final icon = Icon(
      fact.icon,
      size: 18,
      color: isOn ? colors.pillInk : colors.ink,
    );

    return Semantics(
      button: true,
      selected: isOn,
      label: fact.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: isOn
            ? Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: AppRadii.pill,
                  boxShadow: AppShadows.selectedChip,
                ),
                child: icon,
              )
            : GlassSurface(
                variant: GlassVariant.onSurface,
                borderRadius: AppRadii.pill,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: icon,
              ),
      ),
    );
  }
}

/// `.gal{background:var(--sunk);border-radius:16px;padding:11px 11px 12px}`
/// — the selected fact line over the 3-up photo grid.
class _GalleryBlock extends StatelessWidget {
  const _GalleryBlock({
    required this.line,
    required this.thumbs,
    required this.onOpenGallery,
  });

  /// Null only when the ad states no facts at all, in which case this block
  /// is the grid alone.
  final String? line;
  final List<_OverviewThumb> thumbs;
  final void Function(int index) onOpenGallery;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final factLine = line;

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (factLine != null)
            Text(
              factLine,
              overflow: TextOverflow.ellipsis,
              // `.gal__l{font-size:11.5px;font-weight:600;
              // color:var(--ink-2)}` — the 600 weight belongs to `rowTitle`
              // (12.75/600); only the size is overridden.
              style: LaCasaTypography.tabular(
                type.rowTitle,
              ).copyWith(fontSize: 11.5, color: colors.ink2),
            ),
          if (thumbs.isNotEmpty) ...[
            // `.gal__g{margin-top:9px;display:grid;
            // grid-template-columns:repeat(3,1fr);gap:6px}`.
            if (factLine != null) const SizedBox(height: 9),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    // A grid of three equal columns keeps its shape when
                    // the ad has only two photos — the third track is
                    // empty rather than the other two stretching.
                    child: i < thumbs.length
                        ? _Thumb(
                            thumb: thumbs[i],
                            onTap: () => onOpenGallery(thumbs[i].index),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `.gal__g img{width:100%;height:108px;object-fit:cover;border-radius:10px}`
/// — 10px sits inside [AppRadii.sm]'s documented 10–12px grid-thumbnail
/// range, so the token stands in for it.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.thumb, required this.onTap});

  final _OverviewThumb thumb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: SizedBox(
          height: 108,
          width: double.infinity,
          child: ListingPhoto(url: thumb.url),
        ),
      ),
    );
  }
}
