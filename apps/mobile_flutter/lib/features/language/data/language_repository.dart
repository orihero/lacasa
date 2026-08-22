/// Where the user's chosen UI language (SCREENS.md §3.20) is persisted.
///
/// Same shape as `onboarding_repository.dart` and
/// `recent_searches_repository.dart`: one small interface, one
/// `flutter_secure_storage`-backed implementation, no new dependency. Unlike
/// onboarding's "fail closed to seen", a storage failure here degrades to
/// [AppLanguage.en] on read and is silently swallowed on write — see
/// `secure_language_repository.dart` for why English is the safe default in
/// both directions.
library;

import 'app_language.dart';

abstract class LanguageRepository {
  /// The persisted language, or [AppLanguage.en] if none was ever saved or
  /// the read failed.
  Future<AppLanguage> load();

  Future<void> save(AppLanguage language);
}
