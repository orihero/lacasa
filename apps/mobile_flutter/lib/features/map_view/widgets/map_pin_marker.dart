/// One pin on `map-view` — a price-labelled capsule rather than a generic
/// teardrop.
///
/// A map of listings is a map of *prices*: the number is what a buyer scans
/// for, and a field of identical pins forces them to tap each one to learn
/// anything. The label is [Formatters.abbreviatedPrice] — `$78k`, `$1.2k`,
/// `$350`, no `/month` suffix — matching the source mockup's own pins,
/// which a 30px capsule with `0 11px` of padding has room for where the
/// full grouped price does not. The pin's *semantics* label still carries
/// the exact [Formatters.price] string, so nothing is lost to a screen
/// reader by the visual abbreviation.
///
/// The selected pin is drawn as the dark ink pill (`.map__pin.on`), so the
/// preview card at the bottom of the screen is unambiguously tied to a
/// point on the map.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

/// The marker's fixed box, exported so `map_view_screen.dart` can hand the
/// same numbers to `Marker(width:, height:)` — flutter_map needs them up
/// front and a mismatch clips the label.
abstract final class MapPinMetrics {
  /// Wider than the pill itself needs (`$78k` is ~55dp at 11/700): the box
  /// is fixed per-marker, so it has to hold the longest label any ad can
  /// produce — a UZS ad's `800k so'm`.
  static const double width = 96;

  /// `.map__pin{height:30px}`.
  static const double height = 30;
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
      label: AppLocalizations.of(
        context,
      ).mapPinSemanticsLabel(ad.title, Formatters.price(ad)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: MapPinMetrics.height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              // `.map__pin.on{background:var(--pill);color:var(--pill-ink)}`
              // with its glass layers suppressed — the selected pin is the
              // dark ink pill, not an accent one. Unselected keeps
              // `.map__pin gl`: card fill, hairline border.
              color: selected ? colors.pill : colors.card,
              borderRadius: AppRadii.pill,
              border: selected ? null : Border.all(color: colors.line),
              boxShadow: selected
                  // `0 8px 18px -6px rgba(21,21,27,.7)`.
                  ? AppShadows.selectedPillLarge
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              Formatters.abbreviatedPrice(
                ad,
                l10n: AppLocalizations.of(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // `.map__pin{font-size:11px;font-weight:700}` — `specMeta` is
              // the letter-spacing-free role at this band (see `PricePill`).
              style: LaCasaTypography.tabular(type.specMeta).copyWith(
                fontSize: 11,
                color: selected ? colors.pillInk : colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
