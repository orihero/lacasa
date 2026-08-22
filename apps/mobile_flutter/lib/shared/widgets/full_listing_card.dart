/// The `.fcard` full listing card — a photo (favourite heart + category
/// badge + price pill overlaid), title, spec line, and location row. Home's
/// Featured Listings rail was its first caller; `listing-search`'s vertical
/// results list is the shape this card was built to also serve, which is
/// why it lives here rather than staying private to `features/home/`.
///
/// Promoted verbatim out of `features/home/widgets/full_listing_card.dart`
/// — no behavior change, only its address (and its three sub-widget
/// imports) moved to their own new shared homes.
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../formatters/formatters.dart';
import 'favourite_button.dart';
import 'listing_photo.dart';
import 'price_pill.dart';

class FullListingCard extends StatelessWidget {
  const FullListingCard({super.key, required this.ad, required this.onTap});

  final Ad ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isSale = ad.category == AdCategory.sale;

    return GestureDetector(
      key: ValueKey('featuredCard-${ad.id}'),
      onTap: onTap,
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 230,
              height: 148,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ListingPhoto(
                      url: ad.photos.isEmpty ? null : ad.photos.first,
                    ),
                    // Gradient scrim under any overlaid glass so labels stay
                    // legible on bright photography.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.32),
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.42),
                          ],
                          stops: const [0.0, 0.28, 0.6, 1.0],
                        ),
                      ),
                    ),
                    // Overlay insets are per-overlay in the source
                    // (`.fcard__ph .badge{top:11px;left:10px}`,
                    // `.fcard__ph .fav{top:9px;right:9px}`,
                    // `.fcard__ph .ppill{left:10px;bottom:10px}`), not one
                    // uniform gutter — the heart sits slightly tighter to
                    // the corner than the badge it optically balances.
                    Positioned(
                      left: 10,
                      top: 11,
                      child: GlassSurface(
                        variant: GlassVariant.onPhoto,
                        borderRadius: AppRadii.pill,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          isSale
                              ? AppLocalizations.of(
                                  context,
                                ).sharedListingCardSaleBadgeLabel
                              : AppLocalizations.of(
                                  context,
                                ).sharedListingCardRentBadgeLabel,
                          style: type.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    // 2, not the rule's 9: [FavouriteButton] centres its
                    // painted 34px chip inside a 48dp hit box, so the inset
                    // that positions the *box* has to give back the 7px of
                    // transparent margin for the *chip* to keep landing
                    // where `.fcard__ph .fav{top:9px;right:9px}` puts it.
                    // Left at 9 the heart painted ~16px in — the drift this
                    // arithmetic exists to prevent. See
                    // [FavouriteButton.cornerInset].
                    Positioned(
                      right: FavouriteButton.cornerInset(9),
                      top: FavouriteButton.cornerInset(9),
                      child: FavouriteButton(adId: ad.id),
                    ),
                    Positioned(left: 10, bottom: 10, child: PricePill(ad: ad)),
                  ],
                ),
              ),
            ),
            // `.fcard__b{padding:9px 3px 0}`.
            const SizedBox(height: 9),
            Text(
              ad.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              // `.fcard__t{font-size:12.5px;font-weight:600;
              // letter-spacing:-.1px}` + `.clamp2{line-height:1.35}`. Not
              // the `cardTitle` role (13.5/700) — that one is
              // `agents-directory`'s `.acard__n`, a different rule.
              style: type.rowTitle.copyWith(
                fontSize: 12.5,
                letterSpacing: -0.1,
                height: 1.35,
                color: colors.ink,
              ),
            ),
            // `.fcard__b .spec{margin-top:5px}`.
            const SizedBox(height: 5),
            Text(
              _specLine(ad, context),
              style: type.specMeta.copyWith(color: colors.muted),
            ),
            // `.where{margin-top:2px}` — and `.where` is weight 400 in
            // `--faint` with an 11px glyph, one step quieter than the
            // `.spec` line above it, not a second copy of it.
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 11, color: colors.faint),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${ad.district}, ${ad.city}',
                    overflow: TextOverflow.ellipsis,
                    style: type.specMeta.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.faint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // The spec line's rules moved to `Formatters.statLine` once
  // `listing-detail` needed the identical strings — see that method's doc
  // comment. Same output as the private helper this replaced. Passes
  // AppLocalizations through so the room count pluralizes correctly (see
  // Formatters.rooms's own doc comment for why that parameter is optional).
  String _specLine(Ad ad, BuildContext context) =>
      Formatters.statLine(ad, l10n: AppLocalizations.of(context));
}
