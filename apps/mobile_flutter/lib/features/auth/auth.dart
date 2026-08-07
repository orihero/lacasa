/// Barrel for `lib/features/auth/` — the repository seam behind every
/// signed-in screen this slice unlocks (SCREENS.md §12/§13/§15/§16/§18),
/// plus the two screens built directly on top of it: `login` (§3.12) and
/// `register` (§3.13).
///
/// Exports what a caller (chiefly `app_router.dart`, for the two screens;
/// any other screen needing to read or drive auth state, for everything
/// else) should build against: the [AuthRepository] interface, its
/// live/fixture switch, [authRepositoryProvider], and [LoginScreen]/
/// [RegisterScreen] themselves — both take no constructor arguments, so
/// wiring either route is `pageBuilder: (context, state) =>
/// MaterialPage(fullscreenDialog: true, child: const LoginScreen())` (and
/// the `Register` equivalent), replacing `app_router.dart`'s current
/// `_placeholder('Login')`/`_placeholder('Register')` stubs.
///
/// The session itself — role, current user, the
/// `signInWithPassword`/`registerAccount`/`signOut` commands — lives in
/// `lib/navigation/auth_session.dart`'s `authSessionProvider`, deliberately
/// outside this barrel: that file has no dependency on this feature
/// directory beyond the repository seam, and screens should import it
/// directly rather than through here.
library;

export 'data/auth_mode.dart';
export 'data/auth_repository.dart';
export 'state/auth_repository_provider.dart';
export 'widgets/login_screen.dart';
export 'widgets/register_screen.dart';
