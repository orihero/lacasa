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
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api.dart';
import 'app.dart';
import 'features/onboarding/onboarding.dart';
import 'navigation/auth_session.dart';

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

  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(onboardingRepository),
        onboardingSeenProvider.overrideWith(
          () => SeededOnboardingSeenNotifier(hasSeenOnboarding),
        ),
        hasPersistedAuthTokenProvider.overrideWithValue(hasPersistedAuthToken),
      ],
      child: const App(),
    ),
  );
}
