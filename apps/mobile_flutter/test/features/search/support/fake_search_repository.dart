/// A controllable [SearchRepository] fake for widget tests — no network, no
/// coupling to `search_fixtures.dart`, same shape as
/// `test/features/home/support/fake_home_feed_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/search/data/search_repository.dart';

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({List<Ad>? ads, this.error, this.hold})
    : ads = ads ?? const [];

  final List<Ad> ads;
  final Object? error;

  /// When set, [fetchResults] awaits this before returning — the only way
  /// to observe a loading state in a widget test, same reasoning as
  /// `FakeSavedListingsRepository.hold`.
  final Completer<void>? hold;

  int fetchCallCount = 0;

  /// The [AdFilters] the most recent [fetchResults] call was made with —
  /// lets a test assert the filter-sheet handoff actually re-fetches with
  /// the applied filters, not just that a fetch happened.
  AdFilters? lastFilters;

  @override
  Future<List<Ad>> fetchResults({AdFilters filters = const AdFilters()}) async {
    fetchCallCount++;
    lastFilters = filters;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return ads;
  }
}
