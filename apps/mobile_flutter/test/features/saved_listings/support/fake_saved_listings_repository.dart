/// A controllable [SavedListingsRepository] fake for widget tests — no
/// network, no coupling to `saved_listings_fixtures.dart`, same shape as
/// `test/features/agents/support/fake_agents_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/saved_listings/data/saved_listings_repository.dart';

class FakeSavedListingsRepository implements SavedListingsRepository {
  FakeSavedListingsRepository({
    List<Ad>? ads,
    this.error,
    this.hold,
    this.holdFromCall = 1,
  }) : ads = ads ?? const [];

  final List<Ad> ads;
  final Object? error;

  /// When set, [fetchSavedAds] awaits this before returning — the only way
  /// to observe a loading state in a widget test, same reasoning as
  /// `FakeAgentsRepository.hold`.
  final Completer<void>? hold;

  /// Which call [hold] starts applying to (1-based). Defaults to the first,
  /// i.e. the plain "freeze the initial load" case. A test that needs the
  /// *initial* list on screen before it can freeze a later re-fetch — the
  /// failed-unsave reconciliation is exactly that — passes `2`.
  final int holdFromCall;

  int fetchCallCount = 0;

  @override
  Future<List<Ad>> fetchSavedAds() async {
    fetchCallCount++;
    if (hold != null && fetchCallCount >= holdFromCall) await hold!.future;
    if (error != null) throw error!;
    return ads;
  }
}
