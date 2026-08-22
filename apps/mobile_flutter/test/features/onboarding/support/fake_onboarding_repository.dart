/// A controllable [OnboardingRepository] for widget tests — no keystore, and
/// a call counter so a test can assert that finishing *and* skipping both
/// persist (SCREENS.md §3.1 treats them as the same commitment).
library;

import 'package:lacasa_mobile/features/onboarding/onboarding.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.seen = false});

  final bool seen;

  int markSeenCallCount = 0;

  @override
  Future<bool> hasSeenOnboarding() async => seen;

  @override
  Future<void> markSeen() async {
    markSeenCallCount++;
  }
}
