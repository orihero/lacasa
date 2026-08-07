/// Barrel for `lib/features/language/` — same convention as
/// `features/filter/filter.dart` and `features/contact/contact.dart`.
///
/// Nothing here is wired into `app_router.dart`: SCREENS.md §1 buckets
/// `language-sheet` as a bottom sheet, not a route (§3.20). The entry point
/// is [showLanguageSheet], called from whichever screen owns a "Language"
/// row — `profile-signed-out`, `profile-buyer`, `profile-agent` and
/// `settings` per SCREENS.md, none of which this task builds.
///
/// [languageProvider] and [AppLanguage] are exported too: any screen that
/// wants to show the current language (e.g. a settings row's subtitle) reads
/// `ref.watch(languageProvider).value?.label`, the same way
/// `_LanguageSheet` itself does — see `state/language_provider.dart`'s doc
/// comment for what this provider does and does not do yet.
library;

export 'data/app_language.dart';
export 'data/language_repository.dart';
export 'state/language_provider.dart';
export 'state/language_repository_provider.dart';
export 'widgets/language_sheet.dart';
