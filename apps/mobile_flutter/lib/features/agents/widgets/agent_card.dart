/// One row of `agents-directory` (SCREENS.md §3.9) — the mockup's `.acard`:
/// avatar, then a body of name → a single-star "Review: {rating}/5 ·
/// Ads: {n}" line → phone, email and address lines, with a vertically
/// centred chevron. Tapping opens `agent-profile`.
///
/// **Both `address` and the rating are honest-absence, not always-on.**
/// `AgentSummary.address` is `null` for an agent who never set one (see its
/// own doc comment) and is simply omitted — no "—" filler, matching this
/// card's phone/email treatment. `ratingAverage == null` (no reviews yet)
/// drops the rating half of the `.acard__r` line, leaving the ads count, so
/// nothing on the card ever claims a zero rating — see [_RatingAdsLine] and
/// `RatingStars`' own doc comment for the null-vs-zero rule behind that.
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
          // `.acard{border-radius:22px}`.
          borderRadius: BorderRadius.circular(AppRadii.cardLg),
        ),
        // `.acard{align-items:flex-start}` with a per-card
        // `.acard .lrow__go{align-self:center}` override on the chevron —
        // i.e. two different alignments in one row, which needs the row's
        // own height resolved first. Hence `IntrinsicHeight` + `stretch`
        // plus an [Align] per child: a `CrossAxisAlignment.start` row never
        // stretches a child, so nothing inside it can centre itself.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: AgentAvatar(
                  avatarUrl: agent.avatar,
                  fullName: agent.fullName,
                  size: 52,
                ),
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
                      style: type.cardTitle.copyWith(color: colors.ink),
                    ),
                    // `.acard__r` sits directly under the name, above the
                    // contact lines.
                    _RatingAdsLine(
                      average: agent.ratingAverage,
                      count: agent.ratingCount,
                      adsCount: agent.adsCount,
                    ),
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
                    if (agent.address?.trim() case final address?
                        when address.isNotEmpty)
                      _MetaLine(icon: Icons.place_outlined, text: address),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.faint,
                ),
              ),
            ],
          ),
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

    // `.acard__l{margin-top:4px;gap:5px;font-size:10.5px;color:var(--muted)}`
    // with a 12px `--faint` glyph.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 12, color: colors.faint),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: type.specMeta.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.acard__r` — one 12px amber star and one combined string,
/// "Review: {rating}/5 · Ads: {n}" (10.5/600, `--ink-2`). Replaces the
/// five-icon [RatingStars] row plus a separate "Ads:" pill this card used
/// to stack below its contact lines; the mockup's card carries neither.
///
/// The ads half is SCREENS.md §3.9's **"Ads: {adsCount}"**, quoted verbatim
/// (unpluralized, per the spec). When the agent has no reviews yet the
/// rating half — and the star with it — is omitted rather than printed as
/// a zero: `null` and `0.0` are different facts (see `RatingStars`' doc
/// comment), and a lit star over "0/5" would be the false trust signal that
/// rule exists to prevent.
class _RatingAdsLine extends StatelessWidget {
  const _RatingAdsLine({
    required this.average,
    required this.count,
    required this.adsCount,
  });

  final double? average;
  final int count;
  final int adsCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);
    final rating = average;
    final adsLabel = l10n.agentsCardAdsCountLabel(adsCount);
    final text = rating == null
        ? adsLabel
        : '${l10n.sharedRatingLabel(rating.toStringAsFixed(1))} · $adsLabel';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          if (rating != null) ...[
            const Icon(
              Icons.star_rounded,
              size: 12,
              color: AppStatusColors.ratingStar,
            ),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: type.specMeta.copyWith(
                color: colors.ink2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
