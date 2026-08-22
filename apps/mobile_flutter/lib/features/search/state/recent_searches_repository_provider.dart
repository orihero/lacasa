/// The one [RecentSearchesRepository] every provider/widget reads through.
/// Unlike `searchRepositoryProvider` there is no fixture/live split here —
/// see `recent_searches_repository.dart`'s doc comment for why local
/// storage is the only mode this ever runs in. Tests override this with an
/// in-memory fake instead (see `test/features/search/support/
/// fake_recent_searches_repository.dart`) so no suite depends on a real
/// keystore/keychain being available under `flutter test`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recent_searches_repository.dart';
import '../data/secure_recent_searches_repository.dart';

final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>((
  ref,
) {
  return SecureRecentSearchesRepository();
});
