/// `.pricefoot` — "Asking price" over the price and, when the ad states a
/// usable area, the derived per-square-metre figure beside it.
///
/// The bottom bar shows the same price a few pixels below this, which reads
/// as redundant on a tall screen and is not: the bar floats over whatever
/// section the user has scrolled to, so this is the only place the price
/// appears *in* the document, next to the sizes it is a function of. It is
/// also the only place price-per-m² appears at all.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../formatters/listing_detail_formatters.dart';

class ListingPriceFooter extends StatelessWidget {
  const ListingPriceFooter({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final perSqm = ListingDetailFormatters.pricePerSqm(ad);

    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 6, right: 6, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asking price',
            style: type.bodySmall.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              text: Formatters.price(ad),
              style: LaCasaTypography.tabular(
                type.price,
              ).copyWith(color: colors.ink),
              children: [
                if (perSqm != null)
                  TextSpan(
                    text: '  ·  $perSqm',
                    style: LaCasaTypography.tabular(type.bodySmall).copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
