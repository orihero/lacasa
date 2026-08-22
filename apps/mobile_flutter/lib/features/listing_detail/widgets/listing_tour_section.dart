/// `listing-detail`'s 3D Tour entry (SCREENS.md §7: "embedded 3D tour
/// iframe if `tour3dLink` present"). Renders nothing at all when
/// [Ad.tour3dLink] is absent — the same honest-gap rule
/// `listing_detail_section.dart`'s doc comment documents for Description/
/// Additional Information/Sizes/Nearby Places: a listing with no tour link
/// shows no "3D Tour" heading, rather than a heading over a dead button.
///
/// The spec's own wording ("Photo/video carousel, **or** embedded 3D tour
/// iframe") reads as if the tour replaces the hero carousel outright. It
/// does not, here: an actual `<iframe>`-equivalent — a live
/// [WebViewWidget] — embedded inside a long vertical [ListView] fights that
/// scroll for every touch the tour itself wants to interpret as pan/zoom,
/// the same reason `ListingLocationSection`'s map preview stays
/// non-interactive and pushes to a full screen instead. This section is
/// that same pattern applied to the tour: a tappable preview that pushes
/// [Tour3dViewScreen], where the tour gets the whole screen and no
/// competing gesture arena.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../tour3d_view_args.dart';
import 'listing_detail_section.dart';

class ListingTourSection extends StatelessWidget {
  const ListingTourSection({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final link = ad.tour3dLink;

    return ListingDetailSection(
      title: AppLocalizations.of(context).listingTourSectionTitle,
      child: (link == null || link.trim().isEmpty) ? null : _TourBanner(url: link),
    );
  }
}

class _TourBanner extends StatelessWidget {
  const _TourBanner({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).listingTourViewSemanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(
          RoutePaths.tour3dView,
          extra: Tour3dViewArgs(url: url),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppAccent.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.view_in_ar_rounded,
                  size: 20,
                  color: AppAccent.color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).listingTourBannerLabel,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
