/// The `.ppill g` price pill overlaid on a listing photo — glass-over-photo
/// (`GlassVariant.onPhoto`), `$ {price}` for a sale or `$ {price}/month`
/// for a rent, the `/month` portion rendered smaller/lighter per the build
/// spec's "Price formatting" section (mirrors the source's
/// `.ppill span{opacity:.8; font-size:9.5px}`).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../theme/theme.dart';
import '../formatters/home_formatters.dart';

class PricePill extends StatelessWidget {
  const PricePill({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isRent = ad.category == AdCategory.rent;
    final priceStyle = LaCasaTypography.tabular(
      type.cardPrice,
    ).copyWith(color: colors.ink);

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text.rich(
        TextSpan(
          text: '\$ ${HomeFormatters.groupedPrice(ad)}',
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
