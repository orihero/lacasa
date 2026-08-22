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
///   file has no go_router dependency at all, and that separation is
///   deliberate: this file is unit-testable with a plain [ProviderContainer]
///   and no routing concepts leak into it.
///
/// **Auth is real as of this file.** [AuthSessionNotifier]'s three commands
/// ([signInWithPassword], [registerAccount], [signOut]) call
/// `features/auth/data/auth_repository.dart`'s [AuthRepository] — which, by
/// default, is the offline [FixtureAuthRepository] (see `auth_mode.dart`)
/// — and let its [ApiException] propagate uncaught, so a screen can branch
/// on the exact `ApiErrorCode` SCREENS.md's copy calls for (§3.12's
/// "Invalid email or password", §3.13's "Email is already registered", …)
/// rather than this file collapsing every failure into a bool.
///
/// ## Startup restore
///
/// A user who signed in last week must not be signed out on relaunch
/// (`main.dart`'s [hasPersistedAuthTokenProvider] override plus this file's
/// [AuthSessionNotifier.build] do that). The design has two halves,
/// deliberately split by cost:
///
/// - **A synchronous, local, pre-`runApp` check**: does a token exist at
///   all? `main.dart` reads that once via `TokenStorage.getToken()` — one
///   keystore lookup, exactly the same cost tier as
///   `features/onboarding/state/onboarding_providers.dart`'s
///   `hasSeenOnboarding` read on the same blocking path — and overrides
///   [hasPersistedAuthTokenProvider] with the answer. **This is not "the
///   first frame is wrong without it"** the way onboarding's read is
///   (nothing here gates a redirect app_router.dart can make); it exists so
///   [AuthSessionNotifier.build] has a *safe, synchronous* answer to "should
///   I attempt a restore at all" without unconditionally starting async
///   work — see the next point for why that distinction matters. The
///   unoverridden default is `false`, the same fail-safe direction
///   `onboardingSeenProvider`'s default takes: every entry point that
///   doesn't explicitly override it (a widget test's bare
///   `ProviderContainer()`, a screen pumped in isolation, a Riverpod
///   preview) gets an inert, always-signed-out session with zero side
///   effects, rather than every such harness having to remember to disable
///   a restore attempt it never asked for.
/// - **A bounded, async, post-`runApp` validation**: when
///   [hasPersistedAuthTokenProvider] is `true`, [AuthSessionNotifier.build]
///   fires [_restoreSession] on a microtask (never blocking `build()`
///   itself, so the first frame paints signed-out immediately) which calls
///   [AuthRepository.currentUser] — the network half — wrapped in
///   [Future.timeout]. This is the piece that is genuinely unsafe to put on
///   `main.dart`'s blocking path: unlike a keystore read, a network call has
///   no bound in the wild (unreachable host, captive portal, a slow
///   connection), and blocking every app launch on it would trade a
///   cosmetic problem (see below) for occasionally not painting a first
///   frame at all — a strictly worse failure. A restore that fails for any
///   reason (timeout, no connection, a genuinely dead token) leaves the
///   session signed out; it never crashes and never blocks anything else in
///   the app from working meanwhile.
///
/// **Accepted trade-off**: because the network validation happens after the
/// first frame, a returning agent/coworker briefly sees the 4-tab
/// signed-out bar before it reflows to 5 tabs the moment [_restoreSession]
/// resolves. `tab_shell_test.dart`'s "appears immediately on role change"
/// coverage already proves that reflow is instant and correct once the role
/// arrives — what this file adds is *how* the role arrives on a cold start.
/// [AuthSessionState.isRestoring] is exposed for a future splash/gate to
/// hide that reflow behind a loading state instead, but nothing reads it
/// yet: `app_router.dart` is out of this task's ownership, so wiring it into
/// a redirect is left to whichever task builds the screens this restore now
/// makes possible.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/state/auth_repository_provider.dart';

/// How long [AuthSessionNotifier] waits for [AuthRepository.currentUser]
/// before giving up on a startup restore and settling for signed-out. Picked
/// to comfortably cover a slow mobile connection without leaving a returning
/// user's tab bar looking "stuck" in the wrong shape for an unreasonable
/// stretch of the session — this is a UX bound, not a server-side timeout
/// `apps/api` enforces.
const Duration _restoreTimeout = Duration(seconds: 8);

/// `main.dart`'s pre-`runApp` answer to "does a persisted auth session exist
/// to even attempt restoring?" — see this file's doc comment. Defaults to
/// `false`, the safe/inert direction for every entry point that doesn't
/// override it.
final hasPersistedAuthTokenProvider = Provider<bool>((ref) => false);

/// Current session snapshot. `role == null` means fully signed out —
/// distinct from `role == UserRole.user` (a signed-in buyer), matching the
/// mockup's own three-way `matchWhen` split ("signed-out" / buyer / agent).
@immutable
class AuthSessionState {
  const AuthSessionState({this.role, this.user, this.isRestoring = false});

  const AuthSessionState.signedOut({this.isRestoring = false})
    : role = null,
      user = null;

  /// `null` for a fully signed-out session; otherwise the signed-in user's
  /// role as returned by the API (`UserRole.unknown` is treated as "not
  /// agent/coworker" everywhere below — a forward-compat role the app
  /// doesn't recognize yet should never unlock the Work tab).
  final UserRole? role;

  /// The full signed-in user, when there is one. `null` whenever [role] is
  /// `null`.
  final AuthUser? user;

  /// `true` only while the startup restore this file's doc comment
  /// describes is in flight. Always `false` for a session that began with
  /// an explicit [AuthSessionNotifier.signInWithPassword]/
  /// [AuthSessionNotifier.registerAccount] call rather than a relaunch, and
  /// always `false` again once the restore attempt settles (either way).
  final bool isRestoring;

  bool get isSignedIn => role != null;

  /// Gates the Work tab/branch — SCREENS.md §5: "the Work tab appears for
  /// agents and coworkers only."
  bool get canAccessWork => role == UserRole.agent || role == UserRole.coworker;

  bool get isCoworker => role == UserRole.coworker;

  @override
  bool operator ==(Object other) =>
      other is AuthSessionState &&
      other.role == role &&
      other.user == user &&
      other.isRestoring == isRestoring;

  @override
  int get hashCode => Object.hash(role, user, isRestoring);
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    if (ref.watch(hasPersistedAuthTokenProvider)) {
      // Fire-and-forget on purpose: build() must stay synchronous, and the
      // signed-out state returned below is what the very first frame
      // paints. See the file doc comment's "Startup restore" section.
      Future.microtask(_restoreSession);
      return const AuthSessionState.signedOut(isRestoring: true);
    }
    return const AuthSessionState.signedOut();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .currentUser()
          .timeout(_restoreTimeout);
      signIn(user);
      return;
    } on ApiErrorException catch (e) {
      if (e.code == ApiErrorCode.unauthorized) {
        // The stored token is definitively dead (expired/invalid, or the
        // account it named is gone) — clear it so the next launch doesn't
        // keep retrying a doomed request forever. A network hiccup instead
        // throws NetworkException/TimeoutException below, which leaves the
        // token alone: it might still be good once connectivity returns.
        unawaited(ref.read(authRepositoryProvider).signOut());
      }
    } catch (_) {
      // NetworkException, a timeout, or anything else unforeseen: no
      // diagnosis needed here, just degrade to signed-out below.
    }
    state = const AuthSessionState.signedOut();
  }

  /// Applies a successful login/register/restore result. Public because a
  /// screen that obtains an [AuthUser] some other way (there is none today,
  /// but this mirrors `signIn`'s pre-existing role as the one place state
  /// transitions to "signed in") should still go through here rather than
  /// constructing [AuthSessionState] by hand.
  void signIn(AuthUser user) =>
      state = AuthSessionState(role: user.role, user: user);

  /// SCREENS.md §3.12: email/password login. Lets [AuthRepository.login]'s
  /// [ApiErrorException] (`invalidCredentials` 401, `validation` 400)
  /// propagate — the caller maps it to the screen's copy.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    signIn(user);
  }

  /// SCREENS.md §3.13: registration, buyer or realtor-applicant. Lets
  /// [AuthRepository.register]'s [ApiErrorException] (`emailTaken` 409,
  /// `validation` 400) propagate. The resulting session's `role` is always
  /// `"user"` even when [realtor] is supplied — see `auth_repository.dart`.
  Future<void> registerAccount({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .register(
          fullName: fullName,
          email: email,
          password: password,
          phoneNumber: phoneNumber,
          realtor: realtor,
        );
    signIn(user);
  }

  /// Clears the persisted session via [AuthRepository.signOut] and resets
  /// state. Async, unlike the rest of this class's mutators, because it has
  /// to wait for the token to actually be cleared before a screen navigates
  /// away — a signed-out UI backed by a still-present token is the one state
  /// this app must never show, even briefly.
  ///
  /// **Failure contract, and why it is split.** The repository call ends at
  /// `flutter_secure_storage`'s `delete`, which is a platform channel and
  /// *can* throw — a corrupted Android keystore is the realistic case. Two
  /// things follow, and they pull in opposite directions:
  ///
  /// - The in-memory session is cleared in a `finally`, so it is dropped
  ///   **unconditionally**. Whatever happened to the keystore, a user who
  ///   asked to sign out must not be left looking at their own name, email
  ///   and phone number. This is the half that must never fail.
  /// - The error is then **rethrown**, because the persisted token may have
  ///   survived, and a token that outlives a sign-out means the next launch
  ///   silently signs the account back in. On a shared or handed-on device
  ///   that is exactly the thing the user was trying to prevent, so it is
  ///   theirs to know about — callers surface it (see `sign_out_confirm.dart`
  ///   and `settings_screen.dart`).
  ///
  /// Swallowing it here was the obvious alternative and was rejected for
  /// that second reason: it would make every caller's "signed out" message
  /// a claim this method cannot actually back up.
  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      state = const AuthSessionState.signedOut();
    }
  }

  /// Escape hatch for screens/tests that need to preview a role without a
  /// full [AuthUser] (e.g. a dev role switcher, or this package's own
  /// widget tests, `test/navigation/tab_shell_test.dart` among them). Prefer
  /// [signInWithPassword]/[registerAccount] for a real session.
  void setRole(UserRole? role) =>
      state = AuthSessionState(role: role, user: state.user);
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
      AuthSessionNotifier.new,
    );
