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
/// **The call button copies the number instead of dialling.** Placing a
/// call needs `url_launcher` (a `tel:` intent), which this app does not
/// depend on; the same reasoning as the share button in
/// `listing_detail_nav.dart`. Copy-and-toast is honest and immediately
/// useful; a button that silently did nothing would not be.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
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
                Text(
                  _statsLine(agent),
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.muted),
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

  /// "Agent · 24 listings · 9 closed". `adsCount` is an all-time
  /// `AD_CREATED` tally, not a live count of current listings — see
  /// [AgentDetail.adsCount]. Labelled "listings" anyway because that is
  /// what SCREENS.md's own agent card calls it, and the distinction is not
  /// one a buyer can act on.
  static String _statsLine(AgentDetail agent) {
    return [
      'Agent',
      '${agent.adsCount} listing${agent.adsCount == 1 ? '' : 's'}',
      '${agent.dealsClosedCount} closed',
    ].join(' · ');
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.agent, required this.phone});

  final AgentDetail agent;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: 'Copy ${agent.fullName}\'s phone number',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _copy(context),
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

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Phone number copied: $phone')));
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
            'Agent details unavailable',
            style: type.rowTitle.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}
