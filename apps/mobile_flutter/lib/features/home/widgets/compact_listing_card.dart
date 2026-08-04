/// The `.vcard` compact listing card used by the Explore Nearby grid.
/// Differs from [FullListingCard] in three ways (build spec, "Explore
/// Nearby grid"): no storey/floors in the spec line, district-only
/// location (no city), smaller favourite heart and title size.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../theme/theme.dart';
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
          AspectRatio(
            aspectRatio: 1,
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

  String _specLine(Ad ad) {
    final rooms = ad.rooms;
    final roomsPart = rooms == null
        ? null
        : '$rooms room${rooms == 1 ? '' : 's'}';
    final areaPart = ad.area == null ? null : '${_trimNum(ad.area!)} m²';
    return [roomsPart, areaPart].whereType<String>().join(' · ');
  }

  String _trimNum(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }
}
