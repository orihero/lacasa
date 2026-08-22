/// The `.lcard` **row** listing card — a fixed 106x96 photo (category badge
/// + favourite heart overlaid) beside a text column whose first line is the
/// price. This is the shape `listing-search`'s vertical results list uses;
/// it is deliberately *not* [FullListingCard], which implements the mockup's
/// other card, `.fcard` (a 230px-wide column with the price pill overlaid on
/// the photo) — the shape Home's Featured Listings rail needs and which
/// renders as a half-width column when dropped into a vertical list.
///
/// `.lcard` is a global class in the mockup, so this lives in `lib/shared/`
/// alongside `.fcard`/`.vcard`: `listing-search` is its first caller, and
/// saved-listings / my-listings / any other full-width results list is what
/// it was promoted here to also serve, rather than re-implemented.
///
/// Two content details differ from the shared cards on purpose, both
/// straight from the mockup's `.lcard` rules:
///  - the price is the first *body* line (`.lcard__p`, 14/700/-0.4 ink with
///    a 10.5/400 muted rental-period suffix), not a glass [PricePill] over
///    the photo —
///    only `.badge` and `.fav` sit on a `.lcard`'s photo;
///  - the price string is built here rather than through [PricePill],
///    because `.lcard__p` is body text with its own weight/colour rather
///    than glass over a photo. It agrees with [Formatters.price] on the
///    unspaced `$78,000` form, which that formatter now emits too.
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../formatters/formatters.dart';
import 'favourite_button.dart';
import 'listing_photo.dart';

class RowListingCard extends StatelessWidget {
  const RowListingCard({super.key, required this.ad, required this.onTap});

  final Ad ad;
  final VoidCallback onTap;

  /// `.lcard__ph{width:106px;height:96px;border-radius:16px;flex:none}`.
  static const double _photoWidth = 106;
  static const double _photoHeight = 96;

  /// `.lcard__ph .badge{top:7px;left:7px}` / `.lcard .fav{top:7px;right:7px}`.
  static const double _overlayInset = 7;

  /// `.lcard .fav{width:26px;height:26px}`.
  static const double _favSize = 26;

  /// [_overlayInset] compensated for the transparent margin [FavouriteButton]
  /// carries around its painted chip — negative here, which is expected on
  /// this card: see [FavouriteButton.cornerInset] for why the couple of
  /// pixels of hit box that fall outside the photo cost nothing.
  static final double _favInset = FavouriteButton.cornerInset(
    _overlayInset,
    size: _favSize,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);
    final isSale = ad.category == AdCategory.sale;

    return GestureDetector(
      // Kept from the `FullListingCard` this replaced — `listing-search`'s
      // tests find a result row by this key.
      key: ValueKey('featuredCard-${ad.id}'),
      onTap: onTap,
      // `.lcard glf` is flat glass, but this card already carries two
      // `.g` lenses over its photo (badge + heart) and a results list shows
      // ~20 of them at once. `glass_surface.dart`'s hard rule — never nest
      // lenses — wins over the material here: the card body is painted as
      // the opaque card colour with `.glf`'s hairline, and only the two
      // over-photo overlays stay real glass.
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadii.cardLg),
          border: Border.all(color: colors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _photoWidth,
              height: _photoHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ListingPhoto(
                      url: ad.photos.isEmpty ? null : ad.photos.first,
                    ),
                    // `.scrim` — keeps the glass badge/heart legible on
                    // bright photography.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.42),
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          stops: const [0.0, 0.26, 0.46, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: _overlayInset,
                      top: _overlayInset,
                      child: GlassSurface(
                        variant: GlassVariant.onPhoto,
                        borderRadius: AppRadii.pill,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        child: Text(
                          isSale
                              ? l10n.sharedListingCardSaleBadgeLabel
                              : l10n.sharedListingCardRentBadgeLabel,
                          style: type.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    // The badge above is positioned by what it paints, the
                    // heart by its 48dp [TapTarget] box — so only the heart
                    // needs [_overlayInset] adjusted for the transparent
                    // margin around its chip, or it paints 11px further in
                    // than `.lcard .fav{top:7px;right:7px}` asks.
                    Positioned(
                      right: _favInset,
                      top: _favInset,
                      child: FavouriteButton(adId: ad.id, size: _favSize),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              // `.lcard__b{padding:3px 2px 0}`.
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _priceLine(context, colors, type, l10n),
                    const SizedBox(height: 3),
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowTitle.copyWith(
                        color: colors.ink,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      Formatters.statLine(ad, l10n: l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.specMeta.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: colors.faint,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${ad.district}, ${ad.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: type.specMeta.copyWith(
                              color: colors.faint,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.lcard__p` — `$78,000`, or `$350` + `sharedPricePerMonthSuffix` with
  /// the suffix at 10.5/400/muted. UZS ads keep [PricePill]'s "so'm" suffix
  /// convention instead of a misleading `$` prefix (see that widget's doc
  /// comment), and the rental-period suffix is localized for the same
  /// reason: it is rendered one string-concatenation away from a "so'm"
  /// that already came out of [AppLocalizations], so hardcoding the English
  /// "/month" put two scripts in one price line on every ru/uz rental.
  Widget _priceLine(
    BuildContext context,
    LaCasaColors colors,
    LaCasaTypography type,
    AppLocalizations l10n,
  ) {
    final priceStyle = LaCasaTypography.tabular(
      type.cardPrice,
    ).copyWith(color: colors.ink);
    final body = ad.priceType == CurrencyCode.uzs
        ? '${Formatters.groupedPrice(ad)} ${l10n.listingEditorPriceTypeUzsOption}'
        : '\$${Formatters.groupedPrice(ad)}';

    return Text.rich(
      TextSpan(
        text: body,
        style: priceStyle,
        children: [
          if (ad.category == AdCategory.rent)
            TextSpan(
              text: l10n.sharedPricePerMonthSuffix,
              style: type.specMeta.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
