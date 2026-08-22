/// `.segs` + `.pane` — the segmented control that switches `listing-detail`
/// between its bodies, one at a time.
///
/// The mockup does not stack Description / Sizes / Nearby / Location as
/// headed sections; it renders a horizontally scrollable row of pills
/// (`.seg{height:42px;border-radius:21px;padding:0 22px}`, the active one
/// filled `var(--pill)`) with `.pane{display:none}` / `.pane.on{display:
/// block}` beneath, so exactly one body is on screen. SCREENS.md §7
/// enumerates the same bodies but says nothing about how they are laid out,
/// so the mockup wins on visual form.
///
/// The honest-gap rule [ListingDetailSection] enforces survives the change:
/// a pane whose data the ad doesn't carry is never handed to this widget,
/// so it gets no segment either — the buyer is not offered a tab that opens
/// onto blank space. With nothing at all to show, the whole control
/// disappears.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// One switchable body and the segment label that reveals it.
class ListingDetailPane {
  const ListingDetailPane({required this.label, required this.child});

  final String label;
  final Widget child;
}

/// Builds a pane only when [child] is non-null, mirroring
/// [ListingDetailSection]'s drop-if-empty contract so callers can compose
/// the list with the same `?`-spread they already use.
ListingDetailPane? paneOrNull(String label, Widget? child) =>
    child == null ? null : ListingDetailPane(label: label, child: child);

class ListingDetailPanes extends StatefulWidget {
  const ListingDetailPanes({super.key, required this.panes});

  final List<ListingDetailPane> panes;

  @override
  State<ListingDetailPanes> createState() => _ListingDetailPanesState();
}

class _ListingDetailPanesState extends State<ListingDetailPanes> {
  int _selected = 0;

  @override
  void didUpdateWidget(ListingDetailPanes oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A shorter pane list (a refreshed ad that lost a section) must not
    // leave the selection pointing past the end.
    if (_selected >= widget.panes.length) _selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final panes = widget.panes;
    if (panes.isEmpty) return const SizedBox.shrink();

    final index = _selected.clamp(0, panes.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.segs{margin-top:14px;gap:9px;overflow-x:auto;padding-bottom:3px}`.
        const SizedBox(height: 14),
        SizedBox(
          height: _segHeight + 3,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: panes.length,
            separatorBuilder: (context, _) => const SizedBox(width: 9),
            itemBuilder: (context, i) => _Segment(
              key: ValueKey('listingPaneSeg-$i'),
              label: panes[i].label,
              selected: i == index,
              onTap: () => setState(() => _selected = i),
            ),
          ),
        ),
        // `.pane{margin-top:14px;padding:0 4px}`.
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: panes[index].child,
        ),
      ],
    );
  }
}

const double _segHeight = 42;

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // `.seg{font-size:12.5px;font-weight:500;white-space:nowrap}`.
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: type.body.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1,
        color: selected ? colors.pillInk : colors.ink,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: selected
            ? Container(
                height: _segHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: AppShadows.selectedChip,
                ),
                child: text,
              )
            : GlassSurface(
                variant: GlassVariant.onSurface,
                borderRadius: BorderRadius.circular(21),
                height: _segHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: text,
              ),
      ),
    );
  }
}
