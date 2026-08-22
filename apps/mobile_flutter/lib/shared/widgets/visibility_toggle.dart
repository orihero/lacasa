/// The password show/hide eye icon dropped into a [LabelledFormField]'s
/// `trailing` slot. Promoted out of three byte-identical private
/// `_VisibilityToggle`s (`add_coworker_screen.dart`,
/// `coworker_detail_screen.dart`, `edit_profile_screen.dart`).
///
/// **Not** the same widget as `features/auth/widgets/auth_form_widgets
/// .dart`'s `AuthVisibilityToggle`, even though the two render identically
/// — that file's own doc comment already explains why `AuthField` stays
/// apart from this file's `LabelledFormField` (button height,
/// `onChanged` optionality), and a toggle that only ever appears inside
/// one of those two fields' `trailing` slot follows the same split rather
/// than reaching across it.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';

class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({super.key, required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: obscured ? l10n.sharedShowPasswordLabel : l10n.sharedHidePasswordLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // `.pw .eye{width:40px;height:40px;border-radius:20px;
        // font-size:17px;color:var(--muted)}` — the mockup gives the eye a
        // button-sized box, not a bare glyph. Stated as a [SizedBox] because
        // `HitTestBehavior.opaque` makes the child's own box the whole
        // tappable region, and an 18px icon alone is under half the 48dp
        // minimum target.
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
