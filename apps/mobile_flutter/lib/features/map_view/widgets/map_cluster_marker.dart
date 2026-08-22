/// A cluster badge on `map-view` — what `flutter_map_marker_cluster` draws
/// in place of overlapping [MapPinMarker]s, restyled in this app's own
/// tokens rather than the package's stock circle-with-black-text default.
///
/// README.md flagged clustering as an open gap and explicitly rejected a
/// hand-rolled density approximation in favour of a real clustering
/// package; this is that package's badge, wired through
/// `MarkerClusterLayerOptions.builder` in `map_view_screen.dart`.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';

/// The fixed square box `MarkerClusterLayerOptions.computeSize` hands back
/// for a cluster of [count] pins.
///
/// Growing with digit count (rather than one fixed size for every cluster)
/// is what keeps `99+`-style counts from being squeezed or clipped inside a
/// circle sized for a single digit — the same reasoning `MapPinMarker`
/// applies to its own pill via `TextOverflow.ellipsis`, just solved up
/// front here because the cluster package needs a size before it builds
/// the widget, not after.
abstract final class MapClusterMetrics {
  static double sizeFor(int count) {
    if (count < 10) return 40;
    if (count < 100) return 46;
    return 52;
  }
}

class MapClusterMarker extends StatelessWidget {
  const MapClusterMarker({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    // Capped display rather than an ever-widening badge — the box itself is
    // already capped by MapClusterMetrics.sizeFor, so a literal 4-digit
    // count would be the one thing here that could still overflow it.
    final label = count > 99 ? '99+' : '$count';

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).mapClusterSemanticsLabel(count),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppAccent.color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LaCasaTypography.tabular(type.micro).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
