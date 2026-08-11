/// `agent-profile`'s identity block (SCREENS.md §3.10) — the labelled
/// "Full name / E-mail / Phone" rows with the avatar at top-right, plus the
/// call and message actions.
///
/// **The three labels are quoted from §3.10 exactly**, including its
/// inconsistent casing: **"Full name:"**, **"E-mail:"**, **"Phone:"** — not
/// normalized to "Email"/"Phone number". Three implementations are building
/// against this spec and the point of quoting is that they agree; silently
/// tidying the copy in one of them defeats it.
///
/// **Address and the `"Review: {rating}/5"` star row are this task's
/// addition** — §3.10's own text doesn't list them (only §3.9's directory
/// card does), but a profile that carries less identity than the card that
/// opened it would be a strange asymmetry, so both render here too, in the
/// same honest-absence shape `agent_card.dart` uses: address only when set,
/// the rating row always present and reading `RatingStars`' "No reviews
/// yet" text rather than a zero-star row when [AgentDetail.ratingAverage]
/// is `null`.
///
/// **The call button dials via [dialOrCopyPhone]** — §3.10's "call icon →
/// `tel:` link", now real. When there's no dialer on the device (or the OS
/// declines to launch it), it falls back to copying the number instead,
/// with the toast saying so honestly rather than pretending the tap did
/// nothing. Shared with `listing-detail`'s agent row and `profile-agent`'s
/// phone row — three independent copies of this exact logic existed before
/// the cross-slice integration pass that promoted it to `shared/widgets/`.
///
/// The message button *is* the real thing — it opens `contact-sheet`
/// pre-filled with the agent's name, which is what §3.10 asks for.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../contact/contact.dart';

class AgentInfoBlock extends ConsumerWidget {
  const AgentInfoBlock({super.key, required this.agent});

  final AgentDetail agent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final phone = agent.phoneNumber?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.cardXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InfoRow(
                      label: AppLocalizations.of(context).agentsInfoFullNameLabel,
                      value: agent.fullName,
                    ),
                    _InfoRow(
                      label: AppLocalizations.of(context).agentsInfoEmailLabel,
                      value: agent.email,
                    ),
                    // "—" rather than a hidden row: on a screen whose whole
                    // job is contact details, an absent phone is itself the
                    // answer to the question the user came with. That is the
                    // opposite call from `agent_card.dart`'s list row, where
                    // a missing line just keeps the card tidy. The dash
                    // itself is punctuation, not a word, so it isn't routed
                    // through AppLocalizations.
                    _InfoRow(
                      label: AppLocalizations.of(context).agentsInfoPhoneLabel,
                      value: hasPhone ? phone : '—',
                    ),
                    if (agent.address?.trim() case final address? when address.isNotEmpty)
                      _InfoRow(
                        label: AppLocalizations.of(context).agentsInfoAddressLabel,
                        value: address,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              AgentAvatar(
                avatarUrl: agent.avatar,
                fullName: agent.fullName,
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RatingStars(average: agent.ratingAverage, count: agent.ratingCount),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_rounded,
                  label: AppLocalizations.of(context).agentsInfoCallButtonLabel,
                  // Disabled rather than hidden, so the row's shape is the
                  // same for every agent and "this one has no number" reads
                  // as a fact about them, not a layout variant.
                  onTap: hasPhone
                      ? () => dialOrCopyPhone(context, ref, phone)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: AppLocalizations.of(context).agentsInfoMessageButtonLabel,
                  onTap: () => showContactSheet(
                    context,
                    prefill: ContactPrefill.forAgent(
                      agentName: agent.fullName,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: RichText(
        text: TextSpan(
          style: type.body.copyWith(color: colors.ink),
          children: [
            TextSpan(
              text: '$label ',
              style: type.body.copyWith(color: colors.muted),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Null renders the button in its disabled look and swallows taps.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final enabled = onTap != null;
    final tint = enabled ? AppAccent.color : colors.faint;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: AppRadii.pill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: type.label.copyWith(color: tint)),
            ],
          ),
        ),
      ),
    );
  }
}
