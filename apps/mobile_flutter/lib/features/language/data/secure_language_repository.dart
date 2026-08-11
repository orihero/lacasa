/// [LanguageRepository] backed by the platform keystore/keychain via
/// `flutter_secure_storage` — see that interface's doc comment, and
/// `onboarding/data/secure_onboarding_repository.dart`, for why this package
/// is reused rather than adding `shared_preferences` for one more flag.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_language.dart';
import 'language_repository.dart';

const String _languageKey = 'lacasa_language';

class SecureLanguageRepository implements LanguageRepository {
  SecureLanguageRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<AppLanguage> load() async {
    try {
      final raw = await _storage.read(key: _languageKey);
      if (raw == null) return AppLanguage.en;
      return AppLanguage.fromWire(raw);
    } catch (_) {
      // English is the enum default (and `LanguageNotifier`'s own
      // loading/error fallback — see that class's doc comment), so a
      // storage hiccup and "never set anything" look identical to the
      // user — neither is worth surfacing.
      return AppLanguage.en;
    }
  }

  @override
  Future<void> save(AppLanguage language) async {
    try {
      await _storage.write(key: _languageKey, value: language.wire);
    } catch (_) {
      // A failed write just means the choice doesn't survive relaunch —
      // mildly annoying, never broken, and there's nothing useful to tell
      // the user about their keychain at this moment. Same call
      // `secure_onboarding_repository.dart`'s `markSeen` makes.
    }
  }
}
