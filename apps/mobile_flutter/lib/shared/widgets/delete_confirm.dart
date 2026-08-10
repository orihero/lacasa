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

import '../../theme/theme.dart';

/// Shows the delete-confirm alert titled `"Delete $subject?"` and reports
/// whether the user chose **"Delete"**. Never performs the deletion itself
/// — callers own the actual `DELETE` request and its own toast, matching
/// [confirmSignOut]'s split (see that file).
Future<bool> confirmDelete(BuildContext context, {required String subject}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text('Delete $subject?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          key: const ValueKey('deleteConfirmCancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('deleteConfirmDelete'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: TextStyle(color: AppStatusColors.errorText),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
