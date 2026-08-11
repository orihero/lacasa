/// `agents-directory` (SCREENS.md §3.9) — the Agents tab's root page,
/// `RoutePaths.agents`. Header "Agents", then a vertical list of
/// [AgentCard]s; tapping one pushes `agent-profile` into this same branch.
///
/// **Router wiring**: takes no constructor arguments and reads no path
/// params — `app_router.dart`'s `/agents` branch root is
/// `const AgentsDirectoryScreen()`.
///
/// **Pull-to-refresh is here and not on Home**, which has none. Home's feed
/// is assembled from several independent providers with their own retry
/// affordances; this screen is a single list from a single fetch, which is
/// exactly the shape a [RefreshIndicator] models honestly — one gesture,
/// one thing reloaded.
///
/// **The empty state's copy is "No agents found."** — quoted from §3.9,
/// full stop included, the same way `list_states.dart` requires
/// "No listings found" to be quoted rather than paraphrased.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/agents_providers.dart';
import 'agent_card.dart';

class AgentsDirectoryScreen extends ConsumerWidget {
  const AgentsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final agents = ref.watch(agentsDirectoryProvider);

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                0,
              ),
              child: Text(
                AppLocalizations.of(context).agentsDirectoryScreenTitle,
                style: type.navTitle.copyWith(color: colors.ink),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(agentsDirectoryProvider.future),
                child: agents.when(
                  loading: () => const _AgentsSkeletonList(),
                  error: (error, stackTrace) => _ScrollableState(
                    child: FullWidthState(
                      icon: Icons.cloud_off_rounded,
                      message: AppLocalizations.of(
                        context,
                      ).agentsDirectoryLoadErrorMessage,
                      actionLabel: AppLocalizations.of(context).sharedRetryLabel,
                      onAction: () => ref.invalidate(agentsDirectoryProvider),
                    ),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return _ScrollableState(
                        child: FullWidthState(
                          icon: Icons.person_search_outlined,
                          message: AppLocalizations.of(
                            context,
                          ).agentsDirectoryEmptyMessage,
                        ),
                      );
                    }
                    return _AgentsList(agents: list);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentsList extends StatelessWidget {
  const _AgentsList({required this.agents});

  final List<AgentSummary> agents;

  @override
  Widget build(BuildContext context) {
    // Android's stretch overscroll isolates a scrollable into its own
    // layer, which makes any backdrop-sampling lens inside it render black
    // at the scroll edges — same fix, same reason, as `home_feed_screen`.
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          // Clears the floating glass tab bar (`extendBody: true`), so the
          // last card is never permanently covered by it.
          MediaQuery.of(context).padding.bottom + 100,
        ),
        itemCount: agents.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.base),
        itemBuilder: (context, index) {
          final agent = agents[index];
          return AgentCard(
            agent: agent,
            onTap: () => context.push('/agents/${agent.id}'),
          );
        },
      ),
    );
  }
}

class _AgentsSkeletonList extends StatelessWidget {
  const _AgentsSkeletonList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.section,
      ),
      itemCount: 6,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.base),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: 52,
              height: 52,
              borderRadius: AppRadii.pill,
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: 140,
                    height: 11,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ShimmerBox(
                    width: 110,
                    height: 9,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ShimmerBox(
                    width: 160,
                    height: 9,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  const ShimmerBox(
                    width: 62,
                    height: 22,
                    borderRadius: AppRadii.pill,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a non-scrolling state in a scroll view so [RefreshIndicator]'s
/// pull gesture still works when the list is empty or errored — the two
/// moments a user is *most* likely to want to retry by pulling.
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
