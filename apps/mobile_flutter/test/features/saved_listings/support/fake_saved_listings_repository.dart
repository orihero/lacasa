/// A controllable [SavedListingsRepository] fake for widget tests — no
/// network, no coupling to `saved_listings_fixtures.dart`, same shape as
/// `test/features/agents/support/fake_agents_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/saved_listings/data/saved_listings_repository.dart';

class FakeSavedListingsRepository implements SavedListingsRepository {
  FakeSavedListingsRepository({List<Ad>? ads, this.error, this.hold})
    : ads = ads ?? const [];

  final List<Ad> ads;
  final Object? error;

  /// When set, [fetchSavedAds] awaits this before returning — the only way
  /// to observe a loading state in a widget test, same reasoning as
  /// `FakeAgentsRepository.hold`.
  final Completer<void>? hold;

  int fetchCallCount = 0;

  @override
  Future<List<Ad>> fetchSavedAds() async {
    fetchCallCount++;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return ads;
  }
}
