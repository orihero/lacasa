/// A controllable [MyListingsRepository] fake for widget tests — no
/// network, no coupling to `work_seed_data.dart`, same shape as
/// `test/features/saved_listings/support/fake_saved_listings_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/my_listings/data/my_listings_repository.dart';

class FakeMyListingsRepository implements MyListingsRepository {
  FakeMyListingsRepository({
    List<Ad>? ads,
    List<Coworker>? coworkers,
    this.adsError,
    this.coworkersError,
    this.adsHold,
  }) : ads = ads ?? const [],
       coworkers = coworkers ?? const [];

  final List<Ad> ads;
  final List<Coworker> coworkers;
  final Object? adsError;
  final Object? coworkersError;

  /// When set, [fetchMyAds] awaits this before returning — the only way to
  /// observe a loading state in a widget test, same reasoning as
  /// `FakeSavedListingsRepository.hold`.
  final Completer<void>? adsHold;

  int fetchMyAdsCallCount = 0;
  int fetchCoworkersCallCount = 0;
  AdFilters? lastFilters;
  AdSort? lastSort;

  @override
  Future<List<Ad>> fetchMyAds({
    AdFilters filters = const AdFilters(),
    AdSort sort = AdSort.newest,
  }) async {
    fetchMyAdsCallCount++;
    lastFilters = filters;
    lastSort = sort;
    if (adsHold != null) await adsHold!.future;
    if (adsError != null) throw adsError!;
    return ads;
  }

  @override
  Future<List<Coworker>> fetchCoworkers() async {
    fetchCoworkersCallCount++;
    if (coworkersError != null) throw coworkersError!;
    return coworkers;
  }
}
