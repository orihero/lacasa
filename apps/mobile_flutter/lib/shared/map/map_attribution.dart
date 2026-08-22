/// The OpenStreetMap attribution chip every map surface must carry.
///
/// **Not `flutter_map`'s own [SimpleAttributionWidget].** That one renders
/// `flutter_map | © {source}` in an unbounded `Row(mainAxisSize: min)` at
/// default body size, which overflows a 390px phone by ~128px (caught by
/// `listing_detail_screen_test.dart`'s narrow-width guard) and prefixes a
/// `©` of its own, so a source string that already carries one prints it
/// twice. It also credits the rendering library ahead of the data
/// provider, which is backwards: OSM's licence is the obligation here,
/// flutter_map's is not.
///
/// This is deliberately small and low-contrast but never hidden and never
/// clipped — attribution is a licence term for OSM tiles, not decoration
/// the design gets to drop.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'map_defaults.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(
              MapDefaults.osmAttribution,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.micro.copyWith(color: colors.muted, fontSize: 9),
            ),
          ),
        ),
      ),
    );
  }
}
