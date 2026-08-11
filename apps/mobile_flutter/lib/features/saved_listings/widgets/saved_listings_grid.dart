/// `saved-listings`'s (SCREENS.md §3.17) whole body: a 2-column grid of
/// [CompactListingCard]s bound to [savedListingsProvider], same grid
/// geometry as `features/agents/widgets/agent_ads_grid.dart` (2 columns, 13px
/// gutters, 0.66 aspect ratio) since §3.17 reuses the same "Shared Listing
/// Card component" that screen does.
///
/// Unlike `AgentAdsGrid`, this *is* the whole screen's content rather than
/// one section of a longer page, so a failed fetch gets the full-width
/// [FullWidthState] (with Retry) `agents-directory` uses for its own list,
/// not a scoped [RailRetryCard] — there is no identity block above this one
/// worth protecting from a blank grid.
///
/// Empty state copy is §3.17's own, quoted verbatim: "You haven't saved any
/// listings yet."
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/saved_listings_providers.dart';

class SavedListingsGrid extends ConsumerWidget {
  const SavedListingsGrid({super.key, required this.onOpenListing});

  /// Called with the tapped ad's id. The screen owns the branch-relative
  /// push target, same split `AgentAdsGrid.onOpenListing` uses.
  final void Function(String adId) onOpenListing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedListingsProvider);
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(savedListingsProvider.future),
      child: saved.when(
        loading: () => const _SkeletonGrid(),
        error: (error, stackTrace) => _ScrollableState(
          child: FullWidthState(
            icon: Icons.cloud_off_rounded,
            message: l10n.savedListingsLoadErrorMessage,
            actionLabel: l10n.sharedRetryLabel,
            onAction: () => ref.invalidate(savedListingsProvider),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _ScrollableState(
              child: FullWidthState(
                icon: Icons.favorite_border_rounded,
                message: l10n.savedListingsEmptyStateMessage,
              ),
            );
          }
          return _Grid(
            children: list
                .map(
                  (ad) => CompactListingCard(
                    ad: ad,
                    onTap: () => onOpenListing(ad.id),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Android's stretch overscroll isolates a scrollable into its own layer,
    // which makes any backdrop-sampling lens inside it render black at the
    // scroll edges — same fix `agents_directory_screen.dart` applies.
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          // Clears the floating glass tab bar (`extendBody: true`).
          MediaQuery.of(context).padding.bottom + 100,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 13,
          crossAxisSpacing: 13,
          childAspectRatio: 0.66,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return _Grid(
      children: List.generate(
        4,
        (index) => ShimmerBox(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
    );
  }
}

/// Wraps a non-scrolling state in a scroll view so [RefreshIndicator]'s pull
/// gesture still works when the grid is empty or errored — same reasoning as
/// `agents_directory_screen.dart`'s identically-named private widget.
class _ScrollableState extends StatelessWidget {
  const _ScrollableState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 100,
      ),
      children: [child],
    );
  }
}
