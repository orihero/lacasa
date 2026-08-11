/// The `.rail.promos` carousel: two full-bleed photo cards. **Also
/// non-interactive** (build spec, "Promo carousel" — neither `<article
/// class="promo">` nor its `.promo__go` arrow carries a `data-go` in the
/// source markup, flagged there as a divergence worth surfacing since
/// README's own decorative list doesn't call this out). No `onTap`
/// anywhere in this file, deliberately.
///
/// Copy is a hardcoded local list — no promotions/CMS endpoint is
/// documented anywhere in SCREENS.md. The photo background is a themed
/// gradient placeholder rather than a real image for the same reason
/// `ListingPhoto` falls back to one: there is nothing to point a network
/// image at without inventing a URL.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';

class _PromoSpec {
  const _PromoSpec({
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
  /// Pre-joined with the same `\n` the original two-element `titleLines`
  /// list was rendered with (`spec.titleLines.join('\n')`) — the ARB
  /// message itself now carries that newline, so there is nothing left to
  /// join at render time.
  final String title;
  final String subtitle;
  final Gradient gradient;
}

/// Built from [AppLocalizations] rather than a top-level `final` list (the
/// original shape) since every string is now a localized lookup, which
/// requires a [BuildContext] and so cannot be a compile-time/top-level
/// constant.
List<_PromoSpec> _promos(AppLocalizations l10n) => [
  _PromoSpec(
    title: l10n.homePromoOneTitle,
    subtitle: l10n.homePromoOneSubtitle,
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6C63FF), Color(0xFF3B2E8A)],
    ),
  ),
  _PromoSpec(
    title: l10n.homePromoTwoTitle,
    subtitle: l10n.homePromoTwoSubtitle,
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E8A6B), Color(0xFF14432F)],
    ),
  ),
];

class PromoCarousel extends StatelessWidget {
  const PromoCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final promos = _promos(AppLocalizations.of(context));

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        itemCount: promos.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.base),
        itemBuilder: (context, index) => _PromoCard(spec: promos[index]),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.spec});

  final _PromoSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        gradient: spec.gradient,
        boxShadow: AppShadows.floatingPromo,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Bottom scrim so the white copy stays legible.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.base,
            right: AppSpacing.base,
            bottom: AppSpacing.base,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: GlassSurface(
              variant: GlassVariant.onPhoto,
              borderRadius: AppRadii.pill,
              width: 26,
              height: 26,
              alignment: Alignment.center,
              child: const Icon(
                Icons.north_east_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
