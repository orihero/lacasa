/// One pin on `map-view` — a price-labelled capsule rather than a generic
/// teardrop.
///
/// A map of listings is a map of *prices*: the number is what a buyer scans
/// for, and a field of identical pins forces them to tap each one to learn
/// anything. `PricePill`'s own formatting is reused via
/// [Formatters.price] so the figure on the pin, on the card and on
/// `listing-detail` is produced by one algorithm.
///
/// The selected pin is drawn in the accent colour and slightly larger, so
/// the preview card at the bottom of the screen is unambiguously tied to a
/// point on the map.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

/// The marker's fixed box, exported so `map_view_screen.dart` can hand the
/// same numbers to `Marker(width:, height:)` — flutter_map needs them up
/// front and a mismatch clips the label.
abstract final class MapPinMetrics {
  static const double width = 86;
  static const double height = 34;
}

class MapPinMarker extends StatelessWidget {
  const MapPinMarker({
    super.key,
    required this.ad,
    required this.selected,
    required this.onTap,
  });

  final Ad ad;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: '${ad.title}, ${Formatters.price(ad)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppAccent.color : colors.card,
              borderRadius: AppRadii.pill,
              border: Border.all(
                color: selected ? AppAccent.color : colors.line,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              Formatters.price(ad),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LaCasaTypography.tabular(type.micro).copyWith(
                color: selected ? Colors.white : colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
