/// One Kanban card (SCREENS.md §31) — `fullName`, bold phone, `comment`,
/// a conditional red pill (callback date/time for `need_to_call_back`, or
/// the conversation note for `rejected`/`accepted`), and a footer with only
/// the created-at timestamp — **no coworker avatar/name slot**, per
/// `WORK_TAB_CONTRACT.md` ruling 7.8: `Lead` carries no agent/coworker
/// identity distinct from the signed-in session's own scope, so that footer
/// half has nothing real to bind for an agent's own view. Fabricating an
/// avatar there is exactly what the honesty rule this build runs on
/// forbids — omitted rather than faked.
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

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class KanbanCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                  Text(
                    Formatters.date(lead.createdAt),
                    style: type.micro.copyWith(color: colors.faint),
                  ),
                  if (failed) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Couldn't move — try again.",
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
