/// The **`delete-confirm`** native alert (SCREENS.md §38) — shared by every
/// destructive action in the Work build: `edit-listing`'s Delete (§27),
/// `lead-detail`'s Delete (§32), `coworker-detail`'s Delete (§36). Same
/// [AlertDialog.adaptive] construction as `sign_out_confirm.dart`'s
/// [confirmSignOut] (see that file's doc comment for why the native alert,
/// not a bespoke sheet, is the spec-correct choice) — this is the second
/// caller of that exact shape, promoted here rather than each Work feature
/// re-building its own copy.
///
/// SCREENS.md §38 fixes the title per flow ("Delete listing?" / "Delete
/// lead?" / "Delete coworker?") and one shared body ("This action cannot be
/// undone."). [confirmDelete] takes [subject] (`"listing"`/`"lead"`/
/// `"coworker"`, or any other noun a future flow needs) and builds the
/// title from it — `"Delete $subject?"` — rather than hard-coding the three
/// known flows, since a caller passing a mismatched noun would still read
/// correctly.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';

/// Shows the delete-confirm alert titled `"Delete $subject?"` and reports
/// whether the user chose **"Delete"**. Never performs the deletion itself
/// — callers own the actual `DELETE` request and its own toast, matching
/// [confirmSignOut]'s split (see that file).
///
/// **[subject] must already be localized by the caller** (e.g. the
/// listing/lead/coworker word from `lib/l10n/GLOSSARY.md`) — this function
/// only supplies the surrounding sentence via [AppLocalizations]
/// .sharedDeleteConfirmTitle's `{subject}` placeholder, since it has no way
/// to know from a bare noun which flow (listing/lead/coworker, or a future
/// caller) is asking.
Future<bool> confirmDelete(BuildContext context, {required String subject}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(l10n.sharedDeleteConfirmTitle(subject)),
      content: Text(l10n.sharedDeleteConfirmBody),
      actions: [
        TextButton(
          key: const ValueKey('deleteConfirmCancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.sharedConfirmDialogCancelLabel),
        ),
        TextButton(
          key: const ValueKey('deleteConfirmDelete'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.sharedDeleteConfirmDeleteLabel,
            style: TextStyle(color: AppStatusColors.errorText),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
