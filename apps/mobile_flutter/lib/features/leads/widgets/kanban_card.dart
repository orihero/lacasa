/// One Kanban card (SCREENS.md §31) — `fullName`, bold phone, `comment`,
/// a conditional red pill (callback date/time for `need_to_call_back`, or
/// the conversation note for `rejected`/`accepted`), and a footer pairing
/// the created-at timestamp with — when [Lead.coworkerId] is non-empty — the
/// owning coworker's avatar/name.
///
/// **`WORK_TAB_CONTRACT.md` ruling 7.8 is now CLOSED, not the "nothing real
/// to bind" refusal this file used to carry.** That refusal was wrong on its
/// own terms: `Lead.coworkerId` is a real, populated field (set from the
/// acting user on create when they're a COWORKER), and `GET /coworkers`
/// resolves it for **either** role — an AGENT sees their team, a COWORKER
/// sees their siblings — via [coworkersListProvider], the same plain,
/// already-cached (non-`autoDispose`) provider `coworkers-list` itself
/// reads, so watching it here triggers no fetch of its own. And since leads
/// are agent-scoped rather than coworker-scoped
/// (`leadService.js#listLeads`), a coworker's board shows the *whole team's*
/// cards — resolving the id is the only place on this screen that tells
/// them who owns one.
///
/// A solo agent's leads (and, symmetrically, a lone coworker's) always carry
/// an empty `coworkerId` — the coworkers feature is hidden for that session
/// anyway — so the slot is simply omitted rather than looked up against
/// nothing. **While the roster is loading or has failed to load, the slot
/// renders nothing at all** (the footer degrades to just its created-at
/// half): never a placeholder identity, and never a spinner shoehorned into
/// this footer — the honesty rule this build runs on forbids fabricating a
/// value, and "still resolving" is not licence to fake one meanwhile.
///
/// Tap → `lead-detail`. Long-press → the "Move to…" action sheet
/// (`leads_kanban_screen.dart` owns that flow; this widget only reports the
/// gesture). While a move is in flight for this card
/// ([KanbanMoveState.isPending]), a spinner overlays just this card, never
/// the whole board (SCREENS.md §5's Kanban-move bullet). A failed move
/// leaves a "Couldn't move · Retry" row on the card, which re-runs the same
/// move into [failedDestination] — see `kanban_move_providers.dart`'s doc
/// comment for why that row is a deliberate, flagged extension of
/// `apps/console`'s non-actionable note (ruling 7.5).
///
/// **The bold phone line is its own tap target, dialling through
/// [dialOrCopyPhone].** Every column on this board exists to schedule a
/// conversation — "Need To Call Back" is a whole column named after one —
/// so a board that renders the number as inert text is a CRM that cannot
/// place the call it is asking for. Same affordance and same honest
/// copy-to-clipboard fallback as `listing-detail`, `agent-profile` and
/// `profile-agent`. The card's own tap (→ `lead-detail`) still owns every
/// other pixel of the card: the inner detector claims only the phone's own
/// line, and a long-press anywhere — the phone included — still wins the
/// gesture arena for the "Move to…" sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../coworkers/state/coworkers_providers.dart';
import 'lead_form_controls.dart';

class KanbanCard extends ConsumerWidget {
  const KanbanCard({
    super.key,
    required this.lead,
    required this.pending,
    required this.failedDestination,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
  });

  final Lead lead;
  final bool pending;

  /// The column this card's last move attempt failed to reach, or `null`
  /// when nothing failed — see [KanbanMoveState.failedDestination]. Drives
  /// both the failure row's wording and what [onRetry] re-attempts.
  final LeadStatus? failedDestination;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Re-runs the failed move into [failedDestination]. Only ever reachable
  /// while that is non-null.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final comment = lead.comment?.trim();
    final note = lead.conversationComment?.trim();
    final showCallbackPill =
        lead.status == LeadStatus.needToCallBack && lead.callbackDate != null;
    final showNotePill =
        (lead.status == LeadStatus.rejected ||
            lead.status == LeadStatus.accepted) &&
        note != null &&
        note.isNotEmpty;

    return Padding(
      // `.kb__cards{gap:9px}`.
      padding: const EdgeInsets.only(bottom: 9),
      child: Stack(
        children: [
          GestureDetector(
            key: ValueKey('kanbanCard-${lead.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: pending ? null : onTap,
            onLongPress: pending ? null : onLongPress,
            child: GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              // `.kcard{padding:13px 14px}`.
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                  if (lead.phone case final phone? when phone.isNotEmpty) ...[
                    _PhoneLine(leadId: lead.id, phone: phone, pending: pending),
                  ],
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      comment,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      // `.kcard__c{font-size:11px;line-height:1.5;
                      // color:var(--muted)}`.
                      style: type.bodySmall.copyWith(
                        color: colors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  // `.kcard__flag{margin-top:9px}`.
                  if (showCallbackPill) ...[
                    const SizedBox(height: 9),
                    _RedPill(
                      icon: Icons.schedule,
                      // `<span class="kcard__flag">…Call back {when}</span>`
                      // — the words carry the meaning; a bare timestamp on
                      // a red pill says only "something is due".
                      //
                      // `.toLocal()` is load-bearing, not defensive:
                      // `Lead.callbackDate` is decoded by `DateTime.tryParse`
                      // from a `Z`-suffixed ISO string, so it carries the UTC
                      // flag and `Formatters.date` would read *UTC* calendar
                      // and clock fields off it. A 09:00 Tashkent (UTC+5)
                      // call-back rendered as "04:00", and anything before
                      // 05:00 local rendered on the previous day — on the one
                      // pill in this app whose entire job is telling an agent
                      // when to pick up the phone. Same conversion, same
                      // reason, as `dashboard_providers.dart`'s
                      // `isWithinTimeRange`.
                      text: l10n.leadsCallBackFlagLabel(
                        Formatters.date(lead.callbackDate!.toLocal()),
                      ),
                    ),
                  ] else if (showNotePill) ...[
                    const SizedBox(height: 9),
                    _RedPill(
                      icon: Icons.chat_bubble_outline_rounded,
                      text: note,
                    ),
                  ],
                  // `.kcard__f{margin-top:11px;padding-top:10px;
                  // border-top:1px solid var(--line)}`.
                  const SizedBox(height: 11),
                  Container(height: 1, color: colors.line),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          // `Lead.createdAt` comes through
                          // `dateTimeFromWireTimestamp`, which builds its
                          // `DateTime` with `isUtc: true` — same UTC-fields
                          // trap as the call-back pill above, so it takes the
                          // same conversion.
                          Formatters.date(lead.createdAt.toLocal()),
                          overflow: TextOverflow.ellipsis,
                          style: type.micro.copyWith(color: colors.faint),
                        ),
                      ),
                      // Omitted outright for an empty `coworkerId` (a solo
                      // agent's — and a lone coworker's — leads always are)
                      // rather than mounting a lookup against nothing.
                      if (lead.coworkerId.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: _CoworkerFooter(coworkerId: lead.coworkerId),
                        ),
                      ],
                    ],
                  ),
                  if (failedDestination case final destination?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _MoveFailedRow(
                      key: ValueKey('kanbanCardRetry-${lead.id}'),
                      destination: destination,
                      onRetry: onRetry,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (pending)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.screen.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.ink2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The card's bold phone line — its own tap target, dialling through
/// [dialOrCopyPhone] (see [KanbanCard]'s doc comment for why a Kanban card
/// must be able to place the call it is asking for).
///
/// `.kcard__p{margin-top:3px;font-size:12px;font-weight:600;
/// color:var(--ink-2)}` — a step lighter than the name, so the
/// name > phone > comment hierarchy actually reads. The mockup's own 3px top
/// margin is dropped: [TapTarget]'s shrink-wrapping centre already
/// contributes more than that above the glyph.
///
/// `minSize` is below [TapTarget.minimumSize] deliberately, and this is the
/// "say why" that widget's doc comment asks for: a Kanban card is a dense
/// 4-line stack whose whole job is fitting several to a screen, and a full
/// 48dp row for the phone would add ~33dp to every card on the board. 30dp
/// still clears the ~15dp of glyph the old inert `Text` occupied by a wide
/// margin, and the target is generous on the horizontal axis (name-length
/// wide).
///
/// **While [pending], this stops being a button in the semantics tree, not
/// just in behaviour.** A move in flight mutes the whole card — the outer
/// gestures go `null` and a 55%-alpha overlay covers it — so a node still
/// announcing "Call {phone}" as a button, with a tap action that runs a
/// deliberate no-op, is a control that lies to exactly the user who cannot
/// see the overlay. The number itself is still announced (going silent
/// would hide real content, and the card is only busy for a beat); it just
/// no longer advertises an action it will not perform. The [TapTarget]
/// stays mounted meanwhile so the card doesn't reflow underneath the
/// spinner.
class _PhoneLine extends ConsumerWidget {
  const _PhoneLine({
    required this.leadId,
    required this.phone,
    required this.pending,
  });

  final String leadId;
  final String phone;

  /// This card's move is in flight — [KanbanMoveState.isPending].
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final target = TapTarget(
      key: ValueKey('kanbanCardCall-$leadId'),
      minSize: 30,
      semanticsLabel: l10n.leadsCallSemanticsLabel(phone),
      // Muted alongside the card's own gestures while this card's move is in
      // flight, so the whole card reads as one busy unit rather than one
      // dead card with one live control on it. The overlay above it is a
      // `DecoratedBox`, which does not absorb hits, so the no-op is what
      // actually stops the dial.
      onTap: pending ? () {} : () => dialOrCopyPhone(context, ref, phone),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_rounded, size: 11, color: colors.ink2),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LaCasaTypography.tabular(
                type.bodySmall,
              ).copyWith(color: colors.ink2, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (!pending) return target;

    // `excludeSemantics` drops [TapTarget]'s own node — label, `button: true`
    // and tap action together — and replaces it with a plain, actionless
    // one carrying just the number.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: phone,
      child: target,
    );
  }
}

/// The footer's coworker half — only ever mounted (by [KanbanCard.build])
/// when [coworkerId] is non-empty. Watches [coworkersListProvider] itself,
/// rather than taking a resolved [Coworker] as a constructor argument, so
/// that a roster refresh (e.g. after `add-coworker`/`coworker-detail`
/// invalidates it) reaches every card on the board for free.
///
/// **Renders nothing — not a spinner, not a placeholder name — for every
/// state except a genuine match in a resolved list**: `loading`/`error`
/// collapse to [SizedBox.shrink], and so does `data` when the id simply
/// isn't in the (possibly stale, possibly not-yet-caught-up) roster. A
/// missing match is not proof the coworker was deleted — it could just as
/// well be a race with a not-yet-refreshed cache — so this stays silent
/// rather than asserting either "this lead has no owner" or a fabricated
/// one.
class _CoworkerFooter extends ConsumerWidget {
  const _CoworkerFooter({required this.coworkerId});

  final String coworkerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final coworkersAsync = ref.watch(coworkersListProvider);

    return coworkersAsync.when(
      data: (coworkers) {
        Coworker? match;
        for (final candidate in coworkers) {
          if (candidate.id == coworkerId) {
            match = candidate;
            break;
          }
        }
        if (match == null) return const SizedBox.shrink();

        final resolved = match;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AgentAvatar(
              avatarUrl: resolved.avatar,
              fullName: resolved.fullName,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                resolved.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.micro.copyWith(color: colors.faint),
              ),
            ),
          ],
        );
      },
      // Still resolving (or never kicked off yet) — degrade to just the
      // created-at half already on screen, never a spinner shoehorned into
      // this footer.
      loading: () => const SizedBox.shrink(),
      // A failed roster fetch is the same "nothing real to show" case as
      // loading — never fabricate a name to fill the gap.
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// The failed-move row — "Couldn't move" plus a **tappable** Retry that
/// re-runs the move into [destination].
///
/// The note this replaces was a bare `Text` reading "Couldn't move — try
/// again." with nothing to try again *with*: the only route back to that
/// move was long-press → "Move to…" → pick the column again, a sequence
/// nothing on the card names, and the board deliberately suppresses a toast
/// for this failure too (`leads_kanban_screen.dart#_attemptMove`), so the
/// card really was the whole of the user's recourse. Naming the destination
/// in the semantics label ("Retry moving to Accepted") is what makes the
/// row honest for a screen-reader user, who otherwise gets a Retry with no
/// object.
///
/// Kept as its own tap target *inside* the card's own [GestureDetector]:
/// the inner detector wins a tap over the outer one, so Retry never also
/// opens `lead-detail`, while a long-press anywhere on the card (this row
/// included) still resolves to the outer "Move to…" gesture.
class _MoveFailedRow extends StatelessWidget {
  const _MoveFailedRow({
    super.key,
    required this.destination,
    required this.onRetry,
  });

  final LeadStatus destination;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    // Below [TapTarget.minimumSize] for the same density reason the phone
    // line above is, and with the same trade accepted: 32dp of full-card-width
    // strip is far more than the ~13dp of caption glyph the old, entirely
    // untappable note occupied.
    return TapTarget(
      minSize: 32,
      semanticsLabel: l10n.leadsCardMoveRetrySemanticsLabel(
        leadStatusLabel(l10n, destination),
      ),
      onTap: onRetry,
      child: Row(
        children: [
          Flexible(
            child: Text(
              l10n.leadsCardMoveFailedLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.caption.copyWith(color: AppStatusColors.errorText),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.sharedRetryLabel,
            style: type.caption.copyWith(
              color: AppStatusColors.errorText,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppStatusColors.errorText,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.kcard__flag` — a full-width red block with a leading glyph, not a
/// shrink-wrapped chip: the note it carries (a real `conversationComment`)
/// routinely runs to two lines in the mockup, so it wraps rather than
/// truncating.
class _RedPill extends StatelessWidget {
  const _RedPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppStatusColors.errorBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: AppStatusColors.errorText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: type.micro.copyWith(
                color: AppStatusColors.errorText,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
