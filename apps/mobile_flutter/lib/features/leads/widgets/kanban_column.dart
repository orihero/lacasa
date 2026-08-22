/// One Kanban column (SCREENS.md §31) — a status pill + card count header,
/// then its own independently vertically-scrolling card list. Rendered as
/// one full-width page of `leads_kanban_screen.dart`'s `PageView`, which is
/// what gives the "snaps one column per screen-width" rule (SCREENS.md §5)
/// for free: a `PageView` page occupies the whole viewport, and its child's
/// own vertical `ListView` scrolls independently of the horizontal paging
/// gesture (different axes never contend).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'kanban_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.leads,
    required this.pendingLeadIds,
    required this.failedDestinations,
    required this.onCardTap,
    required this.onCardLongPress,
    required this.onCardRetry,
  });

  final LeadStatus status;
  final List<Lead> leads;
  final Set<String> pendingLeadIds;

  /// lead id → the column that lead's last failed move attempt wanted, straight
  /// off [KanbanMoveState.failedDestinations]. A card with no entry here shows
  /// no failure row at all.
  final Map<String, LeadStatus> failedDestinations;

  final ValueChanged<Lead> onCardTap;
  final ValueChanged<Lead> onCardLongPress;

  /// Re-runs a failed move — the lead plus the destination its failed attempt
  /// was aiming for, which is everything `leads_kanban_screen.dart` needs to
  /// replay the very same move (gate sheet included, for the three gated
  /// columns).
  final void Function(Lead lead, LeadStatus destination) onCardRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // `.kb__n{margin-left:auto}` — the count sits against the
            // column's right edge, whatever the pill's width. `spaceBetween`
            // rather than a `Spacer`: a `Spacer` is a second (tight) flex
            // child, so it would split the free space evenly with the
            // `Flexible` below — halving the pill's ceiling *and* leaving
            // the count stranded mid-row whenever the pill shrink-wraps.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible so the longest localized status label ("Qayta
              // qo'ng'iroq qilish kerak") ellipsizes inside the pill
              // instead of overflowing this row on a 360dp phone — the
              // pill is `.st`-sized (23dp tall, `0 10px` + a 5px dot) and
              // that vocabulary is the widest one it renders.
              Flexible(child: LeadStatusPill(status: status)),
              // Floor on the pill↔count gap for the widest-pill case, where
              // `spaceBetween` has no free space left to distribute.
              const SizedBox(width: AppSpacing.md),
              Text(
                '${leads.length}',
                style: LaCasaTypography.tabular(
                  type.label,
                ).copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Expanded(
            child: leads.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).leadsEmptyColumnMessage,
                      style: type.bodySmall.copyWith(color: colors.faint),
                    ),
                  )
                : ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      overscroll: false,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        final failedDestination = failedDestinations[lead.id];
                        return KanbanCard(
                          lead: lead,
                          pending: pendingLeadIds.contains(lead.id),
                          failedDestination: failedDestination,
                          onTap: () => onCardTap(lead),
                          onLongPress: () => onCardLongPress(lead),
                          onRetry: failedDestination == null
                              ? () {}
                              : () => onCardRetry(lead, failedDestination),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
