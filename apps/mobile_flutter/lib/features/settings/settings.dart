/// Barrel for `lib/features/settings/` — same convention as
/// `features/language/language.dart` and `features/contact/contact.dart`.
///
/// `settings` (SCREENS.md §3.19) is a PUSHED screen, unlike `language-sheet`
/// or `contact-sheet` — `route_paths.dart` already declares
/// `/profile/settings` and `/work/settings` as placeholders, so a later
/// integration step replaces those placeholder builders with
/// `SettingsScreen(branchPrefix: RoutePaths.profile)` /
/// `SettingsScreen(branchPrefix: RoutePaths.work)` respectively. See
/// `widgets/settings_screen.dart`'s doc comment for the rest of the
/// reasoning.
library;

export 'data/app_version.dart';
export 'data/notifications_preference_repository.dart';
export 'state/notifications_preference_provider.dart';
export 'state/notifications_preference_repository_provider.dart';
export 'widgets/settings_screen.dart';
