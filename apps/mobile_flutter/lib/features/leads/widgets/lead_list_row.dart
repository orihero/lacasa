/// One row of `leads-list` (§30) — `#{id}`, full name, phone, Commit
/// (`Lead.comment`), status pill, source. Built on `CrmListTile`
/// (`shared/widgets/crm_list_tile.dart`, explicitly named for this screen
/// in its own doc comment) for the leading-avatar/title/subtitle/trailing
/// shape; the id/Commit/Source fields that don't fit that 4-slot shape sit
/// in a second line underneath, inside the same tappable column, rather
/// than forcing every field into `CrmListTile`'s single subtitle line.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class LeadListRow extends StatelessWidget {
  const LeadListRow({super.key, required this.lead, required this.onTap});

  final Lead lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final commit = lead.comment?.trim();
    final source = lead.source?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrmListTile(
            key: ValueKey('leadRow-${lead.id}'),
            leading: AgentAvatar(avatarUrl: null, fullName: lead.fullName),
            title: lead.fullName,
            subtitle: lead.phone,
            trailing: LeadStatusPill(status: lead.status),
            onTap: onTap,
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              left: 56, // aligns under CrmListTile's title, past its 44px leading + gap.
            ),
            child: Text(
              Formatters.adIdBadge(lead.id),
              key: ValueKey('leadRowId-${lead.id}'),
              style: type.micro.copyWith(color: colors.faint),
            ),
          ),
          if (commit != null && commit.isNotEmpty || source != null && source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: 56, // aligns under CrmListTile's title, past its 44px leading + gap.
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      commit != null && commit.isNotEmpty ? commit : '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.bodySmall.copyWith(color: colors.muted),
                    ),
                  ),
                  if (source != null && source.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.micro.copyWith(color: colors.faint),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

