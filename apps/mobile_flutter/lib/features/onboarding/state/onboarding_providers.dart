/// The onboarding gate's state.
///
/// **[onboardingSeenProvider] is a plain, synchronous [Notifier<bool>] whose
/// initial value is injected by `main.dart`**, not an [AsyncNotifier] that
/// reads storage itself. That shape is chosen by a hard constraint
/// downstream: `app_router.dart`'s `redirect` is a synchronous function, and
/// it has to answer "onboarding or not?" on the very first route
/// resolution.
///
/// The alternatives were both worse and were rejected:
///
/// - *Async provider, don't redirect while loading* — a returning user
///   lands on Home, then gets yanked into a carousel a frame later. A
///   first-run user gets it the other way around.
/// - *Async provider, redirect to onboarding while loading* — the flash
///   lands on everyone who has already dismissed it, which is the worse
///   half of the same trade.
///
/// So `main()` awaits the one small read before `runApp` (it is a single
/// keystore lookup, on the same startup path that already blocks on
/// `WidgetsFlutterBinding.ensureInitialized`) and overrides
/// [onboardingSeenProvider] with the answer. By the time any route
/// resolves, the value is simply known.
///
/// **The unoverridden default is `true`, not `false`.** Only `main.dart`,
/// having actually read storage, is in a position to claim a user has *not*
/// seen the carousel; every other entry point — a widget test pumping the
/// router, a screen pumped in isolation — wants ordinary returning-user
/// behaviour, and a `false` default silently redirects all of them into
/// onboarding. It is also the same fail-safe direction
/// `onboarding_repository.dart` takes for storage errors, for the same
/// reason: showing the carousel to someone who already dismissed it is the
/// worse failure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_repository.dart';
import '../data/secure_onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SecureOnboardingRepository();
});

class OnboardingSeenNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  /// Marks the carousel done — in memory immediately, so the router's
  /// redirect stops firing on this frame, and in storage in the background.
  /// Persisting first would leave the user staring at the last slide for
  /// however long a keystore write takes.
  void complete() {
    state = true;
    ref.read(onboardingRepositoryProvider).markSeen();
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);

/// [OnboardingSeenNotifier] with its initial value supplied rather than
/// taken from the class default — the override shape `main.dart` uses after
/// reading storage, and the one a test uses to put the gate in a known
/// state. Public and here, rather than private to `main.dart`, precisely so
/// tests seed the flag through the same mechanism production does instead
/// of a parallel one that could drift.
class SeededOnboardingSeenNotifier extends OnboardingSeenNotifier {
  SeededOnboardingSeenNotifier(this._initial);

  final bool _initial;

  @override
  bool build() => _initial;
}
