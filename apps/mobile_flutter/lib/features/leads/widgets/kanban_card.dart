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
/// leaves "Couldn't move — try again." on the card — `apps/console`'s own
/// copy, replicated per ruling 7.5.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../coworkers/state/coworkers_providers.dart';

class KanbanCard extends ConsumerWidget {
  const KanbanCard({
    super.key,
    required this.lead,
    required this.pending,
    required this.failed,
    required this.onTap,
    required this.onLongPress,
  });

  final Lead lead;
  final bool pending;
  final bool failed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final comment = lead.comment?.trim();
    final note = lead.conversationComment?.trim();
    final showCallbackPill =
        lead.status == LeadStatus.needToCallBack && lead.callbackDate != null;
    final showNotePill =
        (lead.status == LeadStatus.rejected || lead.status == LeadStatus.accepted) &&
        note != null &&
        note.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                  if (lead.phone case final phone? when phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: LaCasaTypography.tabular(
                        type.bodySmall,
                      ).copyWith(color: colors.ink, fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      comment,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: type.bodySmall.copyWith(color: colors.ink2),
                    ),
                  ],
                  if (showCallbackPill) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _RedPill(text: Formatters.date(lead.callbackDate!)),
                  ] else if (showNotePill) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _RedPill(text: note),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          Formatters.date(lead.createdAt),
                          overflow: TextOverflow.ellipsis,
                          style: type.micro.copyWith(color: colors.faint),
                        ),
                      ),
                      // Omitted outright for an empty `coworkerId` (a solo
                      // agent's — and a lone coworker's — leads always are)
                      // rather than mounting a lookup against nothing.
                      if (lead.coworkerId.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: _CoworkerFooter(coworkerId: lead.coworkerId)),
                      ],
                    ],
                  ),
                  if (failed) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocalizations.of(context).leadsCardMoveFailedMessage,
                      style: type.caption.copyWith(color: AppStatusColors.errorText),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.ink2),
                  ),
                ),
              ),
            ),
        ],
      ),
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
            AgentAvatar(avatarUrl: resolved.avatar, fullName: resolved.fullName, size: 16),
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

class _RedPill extends StatelessWidget {
  const _RedPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppStatusColors.errorBg,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: type.micro.copyWith(
          color: AppStatusColors.errorText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
