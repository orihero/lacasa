/// SCREENS.md §3.7's **Location** section — "map pin at the listing's real
/// coordinates". The spec's own preamble flags this as one of two web bugs
/// it deliberately fixes: web renders a dummy pin here, this does not.
///
/// **This now draws a real map.** `flutter_map` + `latlong2` (OSM tiles, the
/// same source `apps/web`'s Leaflet map uses, no API key) landed with
/// `map-view`, and this widget was written from the start to be the only
/// thing that had to change when they did — it already received the [Ad]
/// and already gated on [Ad.hasPin]. The preview is deliberately
/// non-interactive: panning a 118px-tall box nested inside a long vertical
/// scroll fights the page scroll for the same gesture and loses. Tapping it
/// opens `map-view`, which is interactive and full-screen.
///
/// **Unlike every other section here, this one renders even with no data.**
/// "We don't know where this is" is information a buyer acts on, so an ad
/// with no pin (`ad-1008` in the fixtures) still shows the heading and an
/// honest line — where an ad with no `optionList` simply drops Additional
/// Information entirely. See `listing_detail_section.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/map/map_attribution.dart';
import '../../../shared/map/map_defaults.dart';
import '../../../shared/map/map_tile_layer_provider.dart';
import '../../../theme/theme.dart';
import '../formatters/listing_detail_formatters.dart';

class ListingLocationSection extends ConsumerWidget {
  const ListingLocationSection({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    if (!ad.hasPin) return _NoLocation(colors: colors);

    final point = LatLng(ad.lat!, ad.lng!);
    final place = [
      ad.district,
      ad.city,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return GestureDetector(
      key: const ValueKey('listingLocationMap'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(RoutePaths.mapView, extra: <Ad>[ad]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 168,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: MapDefaults.listingZoom,
                  // Every gesture off: this box lives inside a tall
                  // SingleChildScrollView, and a map that eats vertical
                  // drags makes the page feel broken. `map-view` is the
                  // interactive one.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  ref.watch(mapTileLayerProvider),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.place_rounded,
                          size: 30,
                          color: AppAccent.color,
                        ),
                      ),
                    ],
                  ),
                  // OSM licence term, not decoration — see MapDefaults.
                  const MapAttribution(),
                ],
              ),
              // The place name and coordinates stay on screen. The
              // coordinates in particular are the one piece of location
              // data a buyer can paste into any other maps app, and losing
              // them to a prettier preview would be a downgrade.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CaptionBar(ad: ad, place: place),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionBar extends StatelessWidget {
  const _CaptionBar({required this.ad, required this.place});

  final Ad ad;
  final String place;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final coordinates = ListingDetailFormatters.coordinates(ad);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      color: colors.card.withValues(alpha: 0.9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (place.isNotEmpty)
                  Text(
                    place,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                if (coordinates != null)
                  Text(
                    coordinates,
                    overflow: TextOverflow.ellipsis,
                    style: LaCasaTypography.tabular(
                      type.micro,
                    ).copyWith(color: colors.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.open_in_full_rounded, size: 15, color: colors.faint),
        ],
      ),
    );
  }
}

/// The no-coordinates case — kept as the same `sunk` panel shape this
/// section has always used, so an ad with no pin reads as "we don't know",
/// not as a map that failed to load.
class _NoLocation extends StatelessWidget {
  const _NoLocation({required this.colors});

  final LaCasaColors colors;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

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
          Icon(Icons.location_off_rounded, size: 20, color: colors.faint),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).listingNoLocationMessage,
            textAlign: TextAlign.center,
            style: type.bodySmall.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
