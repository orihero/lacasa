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
                  Positioned(
                    right: 6,
                    top: 6,
                    child: FavouriteButton(adId: ad.id, size: 28),
                  ),
                  Positioned(left: 6, bottom: 6, child: PricePill(ad: ad)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ad.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: type.rowTitle.copyWith(color: colors.ink, fontSize: 11.5),
          ),
          const SizedBox(height: 3),
          Text(
            _specLine(ad),
            style: type.specMeta.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 11, color: colors.muted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  ad.district,
                  overflow: TextOverflow.ellipsis,
                  style: type.specMeta.copyWith(color: colors.muted),
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
  // card's own no-storey/floors rule.
  String _specLine(Ad ad) => Formatters.statLine(ad, includeFloor: false);
}
