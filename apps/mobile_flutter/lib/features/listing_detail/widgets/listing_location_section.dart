/// SCREENS.md §3.7's **Location** section — "map pin at the listing's real
/// coordinates". The spec's own preamble flags this as one of two web bugs
/// it deliberately fixes: web renders a dummy pin here, this does not.
///
/// **There is no map widget yet, and this block does not pretend there is.**
/// `flutter_map` + `latlong2` were the chosen dependencies (matching
/// `apps/web`'s Leaflet/OSM — no API key needed) but were reverted when
/// `map-view` went unbuilt, rather than left in the pubspec unused. So this
/// renders the `.mapblock` shape the mockup specifies — a `sunk` panel with
/// a pin, the place label, and the ad's real coordinates — and says plainly
/// that the map itself is unavailable, instead of drawing a decorative
/// grid that reads as a real map of somewhere.
///
/// The coordinates are shown as text because they are the one piece of
/// genuine location data this screen *does* have, and a buyer can paste
/// them into any maps app. When re-adding `flutter_map`, this widget is the
/// only thing that has to change: it already receives the [Ad] and gates on
/// [Ad.hasPin].
///
/// **Unlike every other section here, this one renders even with no data.**
/// "We don't know where this is" is information a buyer acts on, so an ad
/// with no pin (`ad-1008` in the fixtures) still shows the heading and an
/// honest line — where an ad with no `optionList` simply drops Additional
/// Information entirely. See `listing_detail_section.dart`.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../theme/theme.dart';
import '../formatters/listing_detail_formatters.dart';

class ListingLocationSection extends StatelessWidget {
  const ListingLocationSection({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final coordinates = ListingDetailFormatters.coordinates(ad);
    final place = [
      ad.district,
      ad.city,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            coordinates == null
                ? Icons.location_off_rounded
                : Icons.place_rounded,
            size: 20,
            color: coordinates == null ? colors.faint : AppAccent.color,
          ),
          const SizedBox(height: AppSpacing.md),
          if (coordinates == null)
            Text(
              'No location provided for this listing.',
              textAlign: TextAlign.center,
              style: type.bodySmall.copyWith(color: colors.muted),
            )
          else ...[
            if (place.isNotEmpty)
              Text(
                place,
                textAlign: TextAlign.center,
                style: type.rowTitle.copyWith(color: colors.ink2),
              ),
            const SizedBox(height: 3),
            Text(
              coordinates,
              textAlign: TextAlign.center,
              style: LaCasaTypography.tabular(
                type.micro,
              ).copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Map preview not available yet',
              textAlign: TextAlign.center,
              style: type.micro.copyWith(color: colors.faint),
            ),
          ],
        ],
      ),
    );
  }
}
