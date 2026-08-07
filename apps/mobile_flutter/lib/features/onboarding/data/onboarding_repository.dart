/// Where "has this person seen the onboarding carousel?" is persisted.
///
/// **One boolean, and it must survive a reinstall-free relaunch** — that is
/// the entire contract. `flutter_secure_storage` backs the real
/// implementation, reused rather than adding `shared_preferences` for a
/// single flag; the same call
/// `secure_recent_searches_repository.dart` already made, and its doc
/// comment carries the reasoning.
///
/// **Every failure degrades to "seen".** That is the deliberate direction,
/// and it is the opposite of what the recents list does. A storage read
/// that throws on a returning user must not shove them back through a
/// three-slide pitch they dismissed months ago; showing onboarding one time
/// too few is a non-event, showing it again to someone who already
/// dismissed it is the app looking broken.
library;

abstract class OnboardingRepository {
  /// `true` once the carousel has been completed or skipped. See this
  /// file's doc comment for why a failed read answers `true`.
  Future<bool> hasSeenOnboarding();

  /// Records that the carousel is done — called for both "Get Started" and
  /// "Skip", which are the same commitment as far as this flag is
  /// concerned (SCREENS.md §3.1: both go to `home-feed`).
  Future<void> markSeen();
}
