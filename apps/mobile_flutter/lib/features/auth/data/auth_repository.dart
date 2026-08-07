/// Repository seam behind every signed-in screen this slice unlocks — login,
/// register, and profile edits (SCREENS.md §12/§13/§18). Two
/// implementations: [FixtureAuthRepository] (offline stand-in, a handful of
/// seeded accounts) and [LiveAuthRepository] (the real [LaCasaApi]) — see
/// `auth_mode.dart` for which one the app wires up by default, and
/// `state/auth_repository_provider.dart` for how a screen gets one.
///
/// **Every method's failure contract**, so a screen can map a thrown
/// [ApiErrorException] onto SCREENS.md's exact copy without re-deriving it
/// from `apps/api` each time:
///
/// - [login] — `ApiErrorCode.invalidCredentials` (401): wrong email or
///   password (§3.12: "Invalid email or password"). `validation` (400) for
///   a malformed payload — should not normally happen, since the screen's
///   own field validation runs first, but the server is the final word.
/// - [register] — `ApiErrorCode.emailTaken` (409): the email is already
///   registered (§3.13: "Email is already registered"). `validation` (400)
///   for a field the server rejected. The returned [AuthUser.role] is
///   always `"user"` even when [realtor] is supplied — approving a realtor
///   application is a separate, manual step with no route of its own (see
///   `apps/api/src/routes/auth.js`'s `realtorApplicationColumns`).
/// - [currentUser] — `ApiErrorCode.unauthorized` (401): no token stored, the
///   stored token is expired/invalid, or the account it names no longer
///   exists. Used both for a screen that needs the freshest server-side
///   truth and for `lib/navigation/auth_session.dart`'s startup restore.
/// - [updateProfile] — same `emailTaken`/`validation`/`unauthorized` split
///   as [register]/[currentUser], per `apps/api/src/routes/users.js`'s
///   `PATCH /me` (SCREENS.md §3.18's "Error updating profile: {message}").
/// - [signOut] never throws — clearing local session state cannot fail in a
///   way worth surfacing to a screen.
library;

import '../../../api/api.dart';

abstract class AuthRepository {
  Future<AuthUser> login({required String email, required String password});

  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  });

  /// `GET /auth/me` (or its fixture equivalent) — re-validates whatever
  /// session is currently persisted and returns the fresh user, rather than
  /// trusting a cached value. Throws `unauthorized` when there is nothing
  /// to validate (no persisted session) as much as when a real one has
  /// gone stale, which is exactly what lets a caller treat "never signed
  /// in" and "signed in, but not anymore" identically.
  Future<AuthUser> currentUser();

  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  });

  /// Clears whatever session this repository has persisted. Idempotent —
  /// calling it twice, or when nothing was ever signed in, is a no-op.
  Future<void> signOut();
}
