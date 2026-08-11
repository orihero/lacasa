/// `agent-profile` (SCREENS.md §3.10) — header "Agent Information", the
/// labelled identity block, and the agent's "Ads List" grid.
///
/// **Router wiring**: takes the agent id as a constructor argument and a
/// [branchPrefix], for the same reason `listing_detail_screen.dart` does.
/// §1 buckets `agent-profile` under "Pushed (full-screen, back-stack)", so
/// it keeps the tab bar and lives in the back stack of whichever tab opened
/// it — which means it is declared once per branch (`/agents/:id`,
/// `/home/agent/:id`, `/search/agent/:id`) rather than once at top level,
/// and the listing pushes it emits must resolve back into that same branch.
///
/// **Not-found is its own state, not a generic error.** An agent id that
/// 404s (a deleted account, or — just as likely here — a *coworker* id,
/// which `GET /agents/:id` refuses by design) is a permanent answer: a
/// Retry button would invite the user to keep asking a question that will
/// never change. A transport failure gets Retry; a 404 gets "Go back".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/agents_providers.dart';
import 'agent_ads_grid.dart';
import 'agent_info_block.dart';
import 'agent_reviews_section.dart';

class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({
    super.key,
    required this.agentId,
    this.branchPrefix = RoutePaths.agents,
  });

  final String agentId;

  /// The tab branch this screen was pushed into (`/agents`, `/home` or
  /// `/search`) — used to keep the listings it opens inside that same back
  /// stack.
  final String branchPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final agent = ref.watch(agentDetailProvider(agentId));

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NavRow(onBack: () => _pop(context)),
            Expanded(
              child: agent.when(
                loading: () => const _ProfileSkeleton(),
                error: (error, stackTrace) =>
                    _ErrorState(error: error, agentId: agentId),
                data: (agent) => _ProfileBody(
                  agent: agent,
                  onOpenListing: (adId) =>
                      context.push('$branchPrefix/listing/$adId'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    // Same reasoning as `listing_detail_nav.dart`'s: a deep link straight
    // into a profile has nothing to pop, and that is not an error — "up" is
    // just the directory rather than "back".
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.agents);
    }
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: AppLocalizations.of(context).agentsProfileNavBackLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              AppLocalizations.of(context).agentsProfileScreenTitle,
              overflow: TextOverflow.ellipsis,
              style: type.navTitle.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.agent, required this.onOpenListing});

  final AgentDetail agent;
  final void Function(String adId) onOpenListing;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          0,
          AppSpacing.screenGutter,
          // Clears the floating glass tab bar (`extendBody: true`).
          MediaQuery.of(context).padding.bottom + 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentInfoBlock(agent: agent),
            AgentAdsGrid(agentId: agent.id, onOpenListing: onOpenListing),
            AgentReviewsSection(agent: agent),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error, required this.agentId});

  final Object error;
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notFound =
        error is ApiErrorException &&
        (error as ApiErrorException).code == ApiErrorCode.notFound;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: notFound
          ? FullWidthState(
              icon: Icons.person_off_outlined,
              message: AppLocalizations.of(
                context,
              ).agentsProfileNotFoundMessage,
              actionLabel: AppLocalizations.of(
                context,
              ).agentsProfileGoBackLabel,
              onAction: () => context.canPop()
                  ? context.pop()
                  : context.go(RoutePaths.agents),
            )
          : FullWidthState(
              icon: Icons.cloud_off_rounded,
              message: AppLocalizations.of(
                context,
              ).agentsProfileLoadErrorMessage,
              actionLabel: AppLocalizations.of(context).sharedRetryLabel,
              onAction: () => ref.invalidate(agentDetailProvider(agentId)),
            ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppRadii.cardXl),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 180,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      ShimmerBox(
                        width: 200,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      ShimmerBox(
                        width: 150,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                const ShimmerBox(
                  width: 64,
                  height: 64,
                  borderRadius: AppRadii.pill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
