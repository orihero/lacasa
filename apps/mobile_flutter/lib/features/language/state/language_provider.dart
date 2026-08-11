/// [languageProvider] holds the user's chosen UI language and is the seam
/// `app.dart` drives `MaterialApp.locale` from.
///
/// ## What exists today
/// - [AppLanguage] (`data/app_language.dart`): the three-way enum, En/Uz/Ru.
/// - [LanguageRepository] / [SecureLanguageRepository]: persistence, via
///   `flutter_secure_storage`, following every other small-flag repository
///   in this codebase (`onboarding`, `search`'s recent-searches).
/// - [languageProvider] (this file): an [AsyncNotifier] seeded from storage
///   on first read, defaulting to [AppLanguage.en] while loading or on any
///   storage failure (see [SecureLanguageRepository.load]).
/// - `language-sheet` (`widgets/language_sheet.dart`): the radio picker.
///   Selecting a row calls [LanguageNotifier.select], which updates state
///   optimistically and persists in the background, then closes the sheet —
///   SCREENS.md §3.20: "Selecting applies immediately and closes."
/// - `app.dart` watches this provider and sets `MaterialApp.locale` from it
///   (`Locale(language.wire)`), so a selection here is live app-wide the
///   same frame the sheet closes, for any string that has actually been
///   through `flutter gen-l10n` — see `lib/l10n/README.md`.
///
/// ## Status
/// The toolchain (`l10n.yaml`, `AppLocalizations` generation, the
/// `MaterialApp` wiring above, the test harness) is done, and the
/// extraction itself is done too — see `lib/l10n/README.md` for the full
/// picture. All six feature groups have been extracted (688 ARB keys, 100%
/// translated in both Uzbek and Russian, no English-fallback keys) and a
/// selection here is visible across the app the same frame the sheet
/// closes. **The uz/ru values are machine-translated and have not had a
/// native-speaker review pass** — see `README.md`'s "Known gaps" for that
/// caveat, which is the one real gap left in this feature, not extraction
/// coverage.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_language.dart';
import 'language_repository_provider.dart';

class LanguageNotifier extends AsyncNotifier<AppLanguage> {
  @override
  Future<AppLanguage> build() {
    return ref.read(languageRepositoryProvider).load();
  }

  /// SCREENS.md §3.20: "Selecting applies immediately and closes." State
  /// updates synchronously (so the sheet's radio reflects the tap on the
  /// same frame, before the sheet even finishes closing) and persistence
  /// happens in the background, mirroring
  /// `RecentSearchesNotifier.addQuery`'s "update state, then await the
  /// write" order in `search/state/search_providers.dart`.
  Future<void> select(AppLanguage language) async {
    state = AsyncData(language);
    await ref.read(languageRepositoryProvider).save(language);
  }
}

final languageProvider = AsyncNotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);
