/// [RecentSearchesRepository] backed by the platform keystore/keychain via
/// `flutter_secure_storage` — see that interface's doc comment for why this
/// package was reused instead of adding a new one. Stores the recent-query
/// list as a single `\n`-joined string under one key (a query never
/// legitimately contains a newline — the search field is single-line — so
/// this avoids pulling in `dart:convert`'s JSON codec for what is otherwise
/// just a flat string list).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'recent_searches_repository.dart';

const String _recentSearchesKey = 'lacasa_recent_searches';

class SecureRecentSearchesRepository implements RecentSearchesRepository {
  SecureRecentSearchesRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<List<String>> load() async {
    try {
      final raw = await _storage.read(key: _recentSearchesKey);
      if (raw == null || raw.isEmpty) return const [];
      return raw.split('\n').where((s) => s.isNotEmpty).toList();
    } catch (_) {
      // See recent_searches_repository.dart's doc comment: recents are a
      // convenience, never load-bearing — any storage failure degrades to
      // "nothing recent yet" rather than surfacing an error the results
      // list has no use for.
      return const [];
    }
  }

  @override
  Future<void> save(List<String> recents) async {
    try {
      await _storage.write(key: _recentSearchesKey, value: recents.join('\n'));
    } catch (_) {
      // Same degrade rule as load(): a failed write silently loses the
      // "recent" convenience, never the search screen itself.
    }
  }
}
