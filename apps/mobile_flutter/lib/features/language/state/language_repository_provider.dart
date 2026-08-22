/// The one [LanguageRepository] every provider/widget reads through — same
/// shape as `search/state/recent_searches_repository_provider.dart`. No
/// fixture/live split: there is nothing to fetch from a server (SCREENS.md
/// §3.20 is a purely local preference), so a real keystore is the only mode
/// this ever runs in. Tests override this with an in-memory fake instead
/// (`test/features/language/support/fake_language_repository.dart`) so no
/// suite depends on a real keystore/keychain being available under
/// `flutter test`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/language_repository.dart';
import '../data/secure_language_repository.dart';

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return SecureLanguageRepository();
});
