/// A controllable [FilterRepository] fake for widget tests — no network, no
/// coupling to `filter_ads_fixtures.dart`, same shape as
/// `test/features/search/support/fake_search_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/data/filter_repository.dart';

class FakeFilterRepository implements FilterRepository {
  FakeFilterRepository({this.count = 0, this.error, this.hold});

  /// The count returned by every non-erroring [countMatching] call, unless
  /// overridden per-call via [countsByFilters].
  final int count;

  /// When set, [countMatching] throws this instead of returning — exercises
  /// `_CountErrorRow`'s retry path.
  final Object? error;

  /// When set, [countMatching] awaits this before resolving — the only way
  /// to observe the footer's loading spinner in a widget test.
  final Completer<void>? hold;

  int countCallCount = 0;
  AdFilters? lastFilters;

  @override
  Future<int> countMatching(AdFilters filters) async {
    countCallCount++;
    lastFilters = filters;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return count;
  }
}
