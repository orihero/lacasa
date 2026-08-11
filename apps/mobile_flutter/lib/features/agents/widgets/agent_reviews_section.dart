/// `agent-profile`'s reviews section — the paged list backing SCREENS.md
/// §3.9's `"Review: {rating}/5"` row, plus the leave/edit/delete-a-review
/// surface this run adds beyond the spec (see `agent_review_sheet.dart`'s
/// doc comment). Not itself in SCREENS.md; placed after the "Ads List"
/// grid so the spec-defined content stays first.
///
/// **Three call-to-action states**, gated in this order:
/// 1. Signed out → this app's existing inline sign-in prompt (same copy
///    register `saved_listings_screen.dart`'s `_SignedOutState` and
///    `add_coworker_screen.dart`'s `_BlockedState` already use elsewhere),
///    not a broken form. Tapping "Sign In" pushes `login`.
/// 2. Signed in as the agent whose own profile this is → an explanatory
///    line, no button. Pre-empts the server's own `403 forbidden` self-review
///    check for the common case; that check still fires (and is still
///    surfaced meaningfully — see `agent_review_sheet.dart`'s `_messageFor`)
///    for the rarer one this client can't detect client-side (posting from
///    a stale reviews page, or a race with another device).
/// 3. Any other signed-in caller → "Leave a review" (nothing of theirs is
///    in the loaded pages) or "Edit your review" (something is).
///
/// **"Edit your review" is best-effort, not authoritative.** There is no
/// `GET /agents/:id/reviews/me` endpoint — this section can only look for
/// the signed-in caller's own review inside whatever pages
/// [agentReviewsProvider] has actually loaded so far. A caller who reviewed
/// long enough ago that their row has scrolled past the loaded pages will
/// see "Leave a review" instead of "Edit your review" until they page far
/// enough to find it — but the server's own upsert-on-`(agentId, authorId)`
/// means submitting through "Leave a review" in that case still edits their
/// existing row rather than stacking a second one, so the worst outcome is
/// a mislabeled button, never a duplicate review. Flagged rather than
/// worked around: closing it for real needs a server endpoint this task
/// does not add.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/agents_providers.dart';
import 'agent_review_sheet.dart';

class AgentReviewsSection extends ConsumerWidget {
  const AgentReviewsSection({super.key, required this.agent});

  final AgentDetail agent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final session = ref.watch(authSessionProvider);
    final reviewsAsync = ref.watch(agentReviewsProvider(agent.id));

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).reviewsSectionHeading(agent.ratingCount),
            style: type.panelHeading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.base),
          _CallToAction(agent: agent, session: session, reviewsAsync: reviewsAsync),
          const SizedBox(height: AppSpacing.base),
          reviewsAsync.when(
            loading: () => const _ReviewsSkeleton(),
            error: (error, stackTrace) => LayoutBuilder(
              builder: (context, constraints) => RailRetryCard(
                width: constraints.maxWidth,
                message: AppLocalizations.of(
                  context,
                ).reviewsSectionLoadErrorMessage,
                onRetry: () => ref.invalidate(agentReviewsProvider(agent.id)),
              ),
            ),
            data: (state) {
              if (state.reviews.isEmpty) {
                return FullWidthState(
                  icon: Icons.rate_review_outlined,
                  message: AppLocalizations.of(context).reviewsSectionEmptyMessage,
                );
              }
              return Column(
                children: [
                  for (final review in state.reviews) _ReviewTile(review: review),
                  if (state.hasMore) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _LoadMoreButton(
                      loading: state.isLoadingMore,
                      onTap: () => ref.read(agentReviewsProvider(agent.id).notifier).loadMore(),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CallToAction extends ConsumerWidget {
  const _CallToAction({
    required this.agent,
    required this.session,
    required this.reviewsAsync,
  });

  final AgentDetail agent;
  final AuthSessionState session;
  final AsyncValue<AgentReviewsPageState> reviewsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final l10n = AppLocalizations.of(context);

    if (!session.isSignedIn) {
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.reviewsSectionSignInPromptMessage,
              style: type.bodySmall.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          _Pill(
            label: l10n.reviewsSectionSignInButtonLabel,
            onTap: () => context.push(RoutePaths.login),
          ),
        ],
      );
    }

    final user = session.user!;
    if (user.id == agent.id) {
      return Text(
        l10n.reviewsSectionSelfProfileMessage,
        style: type.bodySmall.copyWith(color: colors.muted),
      );
    }

    // Best-effort "is one of mine already loaded" — see this file's doc
    // comment for why this can under-detect but never over-claims.
    final myReview = reviewsAsync.value?.reviews
        .where((r) => r.author.id == user.id)
        .firstOrNull;

    return Align(
      alignment: Alignment.centerLeft,
      child: _Pill(
        label: myReview == null
            ? l10n.reviewsSectionLeaveButtonLabel
            : l10n.reviewsSectionEditButtonLabel,
        onTap: () async {
          final changed = await showAgentReviewSheet(
            context,
            agentId: agent.id,
            agentName: agent.fullName,
            existingReview: myReview,
          );
          if (changed == true) {
            ref.invalidate(agentReviewsProvider(agent.id));
            ref.invalidate(agentDetailProvider(agent.id));
          }
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: colors.pill, borderRadius: AppRadii.pill),
        child: Text(label, style: type.label.copyWith(color: colors.pillInk)),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final AgentReview review;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final comment = review.comment?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentAvatar(avatarUrl: review.author.avatar, fullName: review.author.fullName, size: 36),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.author.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: type.rowTitle.copyWith(color: colors.ink),
                      ),
                    ),
                    Text(
                      Formatters.date(review.createdAt),
                      style: type.micro.copyWith(color: colors.faint),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                RatingStars(
                  average: review.rating.toDouble(),
                  count: 0,
                  starSize: 12,
                  showLabel: false,
                ),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(comment, style: type.body.copyWith(color: colors.ink2)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Center(
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                AppLocalizations.of(context).reviewsSectionLoadMoreLabel,
                style: type.label.copyWith(color: AppAccent.color),
              ),
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 36, height: 36, borderRadius: AppRadii.pill),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 120, height: 10, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 200, height: 9, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
