/// The **"Discard changes?"** alert SCREENS.md §5 requires before dismissing
/// any of `create-listing`, `edit-listing`, `edit-profile`, `create-lead`,
/// `add-coworker`, `coworker-detail` while unsaved form state exists:
/// *"Modals with unsaved form state ... show a discard-confirmation alert
/// ('Discard changes?' / 'Cancel' / 'Discard') before dismissing."*
///
/// Same [AlertDialog.adaptive] shape as `sign_out_confirm.dart`/
/// `delete_confirm.dart` — one more native-alert-not-bespoke-sheet call
/// site, not a reason to invent a fourth pattern.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';

/// Shows the "Discard changes?" alert and reports whether the user chose
/// **"Discard"**. Callers are responsible for deciding *whether* to call
/// this at all (i.e. tracking their own form's dirty state) and for the
/// actual dismissal (`Navigator.pop`/`context.pop`) once it returns `true`
/// — this function never navigates on its own, matching every other
/// confirm-alert helper in `shared/widgets/`.
///
/// Typical call site, e.g. a form screen's back-button/`PopScope` handler:
/// ```dart
/// if (!isDirty || await confirmDiscardChanges(context)) {
///   Navigator.of(context).pop();
/// }
/// ```
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(l10n.sharedDiscardChangesTitle),
      content: Text(l10n.sharedDiscardChangesBody),
      actions: [
        TextButton(
          key: const ValueKey('discardChangesCancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.sharedConfirmDialogCancelLabel),
        ),
        TextButton(
          key: const ValueKey('discardChangesDiscard'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.sharedDiscardChangesDiscardLabel,
            style: TextStyle(color: AppStatusColors.errorText),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
