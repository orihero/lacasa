/// The `.ppill g` price pill overlaid on a listing photo — glass-over-photo
/// (`GlassVariant.onPhoto`), `$ {price}` for a USD sale or `$ {price}/month`
/// for a USD rent, the `/month` portion rendered smaller/lighter (mirrors
/// the source mockup's `.ppill span{opacity:.8; font-size:9.5px}`). Any card
/// or tile that shows a price over a photo — Home's rails, `listing-search`
/// results, `map-view`'s pin preview — should use this rather than
/// hand-rolling the same glass+text combination.
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
  const PricePill({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isRent = ad.category == AdCategory.rent;
    final priceStyle = LaCasaTypography.tabular(
      type.cardPrice,
    ).copyWith(color: colors.ink);
    final body = ad.priceType == CurrencyCode.uzs
        ? '${Formatters.groupedPrice(ad)} ${l10n.listingEditorPriceTypeUzsOption}'
        : '\$ ${Formatters.groupedPrice(ad)}';

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text.rich(
        TextSpan(
          text: body,
          style: priceStyle,
          children: [
            if (isRent)
              TextSpan(
                text: '/month',
                style: priceStyle.copyWith(
                  fontSize: (priceStyle.fontSize ?? 14) * 0.68,
                  color: priceStyle.color?.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
