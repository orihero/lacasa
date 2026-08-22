/// A controllable [RecentSearchesRepository] fake for widget tests — no
/// keystore/keychain, no `flutter_secure_storage` platform binding required
/// under `flutter test`. This is the fake `recent_searches_repository_
/// provider.dart`'s own doc comment already names as living here.
library;

import 'dart:async';

import 'package:lacasa_mobile/features/search/data/recent_searches_repository.dart';

class FakeRecentSearchesRepository implements RecentSearchesRepository {
  FakeRecentSearchesRepository({
    List<String>? initial,
    this.loadError,
    this.loadHold,
  }) : _stored = initial ?? const [];

  List<String> _stored;

  /// When set, [load] throws this instead of returning — exercises the
  /// "recents are a convenience, never load-bearing" degrade path
  /// `recent_searches_repository.dart`'s doc comment describes (the row
  /// should render as if there were simply no recents yet).
  final Object? loadError;

  /// When set, [load] awaits this before returning — the only way to hold
  /// the initial `build()` fetch open in a test, to exercise the
  /// build-vs-mutation race `search_providers.dart#RecentSearchesNotifier
  /// .addQuery`'s doc comment describes.
  final Completer<void>? loadHold;

  int loadCallCount = 0;
  int saveCallCount = 0;

  /// The list handed to the most recent [save] call.
  List<String>? lastSaved;

  @override
  Future<List<String>> load() async {
    loadCallCount++;
    if (loadHold != null) await loadHold!.future;
    if (loadError != null) throw loadError!;
    return _stored;
  }

  @override
  Future<void> save(List<String> recents) async {
    saveCallCount++;
    lastSaved = recents;
    _stored = recents;
  }
}
