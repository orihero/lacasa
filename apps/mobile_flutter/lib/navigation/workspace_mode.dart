/// Which of the app's two shells an agent/coworker session is currently
/// living in — the state behind the Browse/Work switch.
///
/// ## Why this exists
///
/// The app ships two completely separate tab experiences (see
/// `app_router.dart`): a **buyer shell** (`/home`, `/search`, `/agents`,
/// `/profile` — 4 tabs) and an **agent shell** (`/work/dashboard`,
/// `/work/my-listings`, `/work/leads`, `/work/coworkers`, `/work/profile` —
/// 5 tabs). They are two sibling `StatefulShellRoute`s, not one shell whose
/// item list changes, so an agent is never "the buyer app plus a tab": the
/// whole screen set, the whole tab bar and the whole back-stack space swap.
///
/// A realtor still needs the buyer surfaces (searching comparables, reading
/// a competitor's listing, browsing the agents directory), so the two shells
/// are not a permanent fork of the account — they are a *mode*, and this
/// enum is the mode. Only agents/coworkers can be in [WorkspaceMode.work];
/// for every other session the value is simply never consulted (see
/// `app_router.dart`'s `_redirect`, which reads it only under
/// `canAccessWork`).
///
/// ## Why it is persisted
///
/// The mode outlives a relaunch on purpose. An agent who deliberately
/// switched to Browse and closed the app is telling us where they want to
/// be next time; snapping them back into the CRM on every cold start would
/// make the switch feel like it didn't take. Same storage and the same
/// fail-safe shape as `features/onboarding/data/onboarding_repository.dart`
/// — `flutter_secure_storage`, reused rather than adding
/// `shared_preferences` for one more flag.
///
/// **Every failure degrades to [WorkspaceMode.work]**, which is also the
/// unwritten default. An agent whose keystore hiccups lands in their
/// workspace — the surface their account exists for — and one tap gets them
/// to Browse. The opposite direction (defaulting a realtor into the buyer
/// app) hides the CRM behind a setting they never knowingly changed.
///
/// ## Why the initial value is injected, not read here
///
/// Identical constraint to `onboarding_providers.dart`: `app_router.dart`'s
/// `redirect` is synchronous and consults this on the first route it
/// resolves. `main.dart` performs the one keystore read before `runApp` and
/// overrides [workspaceModeProvider] with the answer, so by the time any
/// route resolves the value is simply known — no launching into the wrong
/// shell and flipping a frame later. Every other entry point (a widget test,
/// a screen pumped in isolation) gets the [WorkspaceMode.work] default
/// without touching storage.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The two shells a signed-in agent/coworker can be in. Deliberately not a
/// `bool`: `mode == WorkspaceMode.browse` reads as what it is at every call
/// site, where `!isWorkMode` would not.
enum WorkspaceMode {
  /// The 5-tab CRM shell — `/work/*`. The default.
  work,

  /// The 4-tab buyer shell — `/home`, `/search`, `/agents`, `/profile`.
  /// Exactly what a buyer session sees, with the agent's own
  /// `profile-agent` screen on the Profile tab.
  browse,
}

const String _workspaceModeKey = 'lacasa_workspace_mode';

/// Where the Browse/Work choice is persisted. An interface, like
/// `OnboardingRepository`, so a test can seed or observe the choice without
/// a platform channel.
abstract class WorkspaceModeRepository {
  /// The last mode this device chose. See this library's doc comment for
  /// why a failed read answers [WorkspaceMode.work].
  Future<WorkspaceMode> read();

  /// Records a switch. Fire-and-forget from the caller's point of view —
  /// the in-memory notifier has already moved.
  Future<void> write(WorkspaceMode mode);
}

class SecureWorkspaceModeRepository implements WorkspaceModeRepository {
  SecureWorkspaceModeRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<WorkspaceMode> read() async {
    try {
      final raw = await _storage.read(key: _workspaceModeKey);
      return raw == WorkspaceMode.browse.name
          ? WorkspaceMode.browse
          : WorkspaceMode.work;
    } catch (_) {
      return WorkspaceMode.work;
    }
  }

  @override
  Future<void> write(WorkspaceMode mode) async {
    try {
      await _storage.write(key: _workspaceModeKey, value: mode.name);
    } catch (_) {
      // A failed write costs the agent one extra tap on the next launch.
      // There is nothing useful to say to them about their keychain here.
    }
  }
}

final workspaceModeRepositoryProvider = Provider<WorkspaceModeRepository>(
  (ref) => SecureWorkspaceModeRepository(),
);

class WorkspaceModeNotifier extends Notifier<WorkspaceMode> {
  @override
  WorkspaceMode build() => WorkspaceMode.work;

  /// Flips the mode. **Navigation is deliberately not this method's job**:
  /// `app_router.dart`'s `_AuthRouterRefresh` listens to this provider, so
  /// setting it re-runs `redirect`, which moves the session into the other
  /// shell on its own. A caller that also navigated would be racing that
  /// redirect to the same destination.
  ///
  /// In memory first, storage second — same ordering, and the same reason,
  /// as `OnboardingSeenNotifier.complete`.
  void setMode(WorkspaceMode mode) {
    if (state == mode) return;
    state = mode;
    ref.read(workspaceModeRepositoryProvider).write(mode);
  }

  void toggle() => setMode(
    state == WorkspaceMode.work ? WorkspaceMode.browse : WorkspaceMode.work,
  );
}

final workspaceModeProvider =
    NotifierProvider<WorkspaceModeNotifier, WorkspaceMode>(
      WorkspaceModeNotifier.new,
    );

/// [WorkspaceModeNotifier] with its initial value supplied rather than taken
/// from the class default — the override shape `main.dart` uses after
/// reading storage, and the one a test uses to start a session in a known
/// shell. Public and here, rather than private to `main.dart`, for the same
/// reason `SeededOnboardingSeenNotifier` is: tests seed through the same
/// mechanism production does instead of a parallel one that could drift.
class SeededWorkspaceModeNotifier extends WorkspaceModeNotifier {
  SeededWorkspaceModeNotifier(this._initial);

  final WorkspaceMode _initial;

  @override
  WorkspaceMode build() => _initial;
}
