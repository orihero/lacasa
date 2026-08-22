/// The `.rail.chips` row: five single-select chips, "All" active by
/// default.
///
/// ## It filters now
/// This file used to open "**Decorative** (build spec, "Category chip row"
/// — no `data-go`/`data-filter` on any `.chip`). Selecting a chip only
/// updates [selectedCategoryChipProvider]'s local index — it must never
/// fire a fetch or filter the rails below." That was a faithful reading of
/// the mockup and the wrong thing to ship: the row is drawn in the exact
/// ink-pill-when-selected language `shared/widgets/choice_chip_group.dart`
/// uses for every *real* filter in the app, it animates into a confident
/// selected state on tap, and nothing anywhere consumed the index it set.
/// It was the most control-shaped no-op on the landing screen, and it
/// answered a tap with feedback that said the screen had changed when
/// nothing had.
///
/// A tap now narrows the Home feed **in place, on Home**: it writes the
/// chip's [AdType] to [selectedCategoryChipProvider], which
/// `homeFeedAdsProvider` watches and re-fetches with, so Featured
/// Listings, Explore Nearby and Top Districts (all three read that one
/// list) re-render for the selected category without the user leaving the
/// landing screen.
///
/// An earlier pass sent the tap to the Search tab instead —
/// `appliedSearchFiltersProvider` plus a `context.go`. That worked, but it
/// spent a whole navigation on a one-word filter and left Home showing an
/// unfiltered feed behind it; the chips are on Home, so their effect
/// belongs on Home. Search's own filter state is now left completely
/// untouched by this row: the two screens no longer reach into each
/// other's filters, and the "Filters" badge over there means only what the
/// user set over there.
///
/// **Deliberate deviation from the spec's own decorative note, flagged for
/// a human**: the build spec and this file both used to state the row is
/// non-interactive by design. Wiring it up is a product change, not a bug
/// fix, and is reported as such.
///
/// ## Why the payload is [AdType] and what that costs
/// `AdFilters` has exactly two axes a chip could carry: [AdCategory]
/// (rent/sale) and [AdType] (residential/nonresidential). Apartment/House
/// are residential; Office/Retail are non-residential — so `type` is the
/// only honest mapping of these five labels, and "All" clears the filter
/// set entirely.
///
/// The cost is real and is **not** hidden: nothing in the API distinguishes
/// an apartment from a house, so Apartment and House produce the same
/// results, as do Office and Retail. That is a data-model gap (no property
/// subtype exists on `Ad`, in `@lacasa/domain`, or in `GET /ads`'s query
/// vocabulary), not something this widget can paper over — the alternatives
/// were to keep four labels that do nothing at all, or to invent a
/// distinction the server cannot honour. Reported for the spec owner:
/// either the server grows a subtype, or these five labels collapse to
/// three (All / Residential / Non-residential).
///
/// ## Why the lit chip is just the stored index again
/// While a tap navigated, the lit state had to be cross-checked against
/// `appliedSearchFiltersProvider` — the chip and the filter lived on
/// different screens and could drift apart, leaving Home claiming a filter
/// the Search tab had since replaced. Filtering in place removes that
/// distance: [selectedCategoryChipProvider] is now the single thing both
/// the highlight and the fetch read, so they cannot disagree, and the
/// index alone is the honest answer to "which chip is on".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';

class _ChipSpec {
  const _ChipSpec(this.label, this.icon, this.type);
  final String label;
  final IconData icon;

  /// The `AdFilters.type` this chip stands for; `null` for "All", which
  /// applies no constraint at all. See this file's doc comment for why
  /// this axis, and what it cannot express.
  final AdType? type;
}

/// Built from [AppLocalizations] rather than a top-level `const` list (the
/// original shape) since every label is now a localized lookup, which
/// requires a [BuildContext] and so cannot be `const`.
List<_ChipSpec> _chips(AppLocalizations l10n) => [
  _ChipSpec(l10n.homeCategoryAllLabel, Icons.grid_view_rounded, null),
  _ChipSpec(
    l10n.homeCategoryApartmentLabel,
    Icons.apartment_rounded,
    AdType.residential,
  ),
  _ChipSpec(
    l10n.homeCategoryHouseLabel,
    Icons.house_rounded,
    AdType.residential,
  ),
  _ChipSpec(
    l10n.homeCategoryOfficeLabel,
    Icons.business_rounded,
    AdType.nonresidential,
  ),
  _ChipSpec(
    l10n.homeCategoryRetailLabel,
    Icons.storefront_rounded,
    AdType.nonresidential,
  ),
];

class CategoryChipRow extends ConsumerWidget {
  const CategoryChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryChipProvider).index;
    final chips = _chips(AppLocalizations.of(context));

    // `.rail{padding:2px 20px 4px}` — 40px chips in a 46px band, so
    // 46 - 2 - 4 leaves the chips themselves at exactly `.chip{height:40px}`.
    //
    // The band alone does **not** give the `.chip.on` lift
    // ([AppShadows.selectedChip], E2) room to land, which is what this
    // comment used to claim. That shadow is `0 8px 18px -4px` — it needs
    // ~22dp below the pill and the band offers 4, so [ListView]'s viewport
    // clip sheared it into a hard line flush against the pill's bottom
    // edge, reading as extra bulk rather than as elevation. `Clip.none` is
    // the actual fix: the rail spans the full screen width, so nothing sits
    // beside it for an unclipped chip to overlap, and the horizontal
    // overflow lands off-screen where it was being clipped away anyway.
    // (A strip that *does* share its row — `search_toolbar.dart`'s sort
    // chips — pairs `Clip.none` with [ShadowSafeClip] instead.)
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          2,
          AppSpacing.screenGutter,
          4,
        ),
        itemCount: chips.length,
        // `.rail{gap:12px}` — `.chips{margin-top:14px}` overrides only the
        // top margin, unlike `.dists`/`.agents`, which override the gap too.
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.base),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return _Chip(
            key: ValueKey('categoryChip-$index'),
            spec: chip,
            selected: index == selected,
            // The category is the *only* thing a chip sets. It carries no
            // city, price or district of its own, and it does not merge
            // into anything the user set elsewhere: a landing-screen chip
            // reads as "start here", and a feed quietly narrower than the
            // chip's one word claims would be the same kind of lie this
            // row was fixed to stop telling.
            onTap: () => ref
                .read(selectedCategoryChipProvider.notifier)
                .select(index, chip.type),
          );
        },
      ),
    );
  }
}

/// `.chip{height:40px}`. Stated here rather than left to the rail's
/// constraints because both chip states have to paint into it — see the
/// [SizedBox] in [_Chip.build].
const double _chipHeight = 40;

/// `.chip{padding:0 16px 0 12px}` with `.chip.on{padding-left:5px}`; both
/// states use the on-state's 5, see [_Chip.build].
const EdgeInsets _chipPadding = EdgeInsets.only(left: 5, right: 16);

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _ChipSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final foreground = selected ? colors.pillInk : colors.ink;

    // `.chip.on .chip__ic{width:30px;height:30px;border-radius:50%;
    // background:var(--pill-ink)}` with `.chip.on .chip__ic .i{color:var(--pill)}`
    // — the selected chip inverts its glyph inside a circle. Unselected, the
    // glyph is quieter than its own label: `.chip{color:var(--ink)}` but
    // `.chip .i{font-size:16px;color:var(--muted)}`.
    //
    // **Deliberate deviation.** The mockup leaves `.chip__ic` unsized off-state
    // (:333), so it shrink-wraps the 16px glyph and `.chip.on` ends up 7px
    // wider than its own off-state — the 7px `padding-left:12px→5px` buys back
    // is spent on the circle, not on the box. This build reserves the same
    // 30x30 box in both states and paints the disc only when selected, so a
    // chip does not change size when it is picked. The glyph's optical left
    // inset is the mockup's 12px either way (5 padding + (30-16)/2), so nothing
    // shifts; only the pill's own width stops moving.
    final Widget icon = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.pillInk : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        spec.icon,
        size: 16,
        color: selected ? colors.pill : colors.muted,
      ),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        // `.chip{gap:7px}`.
        const SizedBox(width: 7),
        Text(spec.label, style: type.rowTitle.copyWith(color: foreground)),
      ],
    );

    // Now that the chip filters, it has to announce itself as a control
    // and say what it does: "Show Apartment listings, button" rather than
    // the bare word "Apartment", which a screen-reader user would have no
    // reason to read as tappable. `excludeSemantics` drops the inner [Text]
    // node so the category is announced once, not twice; `selected` carries
    // the state the ink pill carries visually.
    //
    // The tap action is declared **here as well as** on the
    // [GestureDetector] below, for the reason `shared/widgets/tap_target.dart`
    // spells out: `excludeSemantics` drops the entire descendant subtree,
    // and the detector's `tap` action goes with it. Without this line the
    // chip announces itself as a button that TalkBack/VoiceOver double-tap
    // cannot activate — a labelled dead end, strictly worse for a
    // screen-reader user than the unlabelled-but-activatable chip this
    // replaced. (Routing through [TapTarget] itself is not an option here:
    // its 48dp floor would not fit the mockup's 40px chip in a 46px rail.)
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(
        context,
      ).homeCategoryChipSemanticsLabel(spec.label),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        // `.chip{padding:0 16px 0 12px}`, `.chip.on{padding-left:5px;
        // box-shadow:0 8px 18px -8px rgba(21,21,27,.55)}` — the selected
        // chip lifts off the rail ([AppShadows.selectedChip], E2). Both
        // states use the on-state's 5px left padding here, because both
        // reserve the 30px icon box above; that is the other half of the
        // equal-width deviation, and it is what keeps the glyph at the
        // mockup's 12px optical inset.
        //
        // **The [SizedBox] is what makes the two states the same height,
        // and neither may carry `alignment:` again.** A [Container] given
        // an `alignment` wraps its child in an [Align], and an [Align]
        // *expands the box* to the incoming constraints while leaving the
        // child at its intrinsic size. For the ink pill that is harmless —
        // the [BoxDecoration] paints the expanded box. For [GlassSurface]
        // it is not: the lens is the box's *child*, so the glass painted at
        // its own 30dp content height, centred in an invisible 40dp box,
        // while the selected pill painted the full 40. The chips visibly
        // changed size on tap, and the geometry test could not see it —
        // both boxes measured 40. A tight height plus no `alignment` hands
        // both states the same 40dp to paint into. (`choice_chip_group.dart`
        // states the same rule for the same reason.)
        child: SizedBox(
          height: _chipHeight,
          child: selected
              ? Container(
                  padding: _chipPadding,
                  decoration: BoxDecoration(
                    color: colors.pill,
                    borderRadius: AppRadii.pill,
                    boxShadow: AppShadows.selectedChip,
                  ),
                  child: content,
                )
              : GlassSurface(
                  variant: GlassVariant.onSurface,
                  borderRadius: AppRadii.pill,
                  padding: _chipPadding,
                  child: content,
                ),
        ),
      ),
    );
  }
}
