/// Barrel for `lib/features/onboarding/` — SCREENS.md §3.1. Exports the
/// screen plus the seen-flag provider, because unlike every other feature
/// here, two things outside this directory need it: `app_router.dart`'s
/// redirect (to decide whether to show the carousel at all) and `main.dart`
/// (to inject the persisted value before the first frame — see
/// `onboarding_providers.dart`).
library;

export 'data/onboarding_repository.dart';
export 'data/secure_onboarding_repository.dart';
export 'state/onboarding_providers.dart';
export 'widgets/onboarding_screen.dart';
