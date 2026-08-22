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
/// **The rating is a fourth `dt`/`dd` row, and it is deliberate.** §3.10
/// does not list it (only §3.9's directory card does), and it was removed
/// from this block once for exactly that reason — but that left the buyer
/// journey saying two different things about the same agent: the directory
/// card and `listing-detail`'s agent block both print the aggregate, and
/// tapping either of them *through* to the profile made it disappear. An
/// aggregate that vanishes at the moment the user acts on it reads as a
/// retraction. It is rendered by the shared [RatingStars] — same widget,
/// same copy ("Review: {rating}/5"), same `ratingAverage == null` → "No
/// reviews yet" rule (never a zero-star row, see that widget's own doc
/// comment) — so the three surfaces cannot drift. `ratingAverage` is
/// passed straight through, never `?? 0`.
///
/// The reviews themselves still live in `AgentReviewsSection` further down
/// the screen; this row is the summary, not a second copy of the list.
///
/// **Address used to render here too** and is still gone — §3.10 does not
/// list it either, and unlike the rating nothing else on the buyer's path
/// promises it.
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
                      label: AppLocalizations.of(
                        context,
                      ).agentsInfoFullNameLabel,
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
                    // Last, not first: the three §3.10 rows are the ones
                    // the spec quotes and they keep their order and their
                    // position exactly. See this file's doc comment for
                    // why the rating is here at all.
                    _InfoRow(
                      label: AppLocalizations.of(context).agentsInfoRatingLabel,
                      valueWidget: RatingStars(
                        key: const ValueKey('agentInfoRating'),
                        average: agent.ratingAverage,
                        count: agent.ratingCount,
                      ),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              // `.idcard__row{gap:14px}`.
              const SizedBox(width: 14),
              AgentAvatar(
                avatarUrl: agent.avatar,
                fullName: agent.fullName,
                // `.av--84`.
                size: 84,
              ),
            ],
          ),
          // `.btns{margin-top:14px;gap:10px}`.
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_rounded,
                  label: AppLocalizations.of(context).agentsInfoCallButtonLabel,
                  // `.btn--ink` — the primary of the pair.
                  primary: true,
                  // Disabled rather than hidden, so the row's shape is the
                  // same for every agent and "this one has no number" reads
                  // as a fact about them, not a layout variant.
                  onTap: hasPhone
                      ? () => dialOrCopyPhone(context, ref, phone)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: AppLocalizations.of(
                    context,
                  ).agentsInfoMessageButtonLabel,
                  onTap: () => showContactSheet(
                    context,
                    prefill: ContactPrefill.forAgent(agentName: agent.fullName),
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

/// One `.idcard__dl>div` — a hairline-separated `dt`/`dd` pair: a 10px
/// uppercase muted label over a 12.5/600 ink value, `7px 0` padding, with
/// the rule omitted on the last row.
///
/// The label arrives exactly as SCREENS.md §3.10 quotes it ("Full name:",
/// "E-mail:", "Phone:") and is uppercased — and its trailing colon dropped —
/// at *render* time only. The ARB strings stay verbatim so the three
/// implementations building against that spec still agree on the copy.
///
/// Exactly one of [value] / [valueWidget] is supplied. The plain-string
/// form is the `dd` this card is made of; [valueWidget] exists for the one
/// row whose value is not a string at all (the rating's star row), so that
/// row still gets the same label treatment, the same vertical rhythm and
/// the same hairline rule rather than being hand-rebuilt beside the list.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isLast = false,
  }) : assert(
         (value == null) != (valueWidget == null),
         'Supply exactly one of value / valueWidget.',
       );

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.line)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.replaceAll(':', '').toUpperCase(),
            style: type.caption.copyWith(
              color: colors.muted,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          if (valueWidget case final widget?)
            widget
          else
            Text(
              value!,
              overflow: TextOverflow.ellipsis,
              style: type.rowTitle.copyWith(color: colors.ink, fontSize: 12.5),
            ),
        ],
      ),
    );
  }
}

/// One half of the identity card's `.btns` pair — a 54px pill. [primary] is
/// `.btn--ink` (the filled dark Call button with its ink glow); the default
/// is `.btn--ghost glf`, a flat-glass button with ink-coloured content.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final bool primary;

  /// Null renders the button in its disabled look and swallows taps.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final enabled = onTap != null;
    final tint = enabled
        ? (primary ? colors.pillInk : colors.ink)
        : colors.faint;

    // `.btn{height:54px;border-radius:27px;gap:8px;font-size:13.5/600}`.
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: tint),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: type.cardTitle.copyWith(color: tint, letterSpacing: 0.1),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: primary
            ? Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: AppRadii.pill,
                  boxShadow: enabled ? AppShadows.selectedPillLarge : null,
                ),
                child: content,
              )
            : GlassSurface(
                variant: GlassVariant.flatForm,
                borderRadius: AppRadii.pill,
                height: 54,
                alignment: Alignment.center,
                child: content,
              ),
      ),
    );
  }
}
