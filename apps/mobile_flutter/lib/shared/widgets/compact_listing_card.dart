/// The `.vcard` compact listing card — a square photo (favourite heart +
/// price pill overlaid), title, spec line, and district-only location row.
/// Differs from [FullListingCard] in three ways: no storey/floors in the
/// spec line, district-only location (no city), smaller favourite heart and
/// title size. Home's Explore Nearby grid was its first caller; any other
/// screen's grid-shaped listing surface (an agent's ads grid, a denser
/// search results mode) is what this was built to also serve.
///
/// Promoted verbatim out of
/// `features/home/widgets/compact_listing_card.dart` — no behavior change,
/// only its address (and its three sub-widget imports) moved to their own
/// new shared homes.
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../formatters/formatters.dart';
import 'favourite_button.dart';
import 'listing_photo.dart';
import 'price_pill.dart';

class CompactListingCard extends StatelessWidget {
  const CompactListingCard({super.key, required this.ad, required this.onTap});

  final Ad ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      key: ValueKey('exploreCard-${ad.id}'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The photo takes whatever height the text below it doesn't, rather
          // than an `AspectRatio(1)` square. At the grid ratio these callers
          // use it lands at roughly square anyway — but a square is a *fixed*
          // height, and a 2-line title on a 360px-wide phone pushed the
          // column 15px past its cell (caught by `agent_profile_screen_test`'s
          // narrow-width case; Home's Explore grid had the identical latent
          // bug, hidden only by fixture titles short enough to fit on one
          // line). Yielding the photo's height is the right trade: a listing
          // photo a few pixels shorter is invisible, a clipped title is not.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.control),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingPhoto(url: ad.photos.isEmpty ? null : ad.photos.first),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                  // `.vcard__ph .fav{top:8px;right:8px}` /
                  // `.vcard__ph .ppill{left:8px;bottom:8px}`.
                  //
                  // The heart is positioned by its 48dp hit box, so the
                  // inset that keeps the painted 28px chip on the mockup's
                  // 8px is -2 (see [FavouriteButton.cornerInset]). The
                  // earlier hand-picked 4 was a compromise that satisfied
                  // neither number: it painted the glyph 14px in — 6px off
                  // `.vcard__ph .fav{top:8px;right:8px}` on the tightest
                  // cell in the app — to save 2px of hit box that is not
                  // reachable anyway, since nothing dispatches a tap past
                  // the photo's own rect.
                  Positioned(
                    right: FavouriteButton.cornerInset(8, size: 28),
                    top: FavouriteButton.cornerInset(8, size: 28),
                    child: FavouriteButton(adId: ad.id, size: 28),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    // The grid override of the pill — see [PricePill.compact].
                    child: PricePill(ad: ad, compact: true),
                  ),
                ],
              ),
            ),
          ),
          // `.vcard__b{padding:8px 2px 0}`.
          const SizedBox(height: AppSpacing.md),
          Text(
            ad.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            // `.vcard__t{font-size:11.5px;font-weight:600;
            // letter-spacing:-.1px}` + `.clamp2{line-height:1.35}`.
            style: type.rowTitle.copyWith(
              color: colors.ink,
              fontSize: 11.5,
              letterSpacing: -0.1,
              height: 1.35,
            ),
          ),
          // `.vcard__b .spec{margin-top:4px}`.
          const SizedBox(height: AppSpacing.xs),
          Text(
            _specLine(ad, context),
            style: type.specMeta.copyWith(color: colors.muted),
          ),
          // `.where{margin-top:2px}`, weight 400 in `--faint` — see
          // `FullListingCard`, which carries the same rule.
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 11, color: colors.faint),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  ad.district,
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
    );
  }

  // See `FullListingCard._specLine` — same promotion to
  // `Formatters.statLine`, with `includeFloor: false` preserving this
  // card's own no-storey/floors rule, and the same AppLocalizations thread
  // for a correctly pluralized room count.
  String _specLine(Ad ad, BuildContext context) => Formatters.statLine(
    ad,
    includeFloor: false,
    l10n: AppLocalizations.of(context),
  );
}
