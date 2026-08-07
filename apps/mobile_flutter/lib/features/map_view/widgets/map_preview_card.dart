/// The mini preview that slides up when a pin is tapped (SCREENS.md §3.6:
/// "Tap pin → mini preview card (thumbnail, title, price, `{rooms} room`) →
/// tap → `listing-detail`").
///
/// **Its four fields are exactly the four the spec names**, and `{rooms}
/// room` is rendered in the spec's own un-pluralized form rather than
/// `Formatters.statLine`'s richer `3 rooms · 72 m²` — this is the one place
/// SCREENS.md pins a distinct, narrower format, and three implementations
/// agreeing on it matters more than internal consistency with a line that
/// belongs to a different screen.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({super.key, required this.ad, required this.onTap});

  final Ad ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final rooms = ad.rooms;

    return GestureDetector(
      key: ValueKey('mapPreview-${ad.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: SizedBox(
                width: 68,
                height: 68,
                child: ListingPhoto(
                  url: ad.photos.isEmpty ? null : ad.photos.first,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.price(ad),
                    style: LaCasaTypography.tabular(
                      type.cardPrice,
                    ).copyWith(color: colors.ink),
                  ),
                  // Dropped rather than shown as "null room" when the ad
                  // states no room count — the same honest-gap rule
                  // `listing-detail`'s sections follow.
                  if (rooms != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$rooms room',
                      style: type.specMeta.copyWith(color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.faint,
            ),
          ],
        ),
      ),
    );
  }
}
