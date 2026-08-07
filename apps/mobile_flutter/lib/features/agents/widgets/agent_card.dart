/// One row of `agents-directory` (SCREENS.md §3.9) — avatar, name, phone,
/// email, and an "Ads: {adsCount}" count chip. Tapping opens
/// `agent-profile`.
///
/// **Two fields the spec asks for are not rendered, because they do not
/// exist in the system**, and inventing them would be worse than their
/// absence:
///
/// - **`address`** — `User` (`apps/api/prisma/schema.prisma:120`) has no
///   address column, and `agentService.js#serializeAgent` hand-picks the
///   public field list, so `GET /agents` could not send one even if the
///   column existed. There is nothing to show.
/// - **"Review: {rating}/5"** — there is no review, rating, or feedback
///   table anywhere in the schema. A star row is a trust signal; rendering
///   a hardcoded or zero rating would be a *false* trust signal, which is
///   the one failure mode worth refusing outright.
///
/// Both are flagged in the mobile README's data-model gap list rather than
/// silently dropped. `adsCount` renders as a labelled chip in the space
/// they would have occupied.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class AgentCard extends StatelessWidget {
  const AgentCard({super.key, required this.agent, required this.onTap});

  final AgentSummary agent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final phone = agent.phoneNumber?.trim();

    return GestureDetector(
      key: ValueKey('agentCard-${agent.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentAvatar(
              avatarUrl: agent.avatar,
              fullName: agent.fullName,
              size: 52,
            ),
            const SizedBox(width: AppSpacing.base),
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
                  const SizedBox(height: AppSpacing.xs),
                  // Phone before email, matching §3.9's own field order.
                  // Either can be missing on a real row (`phoneNumber` is
                  // nullable in the schema; `email` is not, but an empty
                  // string survives `AgentSummary.fromJson`'s `?? ''`), so
                  // each line is conditional rather than assumed present.
                  if (phone != null && phone.isNotEmpty)
                    _MetaLine(icon: Icons.phone_outlined, text: phone),
                  if (agent.email.trim().isNotEmpty)
                    _MetaLine(
                      icon: Icons.mail_outline_rounded,
                      text: agent.email.trim(),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _AdsCountChip(count: agent.adsCount),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An icon + single line of secondary text. Ellipsized rather than wrapped:
/// a long email should not push the card's height around row to row, and
/// the full value is available one tap away on the profile.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: colors.faint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: type.bodySmall.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// SCREENS.md §3.9's **"Ads: {adsCount}"**, quoted verbatim — the label
/// text is fixed by the spec so three implementations agree on it, and the
/// count is not pluralized for the same reason.
class _AdsCountChip extends StatelessWidget {
  const _AdsCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        'Ads: $count',
        style: type.micro.copyWith(color: colors.ink2),
      ),
    );
  }
}
