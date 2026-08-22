/// The **"Logout"** confirm alert, shared by every screen that signs a
/// session out — `profile-buyer` (§3.15), `profile-agent` (§3.16) and
/// `settings` (§3.19: "(red, → `delete-confirm`-style confirm)"). All three
/// tasks that built those screens independently invented the identical
/// question ("Log out?" / "You'll need to sign in again to access your
/// account.") because none of SCREENS.md's own copy fits: §3.38's
/// `delete-confirm` only defines contextual titles for the three flows that
/// actually delete something (listing/lead/coworker), none of which is a
/// sign-out.
///
/// **Consolidated here rather than left as the two near-identical dialogs
/// the profile task (`AlertDialog.adaptive`) and the settings task (a
/// bespoke `Dialog` painted to match `mockup-e-liquid-glass.html`'s
/// `.sh--mid` alert) each shipped.** [AlertDialog.adaptive] is the one that
/// survives: SCREENS.md §1 files `delete-confirm` itself under "Bottom
/// sheet ... (native alert style)", and settings' own row text explicitly
/// asks for delete-confirm-*style* chrome — i.e. a native alert, not a
/// brand-styled sheet — so the platform-native dialog was the spec-correct
/// choice all along, not just the more convenient one.
///
/// Split into two pieces rather than one bundled "confirm-then-sign-out"
/// call, because the callers' post-confirm needs differ: `profile-buyer`/
/// `profile-agent` need nothing beyond the sign-out itself (`ProfileRoleScreen`
/// swaps to the signed-out variant on its own once the session updates), but
/// `settings` also drives a "Signing out…" row spinner and a `context.go`
/// back to its branch root — logic this file has no business owning.
/// [confirmSignOut] is the low-level piece ("did the user confirm");
/// [confirmAndSignOut] is the no-frills convenience both profile screens use
/// unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../navigation/auth_session.dart';
import '../../theme/theme.dart';

/// Shows the confirm alert and reports whether the user chose "Logout".
/// Never signs anyone out itself — see this file's doc comment for why that
/// is left to the caller.
Future<bool> confirmSignOut(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(l10n.sharedSignOutTitle),
      content: Text(l10n.sharedSignOutBody),
      actions: [
        TextButton(
          key: const ValueKey('profileLogoutCancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.sharedConfirmDialogCancelLabel),
        ),
        TextButton(
          key: const ValueKey('profileLogoutConfirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.sharedSignOutConfirmLabel,
            style: TextStyle(color: AppStatusColors.errorText),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// [confirmSignOut] plus, if confirmed, the actual
/// [AuthSessionNotifier.signOut] call — the whole flow `profile-buyer`/
/// `profile-agent`'s Logout rows need and nothing more. Callers don't need
/// to do anything else afterward: `ProfileRoleScreen` (outside this file)
/// watches [authSessionProvider] and swaps to `ProfileSignedOutScreen` on
/// its own the moment the session state flips, exactly like every other
/// role-reactive rebuild in this app.
/// The session is always dropped, even when clearing the stored token fails
/// — see [AuthSessionNotifier.signOut]'s failure contract. That failure is
/// caught here rather than left to propagate out of a tap handler (where it
/// would surface as an unhandled async error and tell the user nothing), and
/// reported, because the consequence is one only they can act on: the
/// account may sign itself back in on next launch.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  if (!await confirmSignOut(context)) return;

  try {
    await ref.read(authSessionProvider.notifier).signOut();
  } catch (_) {
    if (!context.mounted) return;
    // Reuses settingsSignOutTokenNotClearedMessage rather than a new key —
    // Settings' own _confirmLogout shows this exact sentence for the same
    // failure; see that key's description in app_en.arb.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).settingsSignOutTokenNotClearedMessage,
        ),
      ),
    );
  }
}
