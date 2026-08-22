/// `listing-detail` (SCREENS.md §3.7) — the full property page every
/// listing card in the app links to, and the only screen that pushes
/// `photo-gallery`.
///
/// **Router wiring**: this screen takes the ad id as a constructor
/// argument, so both branch routes that reach it read the same path param:
/// ```dart
/// GoRoute(
///   path: 'listing/:id',
///   builder: (context, state) =>
///       ListingDetailScreen(adId: state.pathParameters['id']!),
/// )
/// ```
/// It is declared under **both** the Home and Search branches (`/home/
/// listing/:id` and `/search/listing/:id`) rather than as one top-level
/// route, because a pushed listing must keep the tab bar and stay inside
/// the back stack of whichever tab the user came from — SCREENS.md §1
/// lists `listing-detail` under "Pushed (full-screen, back-stack)", not
/// under the modal/no-chrome sets that paint on the root navigator. The
/// branch-relative navigation targets this screen emits (`agent-profile`)
/// are therefore resolved from [branchPrefix], not hardcoded.
///
/// **Three states, one route**: loading renders a hero-height skeleton so
/// the layout doesn't jump when the ad arrives; a failed ad fetch renders a
/// terminal retry state (the ad is the screen — see
/// `listing_detail_providers.dart`); a failed *agent* fetch does not reach
/// here at all, degrading inside the agent block alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../contact/contact.dart';
import '../../photo_gallery/photo_gallery.dart';
import '../state/listing_detail_providers.dart';
import 'listing_agent_row.dart';
import 'listing_chip_sections.dart';
import 'listing_detail_bottom_bar.dart';
import 'listing_detail_nav.dart';
import 'listing_detail_panes.dart';
import 'listing_hero.dart';
import 'listing_info_tags.dart';
import 'listing_location_section.dart';
import 'listing_overview_panel.dart';
import 'listing_price_footer.dart';
import 'listing_sizes_section.dart';
import 'listing_tour_section.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({
    super.key,
    required this.adId,
    this.branchPrefix = RoutePaths.home,
  });

  final String adId;

  /// Which shell branch this instance was pushed inside — `/home` or
  /// `/search`. Used to build sibling route paths so tapping the agent
  /// block stays in the same tab's back stack instead of jumping branches.
  final String branchPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final listing = ref.watch(listingDetailProvider(adId));

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: Stack(
        children: [
          listing.when(
            loading: () => const _ListingDetailSkeleton(),
            error: (error, _) => _ListingDetailError(
              error: error,
              onRetry: () => ref.invalidate(listingDetailProvider(adId)),
            ),
            data: (ad) =>
                _ListingDetailBody(ad: ad, branchPrefix: branchPrefix),
          ),
          // Back is available in every state, including the error one —
          // a user who deep-linked to a dead listing must still be able to
          // leave. Share/save appear only once there is an ad to act on.
          ListingDetailNav(ad: listing.value),
          if (listing.value case final ad?)
            ListingDetailBottomBar(
              ad: ad,
              onSubmitApplication: () => _openContactSheet(context, ref, ad),
            ),
        ],
      ),
    );
  }

  /// SCREENS.md §3.7: the CTA opens `contact-sheet` "pre-filled with
  /// listing title + agent". The agent name is whatever
  /// [listingAgentProvider] already resolved for the agent block — read,
  /// not awaited, so the sheet opens instantly and simply omits the name if
  /// that fetch hasn't landed or degraded to null.
  void _openContactSheet(BuildContext context, WidgetRef ref, Ad ad) {
    final agent = ad.agentId.isEmpty
        ? null
        : ref.read(listingAgentProvider(ad.agentId)).value;

    showContactSheet(
      context,
      prefill: ContactPrefill.forListing(
        title: ad.title,
        adId: ad.id,
        agentName: agent?.fullName,
        location: '${ad.district}, ${ad.city}',
        agentAvatarUrl: agent?.avatar,
      ),
    );
  }
}

class _ListingDetailBody extends StatelessWidget {
  const _ListingDetailBody({required this.ad, required this.branchPrefix});

  final Ad ad;
  final String branchPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final description = ad.description?.trim();

    // See `glass_surface.dart`: a Scrollable containing a GlassSurface (the
    // hero's pills, the info tags) must disable Android's stretch overscroll
    // or the lens renders black at the scroll edges.
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        padding: EdgeInsets.only(
          bottom:
              ListingDetailBottomBar.reservedHeight +
              MediaQuery.of(context).padding.bottom,
        ),
        children: [
          ListingHero(
            ad: ad,
            onOpenGallery: (index) => _openGallery(context, index),
          ),
          Padding(
            // `.det__b{padding:13px 14px 0}` — a narrower gutter than the
            // 20px screen default, which AppSpacing.xl's own doc comment
            // flags as this screen's deliberate exception.
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `.panel` — the mockup opens `.det__b` with the Overview
                // card (fact rail + 3-up photo grid) before anything else.
                // It restates what the hero pills and the Sizes pane
                // already carry; see `listing_overview_panel.dart` for why
                // that repetition is the point, and for the conditions
                // under which it renders away entirely.
                ListingOverviewPanel(
                  ad: ad,
                  onOpenGallery: (index) => _openGallery(context, index),
                ),
                // SCREENS.md §7's tour link sits with the photo/video
                // carousel; it renders here instead purely as a matter of
                // this section's own honest-gap mechanism (absent for
                // every ad but the handful that carry `tour3dLink`) — see
                // `listing_tour_section.dart`'s doc comment for why it
                // pushes a full screen rather than embedding inline.
                ListingTourSection(ad: ad),
                // `.segs` + `.pane`: one body at a time, not five stacked
                // headed sections. The section titles double as the segment
                // labels, so no new copy is involved.
                ListingDetailPanes(
                  panes: [
                    ?paneOrNull(
                      l10n.listingDescriptionSectionTitle,
                      _buildDescriptionPane(context, ad, description),
                    ),
                    ?paneOrNull(
                      l10n.listingAdditionalInfoSectionTitle,
                      buildAdditionalInfoOrNull(ad),
                    ),
                    ?paneOrNull(
                      l10n.listingSizesSectionTitle,
                      ListingSizesSection.buildOrNull(l10n, ad),
                    ),
                    ?paneOrNull(
                      l10n.listingNearbyPlacesSectionTitle,
                      buildNearbyPlacesOrNull(ad),
                    ),
                    // Always present — see `listing_location_section.dart`
                    // for why it's the one exception to the drop-if-empty
                    // rule the other panes follow.
                    ListingDetailPane(
                      label: l10n.listingLocationSectionTitle,
                      child: ListingLocationSection(
                        ad: ad,
                        branchPrefix: branchPrefix,
                      ),
                    ),
                  ],
                ),
                ListingAgentRow(
                  ad: ad,
                  onOpen: (agentId) =>
                      context.push('$branchPrefix/agent/$agentId'),
                ),
                SaveThePlaceButton(ad: ad),
                ListingPriceFooter(ad: ad),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The Description pane: the paragraph, then the Type/Category/Repair/
  /// Furniture chips 11dp below it (`.tags{margin-top:11px}`) — the mockup
  /// nests them inside this pane rather than floating them above the body.
  /// Null when the ad carries neither, so the segment disappears with them.
  static Widget? _buildDescriptionPane(
    BuildContext context,
    Ad ad,
    String? description,
  ) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final tags = ListingInfoTags.buildOrNull(context, ad);
    final hasDescription = description != null && description.isNotEmpty;
    if (!hasDescription && tags == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `.pane p{font-size:12px;line-height:1.66;color:var(--ink-2)}`.
        if (hasDescription)
          Text(description, style: type.body.copyWith(color: colors.ink2)),
        if (tags != null) ...[
          if (hasDescription) const SizedBox(height: 11),
          tags,
        ],
      ],
    );
  }

  void _openGallery(BuildContext context, int index) {
    context.push(
      RoutePaths.photoGallery,
      extra: PhotoGalleryArgs(ad: ad, startIndex: index),
    );
  }
}

/// Reserves the hero's exact height plus a few body lines, so the screen
/// does not reflow when the ad lands.
class _ListingDetailSkeleton extends StatelessWidget {
  const _ListingDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: ShimmerBox(
            height: ListingHero.height,
            borderRadius: AppRadii.hero,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, AppSpacing.section, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 220,
                height: 14,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: AppSpacing.base),
              ShimmerBox(
                width: double.infinity,
                height: 11,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: AppSpacing.md),
              ShimmerBox(
                width: 180,
                height: 11,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The ad fetch is terminal for this screen — there is no partial listing
/// worth rendering. A 404 gets its own copy: "try again" is bad advice for
/// a listing that has been removed, and the two are not the same problem.
class _ListingDetailError extends StatelessWidget {
  const _ListingDetailError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  bool get _isNotFound =>
      error is ApiErrorException &&
      (error as ApiErrorException).code == ApiErrorCode.notFound;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: _isNotFound
            ? FullWidthState(
                icon: Icons.search_off_rounded,
                message: l10n.listingNotFoundMessage,
              )
            : FullWidthState(
                icon: Icons.error_outline_rounded,
                message: l10n.listingLoadErrorMessage,
                actionLabel: l10n.sharedRetryLabel,
                onAction: onRetry,
              ),
      ),
    );
  }
}
