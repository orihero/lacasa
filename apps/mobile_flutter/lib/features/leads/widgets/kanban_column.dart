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
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'kanban_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.leads,
    required this.pendingLeadIds,
    required this.failedLeadIds,
    required this.onCardTap,
    required this.onCardLongPress,
  });

  final LeadStatus status;
  final List<Lead> leads;
  final Set<String> pendingLeadIds;
  final Set<String> failedLeadIds;
  final ValueChanged<Lead> onCardTap;
  final ValueChanged<Lead> onCardLongPress;

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
            children: [
              LeadStatusPill(status: status),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${leads.length}',
                style: LaCasaTypography.tabular(
                  type.rowTitle,
                ).copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Expanded(
            child: leads.isEmpty
                ? Center(
                    child: Text(
                      'No leads in this stage yet.',
                      style: type.bodySmall.copyWith(color: colors.faint),
                    ),
                  )
                : ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        return KanbanCard(
                          lead: lead,
                          pending: pendingLeadIds.contains(lead.id),
                          failed: failedLeadIds.contains(lead.id),
                          onTap: () => onCardTap(lead),
                          onLongPress: () => onCardLongPress(lead),
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
