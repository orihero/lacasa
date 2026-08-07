/// The three options `language-sheet` (SCREENS.md §3.20) offers, and the
/// single source of truth for their radio-row labels: **"En" / "Uz" / "Ru"**,
/// quoted character for character rather than expanded to "English" /
/// "Uzbek" / "Russian" — the spec's abbreviated form is what three
/// independent implementations must agree on.
///
/// This enum is the seam a future localisation effort plugs into (see
/// `language_provider.dart`'s doc comment for the full story of what that
/// effort still has to do) — the wire values below are picked to match the
/// `Accept-Language`-style codes that ARB/`intl` tooling and any future
/// `PATCH /users/me` "preferred language" field would both expect, even
/// though nothing reads them yet.
library;

enum AppLanguage {
  en,
  uz,
  ru;

  /// SCREENS.md §3.20's exact radio-row text.
  String get label => switch (this) {
    AppLanguage.en => 'En',
    AppLanguage.uz => 'Uz',
    AppLanguage.ru => 'Ru',
  };

  /// ISO 639-1 code. Not consumed by anything today — see this file's doc
  /// comment.
  String get wire => switch (this) {
    AppLanguage.en => 'en',
    AppLanguage.uz => 'uz',
    AppLanguage.ru => 'ru',
  };

  static AppLanguage fromWire(String value) {
    return AppLanguage.values.firstWhere(
      (l) => l.wire == value,
      orElse: () => AppLanguage.en,
    );
  }
}
