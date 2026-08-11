/// The fixed pending/success/error toast pattern SCREENS.md §5 requires of
/// every Work form's save action: *"every form's `toast.promise`-style
/// feedback follows a fixed 3-state pattern — pending ... success ...
/// error ... shown as a transient bottom toast, not a blocking alert,
/// except `delete-confirm` and OAuth failures which use native alerts."*
///
/// Built on [ScaffoldMessenger]/[SnackBar] — the platform-idiomatic
/// "transient bottom toast" primitive, and the only one this app depends on
/// already (no `fluttertoast`/`toastification` package exists here, and
/// none is worth adding: a themed [SnackBar] satisfies §5's contract
/// exactly). There is no toast system anywhere in `apps/web`/`apps/console`
/// to port timing/sequencing from (see the web/console survey's
/// discrepancy #8) — the pending → success **or** error sequence below is
/// this build's own, designed to satisfy §5's copy rules directly.
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';

abstract final class LaCasaToast {
  /// Shows a neutral, non-dismissing-by-timeout pending toast (e.g.
  /// "Creating", "Uploading") — call this immediately before an async
  /// mutation starts, then call [showSuccess] or [showError] once it
  /// settles. [showSuccess]/[showError] both call
  /// [ScaffoldMessengerState.hideCurrentSnackBar] first, so this toast
  /// never lingers alongside the one that replaces it.
  static void showPending(BuildContext context, String message) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 1), // replaced explicitly, not timed out
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.card,
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(child: Text(message, style: TextStyle(color: colors.ink))),
            ],
          ),
        ),
      );
  }

  /// A transient success toast (e.g. "Successfully created") — 2.5s,
  /// auto-dismisses.
  static void showSuccess(BuildContext context, String message) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 2500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.card,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppStatusColors.successText, size: 20),
              const SizedBox(width: AppSpacing.base),
              Expanded(child: Text(message, style: TextStyle(color: colors.ink))),
            ],
          ),
        ),
      );
  }

  /// A transient error toast — SCREENS.md's copy is either a generic
  /// "Something went wrong" or a specific server message quoted per screen
  /// in §3; pass whichever the caller already resolved (e.g. from an
  /// [ApiErrorException]'s `message`), this function does not branch on
  /// [ApiErrorCode] itself.
  static void showError(BuildContext context, String message) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.card,
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: AppStatusColors.errorText, size: 20),
              const SizedBox(width: AppSpacing.base),
              Expanded(child: Text(message, style: TextStyle(color: colors.ink))),
            ],
          ),
        ),
      );
  }

  /// Runs [action] wrapped in the full pending → success/error sequence:
  /// shows [pending] immediately, awaits [action], then shows [success] on
  /// completion or [errorMessage]'s result on failure (default: every
  /// [ApiException]'s own `message`, i.e. "Something went wrong" is left to
  /// the caller to pass explicitly as [errorMessage] when SCREENS.md calls
  /// for that generic copy instead of the server's own message). Rethrows
  /// whatever [action] threw after showing the error toast, so a caller can
  /// still branch on the specific [ApiErrorCode] (e.g. to keep a form's
  /// fields populated) — this helper only owns the toast, never the
  /// control flow after a failure.
  static Future<T> run<T>({
    required BuildContext context,
    required Future<T> Function() action,
    required String pending,
    required String success,
    String Function(Object error)? errorMessage,
  }) async {
    showPending(context, pending);
    try {
      final result = await action();
      if (context.mounted) showSuccess(context, success);
      return result;
    } catch (error) {
      if (context.mounted) {
        showError(
          context,
          errorMessage?.call(error) ?? _defaultErrorMessage(context, error),
        );
      }
      rethrow;
    }
  }

  // Takes [context] (rather than a plain top-level function taking
  // [AppLocalizations]) purely because a context is already sitting right
  // there in [run]'s catch block and this is a private helper with exactly
  // one caller — no need to widen the seam further.
  static String _defaultErrorMessage(BuildContext context, Object error) {
    if (error is ApiException) return error.message;
    return AppLocalizations.of(context).sharedGenericErrorMessage;
  }
}
