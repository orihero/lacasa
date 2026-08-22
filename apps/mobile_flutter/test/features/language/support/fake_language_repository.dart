// In-memory [LanguageRepository] fake — same shape as
// `test/features/search/support/fake_recent_searches_repository.dart` — so
// no suite depends on a real keystore/keychain under `flutter test`.

import 'package:lacasa_mobile/features/language/language.dart';

class FakeLanguageRepository implements LanguageRepository {
  FakeLanguageRepository({AppLanguage initial = AppLanguage.en})
    : _current = initial;

  AppLanguage _current;

  /// Every value [save] was called with, in call order — lets a test assert
  /// persistence happened without caring about [load]'s return.
  final List<AppLanguage> saved = [];

  @override
  Future<AppLanguage> load() async => _current;

  @override
  Future<void> save(AppLanguage language) async {
    _current = language;
    saved.add(language);
  }
}
