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
import '../../theme/theme.dart';
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
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: GlassSurface(
                        variant: GlassVariant.onPhoto,
                        borderRadius: AppRadii.pill,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          isSale ? 'Sale' : 'Rent',
                          style: type.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: FavouriteButton(adId: ad.id),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: PricePill(ad: ad),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ad.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: type.cardTitle.copyWith(color: colors.ink),
            ),
            const SizedBox(height: 3),
            Text(
              _specLine(ad),
              style: type.specMeta.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 12, color: colors.muted),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${ad.district}, ${ad.city}',
                    overflow: TextOverflow.ellipsis,
                    style: type.specMeta.copyWith(color: colors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _specLine(Ad ad) {
    final rooms = ad.rooms;
    final roomsPart = rooms == null
        ? null
        : '$rooms room${rooms == 1 ? '' : 's'}';
    final areaPart = ad.area == null ? null : '${_trimNum(ad.area!)} m²';
    final floorPart = (ad.storey != null && ad.floors != null)
        ? '${ad.storey}/${ad.floors}'
        : null;
    return [roomsPart, areaPart, floorPart].whereType<String>().join(' · ');
  }

  String _trimNum(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }
}
