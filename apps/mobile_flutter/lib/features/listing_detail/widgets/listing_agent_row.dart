/// The agent block (mockup `.agentrow`) — avatar, name, a stats line, and
/// a call button. SCREENS.md §3.7: "Agent block (tap → `agent-profile`):
/// avatar + `fullName`."
///
/// **This block fails on its own.** It watches [listingAgentProvider],
/// which resolves to `null` for a deleted agent, a coworker id the agents
/// endpoint refuses, or no network at all — never to an error (see
/// `listing_detail_repository.dart`'s contract). All three render the same
/// "Agent details unavailable" row rather than taking the listing down or
/// leaving a gap where a person should be. That asymmetry with the ad
/// fetch, which *is* fatal, is the whole reason the repository has two
/// methods.
///
/// **The call button dials via [dialOrCopyPhone]** — a real `tel:` intent.
/// When there's no dialer on the device (or the OS declines to launch it),
/// it falls back to the previous copy-and-toast behaviour, with the toast
/// saying so honestly rather than pretending the tap did nothing. Shared
/// with `profile-agent`'s phone row and `agent-profile`'s Call action —
/// three independent copies of this exact logic existed before the
/// cross-slice integration pass that promoted it to `shared/widgets/`.
///
/// **Two lines only: the name, and the agent's rating.** The second line
/// used to be the mockup's `.agentrow__r` — "Agent · 24 listings · 9
/// closed" — and is now a [RatingStars] row instead. Two independent
/// reasons, both about what a *buyer* can act on:
///
/// 1. `dealsClosedCount` is a sales-performance metric. It is the only
///    deal count anywhere in the buyer journey, and closing deals is a
///    fact about the agent's employer, not about whether this buyer should
///    call them.
/// 2. `adsCount` is an all-time `AD_CREATED` event tally (see
///    [AgentDetail.adsCount]), not a count of live listings — so a buyer
///    who read "24 listings" here and then tapped through to
///    `agent-profile`'s "Ads List" grid found a different, smaller number
///    with nothing to explain the gap.
///
/// The rating is the aggregate the buyer surfaces already agree on:
/// `agents-directory`'s card (SCREENS.md §3.9's "Review: {rating}/5") and
/// Home's Top Agents rail both render it, and [RatingStars] is the single
/// widget all three share so the `ratingAverage == null` → "No reviews
/// yet" rule (never a zero-star row — see its own doc comment) holds
/// identically everywhere. `ratingAverage` is passed straight through,
/// never `?? 0`.
///
/// **This is a deviation from the mockup**, which does draw the closed-
/// deals line; SCREENS.md §7 itself specifies only "avatar + `fullName`",
/// so nothing spec-quoted changed here — but three implementations render
/// this block, so it is raised as a spec question rather than treated as
/// settled. The agent's address still belongs to `agent-profile` alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/listing_detail_providers.dart';

class ListingAgentRow extends ConsumerWidget {
  const ListingAgentRow({super.key, required this.ad, required this.onOpen});

  final Ad ad;

  /// Called with the agent's id when the row is tapped — the screen owns
  /// the branch-relative `agent-profile` push, since the same widget is
  /// used from both the Home and Search branches.
  final void Function(String agentId) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    // An ad with no agentId has nobody to look up; skip the provider
    // entirely rather than watching a family keyed by the empty string.
    final agent = ad.agentId.isEmpty
        ? const AsyncValue<AgentDetail?>.data(null)
        : ref.watch(listingAgentProvider(ad.agentId));

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: agent.when(
        loading: () => const _AgentRowSkeleton(),
        // Unreachable by contract — fetchAgent never throws — but a screen
        // that assumed so and was wrong would crash rather than degrade, so
        // this branch renders the same unavailable state as a null.
        error: (_, _) => const _AgentUnavailable(),
        data: (agent) => agent == null
            ? const _AgentUnavailable()
            : _AgentRowContent(agent: agent, onOpen: () => onOpen(agent.id)),
      ),
    );
  }
}

class _AgentRowContent extends StatelessWidget {
  const _AgentRowContent({required this.agent, required this.onOpen});

  final AgentDetail agent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final phone = agent.phoneNumber;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Row(
        children: [
          AgentAvatar(
            avatarUrl: agent.avatar,
            fullName: agent.fullName,
            size: 42,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  agent.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 1),
                // `.agentrow__r`'s slot, now carrying the rating instead of
                // the ads/closed tally — see this file's doc comment. The
                // star row is one point smaller than the directory card's
                // default so it stays inside the 42px avatar's height.
                RatingStars(
                  key: const ValueKey('listingAgentRating'),
                  average: agent.ratingAverage,
                  count: agent.ratingCount,
                  starSize: 12,
                ),
                // `.agentrow` is name + one secondary line and nothing
                // else. The agent's address belongs to `agent-profile`,
                // which does specify it.
              ],
            ),
          ),
          if (phone != null && phone.trim().isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            _CallButton(agent: agent, phone: phone.trim()),
          ],
        ],
      ),
    );
  }
}

class _CallButton extends ConsumerWidget {
  const _CallButton({required this.agent, required this.phone});

  final AgentDetail agent;
  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(
        context,
      ).listingAgentCallSemanticsLabel(agent.fullName),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => dialOrCopyPhone(context, ref, phone),
        // `.agentrow .rnd{width:38px;height:38px;font-size:17px;
        // color:var(--ink);background:var(--sunk);
        // box-shadow:0 0 0 1px var(--line)}` — an ink glyph inside a
        // hairline-ringed sunk disc, not an accent one. The accent is
        // reserved for the surfaces whose CSS asks for it (e.g.
        // `.nrow .lrow__ic`); this is the same round action disc as
        // `.trow__act`, which `my_listing_row.dart` also paints in ink.
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: AppRadii.pill,
            border: Border.all(color: colors.line, width: 1),
          ),
          child: Icon(Icons.phone_rounded, size: 17, color: colors.ink),
        ),
      ),
    );
  }
}

class _AgentRowSkeleton extends StatelessWidget {
  const _AgentRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerBox(width: 42, height: 42, borderRadius: AppRadii.pill),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 120,
                height: 11,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: AppSpacing.sm),
              ShimmerBox(
                width: 170,
                height: 9,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentUnavailable extends StatelessWidget {
  const _AgentUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: AppRadii.pill,
          ),
          child: Icon(Icons.person_off_outlined, size: 19, color: colors.faint),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            AppLocalizations.of(context).listingAgentUnavailableLabel,
            style: type.rowTitle.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}
