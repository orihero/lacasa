/// One row of `agents-directory` (SCREENS.md §3.9) — avatar, name, phone,
/// email, address, a `"Review: {rating}/5"` star row, and an
/// "Ads: {adsCount}" count chip. Tapping opens `agent-profile`.
///
/// **Both `address` and the rating row are honest-absence, not
/// always-on.** `AgentSummary.address` is `null` for an agent who never set
/// one (see its own doc comment) and is simply omitted — no "—" filler,
/// matching this card's existing phone/email treatment. `ratingAverage`
/// `== null` (no reviews yet) renders `RatingStars`' "No reviews yet" text
/// rather than a zero-star row or being hidden outright — SCREENS.md's
/// star row is a trust signal, and silently hiding "nobody has reviewed
/// this agent" would itself read as a claim ("this row just doesn't apply
/// here") the app has no basis for. See `RatingStars`' own doc comment for
/// the full null-vs-zero reasoning this call site relies on.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
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
                  if (agent.address?.trim() case final address? when address.isNotEmpty)
                    _MetaLine(icon: Icons.place_outlined, text: address),
                  const SizedBox(height: AppSpacing.sm),
                  RatingStars(average: agent.ratingAverage, count: agent.ratingCount),
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
        AppLocalizations.of(context).agentsCardAdsCountLabel(count),
        style: type.micro.copyWith(color: colors.ink2),
      ),
    );
  }
}
