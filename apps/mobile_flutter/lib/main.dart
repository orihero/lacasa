/// App entry point: bootstraps the Flutter binding, resolves the couple of
/// pieces of persisted state the very first frame depends on, wraps the app
/// tree in a [ProviderScope], and hands off to [App] for theme/navigation
/// wiring.
///
/// **Why this awaits before `runApp`.** `app_router.dart`'s `redirect` is
/// synchronous and has to decide "onboarding or Home?" on the first route it
/// resolves. Reading the seen-flag here — one keystore lookup, on a startup
/// path that already blocks on `ensureInitialized` — and injecting it as a
/// provider override means that decision is simply known, with no first-run
/// flash of Home or returning-user flash of the carousel. See
/// `features/onboarding/state/onboarding_providers.dart` for the rejected
/// alternatives.
///
/// This is deliberately close to the *only* class of thing startup blocks
/// on: a single, bounded, local keystore read whose answer some provider
/// needs synchronously. Everything else loads asynchronously behind a
/// loading state, and nothing else should be added here without a
/// comparably narrow justification.
///
/// **The one addition beyond onboarding** is [hasPersistedAuthTokenProvider]
/// — whether a previous session's token exists at all. Note what this read
/// deliberately does *not* do: it does not validate that token against the
/// server (`GET /auth/me`), because that is a network call with no bound in
/// the wild, unlike a keystore lookup. Blocking `runApp` on it would risk
/// never painting a first frame on a bad connection, which is strictly worse
/// than the cosmetic trade-off this design accepts instead (a returning
/// agent/coworker's tab bar reflows from 4 to 5 tabs a moment after launch).
/// The actual network validation happens later, bounded by a timeout, inside
/// `navigation/auth_session.dart`'s `AuthSessionNotifier` — see that file's
/// "Startup restore" doc section for the full reasoning and the rejected
/// alternative (blocking here too, onboarding-style).
///
/// **The third read is the workspace mode** — Browse or Work, i.e. which of
/// the app's two shells a returning agent belongs in. It qualifies on
/// exactly the onboarding grounds rather than the auth-token ones: the
/// router's synchronous `redirect` needs the answer on the first route it
/// resolves, and it is a single local keystore lookup with no network in
/// sight. See `navigation/workspace_mode.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api.dart';
import 'app.dart';
import 'features/onboarding/onboarding.dart';
import 'navigation/auth_session.dart';
import 'navigation/workspace_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final onboardingRepository = SecureOnboardingRepository();
  final hasSeenOnboarding = await onboardingRepository.hasSeenOnboarding();

  // Fails closed to "nothing to restore": SecureTokenStorage.getToken()
  // itself has no try/catch (lib/api/token_storage.dart), so a keystore
  // read that throws here would otherwise crash startup outright. A
  // corrupt/unreadable keystore must never be mistaken for a live session —
  // the same fail-safe direction `SecureOnboardingRepository` takes for its
  // own read, just with the opposite target value (there, failure means
  // "seen"; here, failure means "no session").
  bool hasPersistedAuthToken;
  try {
    hasPersistedAuthToken = await SecureTokenStorage().getToken() != null;
  } catch (_) {
    hasPersistedAuthToken = false;
  }

  // The third and last of this function's keystore reads, and it clears the
  // same bar the other two do: `app_router.dart`'s synchronous `redirect`
  // consults the workspace mode on the very first route it resolves, so a
  // returning agent whose mode is only known a frame later would launch into
  // the wrong shell and get yanked into the other one. `read()` fails closed
  // to `WorkspaceMode.work` on its own (see workspace_mode.dart) — no
  // try/catch needed here, unlike the token read above.
  final workspaceModeRepository = SecureWorkspaceModeRepository();
  final workspaceMode = await workspaceModeRepository.read();

  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(onboardingRepository),
        onboardingSeenProvider.overrideWith(
          () => SeededOnboardingSeenNotifier(hasSeenOnboarding),
        ),
        hasPersistedAuthTokenProvider.overrideWithValue(hasPersistedAuthToken),
        workspaceModeRepositoryProvider.overrideWithValue(
          workspaceModeRepository,
        ),
        workspaceModeProvider.overrideWith(
          () => SeededWorkspaceModeNotifier(workspaceMode),
        ),
      ],
      child: const App(),
    ),
  );
}
