/// The `.ppill g` price pill overlaid on a listing photo — glass-over-photo
/// (`GlassVariant.onPhoto`), `${price}` for a USD sale or
/// `${price}{sharedPricePerMonthSuffix}` for a USD rent, the suffix rendered
/// smaller/lighter (mirrors the source mockup's
/// `.ppill span{opacity:.8; font-size:9.5px}`). Any card or tile that shows
/// a price over a photo — Home's rails, `listing-search` results,
/// `map-view`'s pin preview — should use this rather than hand-rolling the
/// same glass+text combination.
///
/// ## The ink here is fixed white, not [LaCasaColors.ink]
/// `GlassVariant.onPhoto` is the one glass variant with **no themed
/// counterpart** — `GlassTheme._onPhoto` is a single constant shared by both
/// brightnesses (`theme/glass_theme_extension.dart`), because what sits
/// under it is a photograph, not app chrome, and a photograph does not get
/// lighter when the app theme does. Every sibling overlay on that variant
/// therefore paints a hardcoded [Colors.white]: the Sale/Rent badge on this
/// same photo ([FullListingCard], [RowListingCard]), `listing-detail`'s hero
/// counter and district line, [FavouriteButton]'s heart, and `map-view`'s
/// chrome.
///
/// This pill used to be the sole exception, painting `colors.ink`. In dark
/// mode that resolves to a near-white and looked correct, which is why it
/// survived review; in **light** mode it resolves to `#15151B`, and the
/// variant is a 15%-*white* veil (`rgba(255,255,255,.15)`) over a photo that
/// both card callers deliberately darken underneath — `.42` black at the
/// pill's edge on [FullListingCard], `.35` on [CompactListingCard]. Black
/// text on a darkened photo under a whitening veil falls toward ~1.2:1, and
/// it sat 10dp from a *white* Sale badge on the identical glass, so the two
/// overlays on one photo disagreed about which colour that glass takes.
///
/// The [Shadow] is the other half: the scrim guarantees a dark ground at the
/// pill's own corner, but [PricePill] is a shared widget and a future caller
/// may drop it on an undarkened bright photo. A 1dp-offset, 4dp-blur black
/// shadow at 40% costs nothing on a dark ground and keeps the glyphs
/// separated from a white one — the same insurance the mockup's own
/// `text-shadow` on over-photo labels provides.
///
/// **UZS ads don't get the `$` prefix.** SCREENS.md's `$ {price}` rule was
/// written to unify the web app's three inconsistent price formats, not to
/// claim every ad is USD; the live API returns `priceType: "uzs"` for a
/// real fraction of seeded ads, and a `$` prefix there misstates the price
/// by roughly 13x. This mirrors [Formatters.price]'s branch on
/// [Ad.priceType] and the same "so'm" suffix the listing-editor's own live
/// price preview already uses (`listingEditorPriceTypeUzsOption` —
/// `_PricePreview` in
/// `features/listing_editor/widgets/form/details_step.dart`) rather than
/// inventing a second UZS convention. This widget always has a
/// [BuildContext], so unlike [Formatters.price] it doesn't need an optional
/// [AppLocalizations] parameter to reach that string.
///
/// Promoted out of `features/home/widgets/price_pill.dart`; the only
/// change at that point was its price-string dependency, which started
/// reading [Formatters.groupedPrice] (`shared/formatters/formatters.dart`)
/// instead of the since-retired `HomeFormatters.groupedPrice` — same
/// algorithm, consolidated to one owner.
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../formatters/formatters.dart';

class PricePill extends StatelessWidget {
  const PricePill({super.key, required this.ad, this.compact = false});

  final Ad ad;

  /// `false` (default) renders the base `.ppill` — 26px tall, `0 10px`
  /// padding, 11px/600. `true` renders the grid-card override
  /// (`.vcard__ph .ppill{height:24px;font-size:10.5px;padding:0 9px}`),
  /// which [CompactListingCard] passes because its 2-up cell is too narrow
  /// for the base size. A flag rather than two widgets: the two differ only
  /// in those three numbers, exactly as the source CSS expresses it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isRent = ad.category == AdCategory.rent;
    // `.ppill{font-size:11px;font-weight:600}` — `specMeta` is the only
    // role at this size band with no letter-spacing of its own (which the
    // source rule also has none of); the weight is the one override.
    //
    // The colour is deliberately **not** read from `LaCasaColors` — see this
    // file's doc comment for why over-photo glass takes a fixed white in
    // both themes.
    final priceStyle = LaCasaTypography.tabular(type.specMeta).copyWith(
      fontSize: compact ? 10.5 : 11,
      fontWeight: FontWeight.w600,
      color: AppOnPhoto.ink,
      shadows: const [AppOnPhoto.inkShadow],
    );
    final body = ad.priceType == CurrencyCode.uzs
        ? '${Formatters.groupedPrice(ad)} ${l10n.listingEditorPriceTypeUzsOption}'
        : '\$${Formatters.groupedPrice(ad)}';

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text.rich(
        TextSpan(
          text: body,
          style: priceStyle,
          children: [
            if (isRent)
              TextSpan(
                // Localized, not the literal "/month" this used to hard-code
                // — the very next line up already resolves "so'm" through
                // [AppLocalizations], so a Russian rental read
                // "800 000 so'm/month" and mixed three scripts in one string.
                // This widget always has a [BuildContext], so unlike
                // [Formatters.price] it needs no fallback.
                text: l10n.sharedPricePerMonthSuffix,
                // `.ppill span{font-weight:400;opacity:.8;font-size:9.5px}`
                // — a fixed size, not a ratio of the base: the compact
                // override shrinks the number, not this suffix.
                style: priceStyle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  color: priceStyle.color?.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
