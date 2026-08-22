/// The mini preview that slides up when a pin is tapped (SCREENS.md §3.6:
/// "Tap pin → mini preview card (thumbnail, title, price, `{rooms} room`) →
/// tap → `listing-detail`").
///
/// **Its four fields are exactly the four the spec names**, rendered via
/// [AppLocalizations.listingRoomsCount] rather than `Formatters.statLine`'s
/// richer `3 rooms · 72 m²` — this is the one place SCREENS.md pins a
/// distinct, narrower single-field format, and three implementations
/// agreeing on it matters more than internal consistency with a line that
/// belongs to a different screen.
///
/// **Pluralization, added by the i18n pass.** SCREENS.md's own `{rooms}
/// room` wording is un-pluralized (always literally "room", the English
/// singular, regardless of count) — the pre-i18n Dart interpolation this
/// replaced reproduced that literally, which is grammatically wrong for
/// `rooms != 1` and, worse, silently un-fixable for a translator once
/// baked into one concatenated string (see `lib/l10n/README.md`'s
/// "Plurals" section, which names this exact call site). The ICU plural
/// this now goes through renders "1 room" / "2 rooms" correctly in
/// English and gives Russian's four plural categories a real place to
/// live — a deliberate, documented correction of the interpolation bug,
/// not a copy change (SCREENS.md's own wording is a spec shorthand, not
/// a literal singular-only requirement).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
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
      // `.map__prev{border-radius:24px;padding:9px}` wrapping an `.lcard`.
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
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
            // `.lcard__ph{width:106px;height:96px;border-radius:16px}`.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 106,
                height: 96,
                child: ListingPhoto(
                  url: ad.photos.isEmpty ? null : ad.photos.first,
                ),
              ),
            ),
            // `.lcard{gap:12px}`.
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // `.lcard__b` leads with the price (`.lcard__p`, 14/700),
                  // then the title (`.lcard__t`, 12/600), then the spec
                  // line — the order a buyer scans a map result in.
                  Text(
                    Formatters.price(ad),
                    style: LaCasaTypography.tabular(
                      type.cardPrice,
                    ).copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle.copyWith(
                      fontSize: 12,
                      color: colors.ink,
                    ),
                  ),
                  // Dropped rather than shown as "null room" when the ad
                  // states no room count — the same honest-gap rule
                  // `listing-detail`'s sections follow.
                  if (rooms != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).listingRoomsCount(rooms),
                      style: type.specMeta.copyWith(color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
