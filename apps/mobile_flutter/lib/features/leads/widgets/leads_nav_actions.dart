/// The pair of trailing icon buttons `leads-list` and `leads-kanban` both
/// put on their [NavRow]: a view-toggle (icon/label swap between the two
/// screens — list points at kanban and vice versa) and an "add lead"
/// circle. Kept leads-local rather than promoted to `shared/widgets/`: it's
/// only ever used by these two screens, not a cross-feature shape.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';

class LeadsNavActions extends StatelessWidget {
  const LeadsNavActions({
    super.key,
    required this.toggleIcon,
    required this.toggleLabel,
    required this.toggleKey,
    required this.onToggleView,
    required this.addKey,
    required this.onAddLead,
  });

  final IconData toggleIcon;
  final String toggleLabel;
  final Key toggleKey;
  final VoidCallback onToggleView;
  final Key addKey;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: toggleLabel,
          child: GestureDetector(
            key: toggleKey,
            behavior: HitTestBehavior.opaque,
            onTap: onToggleView,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(toggleIcon, size: 20, color: colors.ink2),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          button: true,
          label: AppLocalizations.of(context).leadsAddNewLeadLabel,
          child: GestureDetector(
            key: addKey,
            behavior: HitTestBehavior.opaque,
            onTap: onAddLead,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.pill, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, size: 20, color: colors.pillInk),
            ),
          ),
        ),
      ],
    );
  }
}
