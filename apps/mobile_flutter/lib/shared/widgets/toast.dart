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
///
/// **Nothing in the app should build a bare [SnackBar] itself.** A raw
/// `SnackBar(content: Text(...))` used to inherit Material's defaults — a
/// *docked* dark-grey bar, no status icon — which was a visibly different
/// component from the floating `colors.card` toast above, and the two were
/// shipping side by side on the same screen (`listing-detail`'s Share used
/// this file, its Save used a raw bar). `AppTheme` now carries the bar's
/// behaviour, background, copy colour and action colour as a
/// `SnackBarThemeData`, so the remaining raw sites in `features/` at least
/// *look* right; that is a safety net, not a licence. Everything the theme
/// cannot supply still lives here — the status glyph, the per-state
/// durations, and the pending → success/error sequence §5 actually asks for
/// — so every site should still call [showSuccess]/[showError]/[showInfo].
/// The one thing that used to force a caller back to a raw bar — needing a
/// tappable action, which this file had no way to express — is now [action];
/// a snackbar with a button is still a toast, and it should still look like
/// the rest of them.
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
    _show(
      context,
      message: message,
      // Replaced explicitly by showSuccess/showError, not timed out.
      duration: const Duration(minutes: 1),
      leading: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.ink),
      ),
    );
  }

  /// A transient success toast (e.g. "Successfully created") — 2.5s,
  /// auto-dismisses. See [action] on [_show] for when to pass one.
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      duration: const Duration(milliseconds: 2500),
      leading: const Icon(
        Icons.check_circle_rounded,
        color: AppStatusColors.successText,
        size: 20,
      ),
      action: action,
    );
  }

  /// A transient error toast — SCREENS.md's copy is either a generic
  /// "Something went wrong" or a specific server message quoted per screen
  /// in §3; pass whichever the caller already resolved (e.g. from an
  /// [ApiErrorException]'s `message`), this function does not branch on
  /// [ApiErrorCode] itself.
  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      duration: const Duration(seconds: 4),
      leading: const Icon(
        Icons.error_rounded,
        color: AppStatusColors.errorText,
        size: 20,
      ),
      action: action,
    );
  }

  /// A transient *neutral* toast: something the user should know, that is
  /// neither a success nor a failure. It exists for the one shape
  /// [showError] was being misused for — "you need an account to do that" —
  /// where the red error icon actively misleads, telling the user something
  /// broke when nothing did. Same 4s budget as [showError], because a
  /// message worth an [action] is worth long enough to reach for it.
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    _show(
      context,
      message: message,
      duration: const Duration(seconds: 4),
      leading: Icon(Icons.info_outline_rounded, color: colors.ink2, size: 20),
      action: action,
    );
  }

  /// The single place the §5 toast look is defined: floating (never docked),
  /// on `colors.card` (never Material's dark grey), a 20px status glyph in
  /// the leading slot, ink-coloured copy. [action] renders as the trailing
  /// [SnackBarAction] — accent-coloured so it reads as tappable against the
  /// card, which Material's default `inversePrimary` label does not.
  ///
  /// That accent comes from `SnackBarThemeData.actionTextColor` in
  /// `lib/theme/app_theme.dart` — the only place it *can* come from without
  /// a per-call-site colour, since [SnackBar] itself has no
  /// `actionTextColor` and [SnackBarAction] resolves
  /// `textColor ?? snackBarTheme.actionTextColor` — rather than a `textColor`
  /// on each caller's [SnackBarAction]. This paragraph claimed
  /// "accent-coloured" while the only thing producing it was one call site
  /// (`favourite_button.dart`) passing its own colour, so the second action
  /// toast anyone added would have quietly shipped in Material's default.
  /// That theme entry also carries this bar's behaviour, background and text
  /// colour, so even a bare [SnackBar] built elsewhere inherits the look.
  static void _show(
    BuildContext context, {
    required String message,
    required Duration duration,
    required Widget leading,
    SnackBarAction? action,
  }) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.card,
          action: action,
          content: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(message, style: TextStyle(color: colors.ink)),
              ),
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
