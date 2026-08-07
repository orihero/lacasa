/// Single source of truth for "who is signed in and what role are they" —
/// the piece of app state the navigation shell gates on (SCREENS.md §1/§5:
/// tab set depends on role; §5's Work-branch guard).
///
/// This is a plain [Notifier] (Riverpod 3.x idiomatic API, no `_generator`
/// codegen, no legacy `StateNotifierProvider`/`ChangeNotifierProvider`), so:
/// - widgets read it reactively with `ref.watch(authSessionProvider)`
///   (e.g. the tab bar's visible item set, `ProfileRoleScreen`'s branch),
/// - the router's `redirect` re-evaluation is bridged from this provider by
///   `_AuthRouterRefresh` in `app_router.dart`, not by this file — this
///   file has no go_router dependency at all.
///
/// **Scope note**: no real auth flow (login/register screens, token
/// persistence via `lib/api/token_storage.dart`) is wired up yet — that is
/// a later screen-building task's job. [signIn]/[signOut]/[setRole] exist
/// now so the navigation shell (and its tests) have something real to
/// react to; a later agent wires these calls to actual
/// `LaCasaApi.auth`/`TokenStorage` results instead of inventing its own
/// parallel state.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';

/// Current session snapshot. `role == null` means fully signed out —
/// distinct from `role == UserRole.user` (a signed-in buyer), matching the
/// mockup's own three-way `matchWhen` split ("signed-out" / buyer / agent).
@immutable
class AuthSessionState {
  const AuthSessionState({this.role, this.user});

  const AuthSessionState.signedOut() : role = null, user = null;

  /// `null` for a fully signed-out session; otherwise the signed-in user's
  /// role as returned by the API (`UserRole.unknown` is treated as "not
  /// agent/coworker" everywhere below — a forward-compat role the app
  /// doesn't recognize yet should never unlock the Work tab).
  final UserRole? role;

  /// The full signed-in user, when there is one. `null` whenever [role] is
  /// `null`.
  final AuthUser? user;

  bool get isSignedIn => role != null;

  /// Gates the Work tab/branch — SCREENS.md §5: "the Work tab appears for
  /// agents and coworkers only."
  bool get canAccessWork => role == UserRole.agent || role == UserRole.coworker;

  bool get isCoworker => role == UserRole.coworker;

  @override
  bool operator ==(Object other) =>
      other is AuthSessionState && other.role == role && other.user == user;

  @override
  int get hashCode => Object.hash(role, user);
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() => const AuthSessionState.signedOut();

  /// Applies a successful login/register/`GET /auth/me` result.
  void signIn(AuthUser user) =>
      state = AuthSessionState(role: user.role, user: user);

  void signOut() => state = const AuthSessionState.signedOut();

  /// Escape hatch for screens/tests that need to preview a role without a
  /// full [AuthUser] (e.g. a dev role switcher, or this package's own
  /// widget tests). Prefer [signIn]/[signOut] once real auth exists.
  void setRole(UserRole? role) =>
      state = AuthSessionState(role: role, user: state.user);
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
      AuthSessionNotifier.new,
    );
