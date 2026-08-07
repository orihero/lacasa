/// `agent-profile`'s "Ads List" section (SCREENS.md §3.10) — a 2-column
/// grid of this agent's active listings, bound to [agentAdsProvider].
///
/// **This section degrades on its own.** It is the whole reason
/// `agents_repository.dart` splits the profile into two fetches: a failed
/// ads load renders a scoped [RailRetryCard] here, leaving the identity
/// block above it — the name, email and phone number the user actually came
/// for — untouched. Blanking a person's contact details because a grid
/// failed would be the wrong trade every time.
///
/// **The count in the heading is the grid's, not [AgentDetail.adsCount].**
/// Those two legitimately disagree: `adsCount` is an all-time `AD_CREATED`
/// event tally that never decreases (see the model's own doc comment),
/// while this grid shows only what `GET /ads?agentId=` returns, which the
/// server scopes to `stage: "ACTIVE"`. Showing "Ads List (24)" over 3 cards
/// would read as a loading bug. The heading counts what is on screen; the
/// all-time figure stays on the directory card where it is labelled "Ads:".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/agents_providers.dart';

class AgentAdsGrid extends ConsumerWidget {
  const AgentAdsGrid({
    super.key,
    required this.agentId,
    required this.onOpenListing,
  });

  final String agentId;

  /// Called with the tapped ad's id. The screen owns the branch-relative
  /// push target, since this widget is reachable from three branches.
  final void Function(String adId) onOpenListing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(agentAdsProvider(agentId));

    return ads.when(
      loading: () => _Shell(
        child: _grid(
          List.generate(
            2,
            (index) => AspectRatio(
              aspectRatio: 0.66,
              child: ShimmerBox(
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => _Shell(
        child: LayoutBuilder(
          builder: (context, constraints) => RailRetryCard(
            width: constraints.maxWidth,
            message: "Couldn't load this agent's listings",
            onRetry: () => ref.invalidate(agentAdsProvider(agentId)),
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          // §3.10's own empty copy, and the same string `list_states.dart`
          // pins app-wide — never the web app's misspelled "Not fount post".
          return const _Shell(
            child: FullWidthState(
              icon: Icons.home_work_outlined,
              message: 'No listings found.',
            ),
          );
        }

        return _Shell(
          count: list.length,
          child: _grid(
            list
                .map(
                  (ad) => CompactListingCard(
                    ad: ad,
                    onTap: () => onOpenListing(ad.id),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 13,
      crossAxisSpacing: 13,
      childAspectRatio: 0.66,
      children: children,
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.count});

  final Widget child;

  /// Rendered as "Ads List (n)" when known. Omitted while loading and on
  /// error, where any number would be a claim the widget can't back up.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count == null ? 'Ads List' : 'Ads List ($count)',
            style: type.panelHeading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.base),
          child,
        ],
      ),
    );
  }
}
