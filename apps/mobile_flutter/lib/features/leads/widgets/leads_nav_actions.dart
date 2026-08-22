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
            // `.nav .rnd.gl` — a 38px glass circle, not a bare icon.
            child: GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: AppRadii.pill,
              width: 38,
              height: 38,
              alignment: Alignment.center,
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
            // `.nav .rnd.acc` — 38px, filled with `--pill`, and carrying the
            // source's own drop shadow (`0 8px 18px -8px rgba(21,21,27,.6)`).
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.pill,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x9915151B),
                    blurRadius: 18,
                    spreadRadius: -8,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, size: 20, color: colors.pillInk),
            ),
          ),
        ),
      ],
    );
  }
}
