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
/// **Address and the rating row, added this task**, read straight off the
/// same [AgentDetail] this block already fetches — `GET /agents/:id` (and
/// its fixture stand-in) now carries `address`/`ratingAverage`/
/// `ratingCount` alongside the fields this block already used. Address
/// only appears when set (same honest-absence rule `agent_card.dart` and
/// `agent_info_block.dart` both follow — no "—" filler in a block this
/// compact); the rating row always renders, via `RatingStars`, whose own
/// doc comment covers the null-average-means-"No reviews yet" rule this
/// call site relies on.
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
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n.listingAgentStatsLine(
                    agent.adsCount,
                    agent.dealsClosedCount,
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
                if (agent.address?.trim() case final address? when address.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    address,
                    overflow: TextOverflow.ellipsis,
                    style: type.bodySmall.copyWith(color: colors.muted),
                  ),
                ],
                const SizedBox(height: 2),
                RatingStars(
                  average: agent.ratingAverage,
                  count: agent.ratingCount,
                  starSize: 11,
                ),
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

  // "Agent · 24 listings · 9 closed" — see AppLocalizations.
  // listingAgentStatsLine's ARB description for the full reasoning.
  // `adsCount` is an all-time `AD_CREATED` tally, not a live count of
  // current listings — see [AgentDetail.adsCount]. Labelled "listings"
  // anyway because that is what SCREENS.md's own agent card calls it, and
  // the distinction is not one a buyer can act on.
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
      label: AppLocalizations.of(context).listingAgentCallSemanticsLabel(
        agent.fullName,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => dialOrCopyPhone(context, ref, phone),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: AppRadii.pill,
          ),
          child: Icon(Icons.phone_rounded, size: 17, color: AppAccent.color),
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
        const ShimmerBox(
          width: 42,
          height: 42,
          borderRadius: AppRadii.pill,
        ),
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
          child: Icon(
            Icons.person_off_outlined,
            size: 19,
            color: colors.faint,
          ),
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
