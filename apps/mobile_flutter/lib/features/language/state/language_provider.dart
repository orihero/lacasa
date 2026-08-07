/// [languageProvider] holds the user's chosen UI language and is **the
/// entire localisation seam this build has**. Read this doc comment before
/// touching anything here — it is the map for the next agent that actually
/// localises the app.
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
///
/// ## What does not exist, and must not be faked
/// **The app ships one hardcoded English copy.** Every literal string in
/// `lib/` — every `Text('...')`, every button label, every validation
/// message — is an English string baked into the widget tree at compile
/// time. There is no ARB catalogue, no generated `AppLocalizations` class,
/// no `MaterialApp.localizationsDelegates`/`supportedLocales`, and no `.arb`
/// file for Uzbek or Russian anywhere in this repo. Selecting "Uz" or "Ru"
/// in the sheet built here changes [languageProvider]'s persisted value —
/// full stop. Not one label anywhere else in the app moves.
///
/// That is why `language_sheet.dart` prints an explicit, honest line under
/// the radio options instead of silently shipping a control that looks
/// functional and isn't. Faking translated strings (e.g. a hand-maintained
/// `Map<AppLanguage, String>` per copy string scattered through 60+ widget
/// files) was rejected: it would drift from the real copy immediately,
/// give three independent implementations three different half-translations
/// to disagree over, and bury the actual gap instead of surfacing it.
///
/// ## Exactly what the next person has to do
/// 1. Add the `flutter_localizations` SDK package and `intl` to
///    `pubspec.yaml`, and an `l10n.yaml` pointing at `lib/l10n/`.
/// 2. Write `lib/l10n/app_en.arb` by pulling every literal string out of
///    every `features/*/widgets/*.dart` file (SCREENS.md is the source of
///    truth for the *English* wording — it's already been transcribed
///    character-for-character into the widgets, so the ARB keys can mostly
///    be lifted straight from there) plus `app_uz.arb` / `app_ru.arb` with
///    the actual translations (a translator/native speaker pass — this is
///    not a mechanical step).
/// 3. Run `flutter gen-l10n` to generate `AppLocalizations`, then replace
///    every hardcoded `Text('...')`/string literal with
///    `AppLocalizations.of(context)!.someKey` — a large, mechanical,
///    file-by-file pass across the whole `features/` tree.
/// 4. Wire `MaterialApp.localizationsDelegates`,
///    `MaterialApp.supportedLocales`, and `MaterialApp.locale` (the last one
///    driven by `ref.watch(languageProvider)`, converting [AppLanguage] to a
///    `Locale` via [AppLanguage.wire]) in `app.dart`.
/// 5. Delete the honest-gap copy in `language_sheet.dart` once (4) is true.
///
/// None of that is done here. This provider is deliberately built to need
/// no further changes when it is: it already exposes the selected
/// [AppLanguage] and already persists it, so step (4) above is the only
/// thing that has to touch this file (reading it), and nothing has to touch
/// its shape.
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
