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
              // `.nav .rnd.gl` — a 38px round glass chip inside the 44px
              // tap target, not a bare glyph on the screen background.
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: GlassSurface(
                    variant: GlassVariant.onSurface,
                    borderRadius: AppRadii.pill,
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    // The lens's default band is tuned for a card and would
                    // swallow a 38px disc — the same override every other
                    // hand-built copy of this control uses.
                    distortionWidth: 8,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: colors.ink,
                    ),
                  ),
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

/// The first-load placeholder. It stands in for the *whole* body, not just
/// the identity card: the mockup's profile is an idcard, a `.sec` "Ads List"
/// heading and a 2-column `.grid`, so a one-card skeleton would promise a
/// screen that is about to grow by several hundred pixels. The grid half
/// repeats `AgentAdsGrid`'s own loading branch (same 2 columns, same 13px
/// gaps, same 0.66 aspect ratio) because that widget isn't mounted until
/// [agentDetailProvider] resolves.
///
/// Scrolls for the same reason [_ProfileBody] does — on a short viewport the
/// placeholder is now tall enough to need it.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

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
                  const SizedBox(width: 14),
                  // Matches `AgentInfoBlock`'s `.av--84` avatar, so the
                  // placeholder doesn't jump on load.
                  const ShimmerBox(
                    width: 84,
                    height: 84,
                    borderRadius: AppRadii.pill,
                  ),
                ],
              ),
            ),
            // The `.sec` row `AgentAdsGrid._Shell` draws once it mounts: the
            // "Ads List" heading, with no trailing count — a number here
            // would be a claim the placeholder can't back up either.
            const SizedBox(height: AppSpacing.section),
            ShimmerBox(
              width: 90,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.base),
            GridView.count(
              crossAxisCount: 2,
              // Matches [AgentAdsGrid]'s own zero padding — without it this
              // skeleton inherits the ambient vertical insets and settles at a
              // different height than the grid it stands in for.
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              childAspectRatio: 0.66,
              children: List.generate(
                2,
                (index) => AspectRatio(
                  aspectRatio: 0.66,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
