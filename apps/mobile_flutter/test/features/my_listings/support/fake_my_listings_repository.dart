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

  /// When set, [fetchMyAdsPage] awaits this before returning — the only way
  /// to observe a loading state in a widget test, same reasoning as
  /// `FakeSavedListingsRepository.hold`.
  final Completer<void>? adsHold;

  int fetchMyAdsCallCount = 0;
  int fetchCoworkersCallCount = 0;
  AdFilters? lastFilters;
  AdSort? lastSort;

  /// [fetchMyAdsPage]'s own opaque cursor stand-in — same shape as
  /// `FixtureMyListingsRepository`'s "matched list's next start index, as a
  /// string" (see that class's doc comment): genuinely sliced by [limit]
  /// against [ads] rather than a fake "return everything on page one"
  /// shortcut, so `my_listings_screen_test.dart`'s own infinite-scroll group
  /// (real `myListingsPageSize`-sized pages, a real `loadMore`) exercises
  /// the same paging contract the live/fixture repositories do.
  @override
  Future<AdPage> fetchMyAdsPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    AdStage? stage,
    int? limit,
    String? cursor,
  }) async {
    fetchMyAdsCallCount++;
    lastFilters = filters;
    lastSort = switch (sort) {
      AdListSort.newest => AdSort.newest,
      AdListSort.priceDesc => AdSort.highestPrice,
      AdListSort.priceAsc => AdSort.lowestPrice,
      // No `AdSort` counterpart for the wider `AdListSort`'s other values —
      // no test in this suite drives one of these, and `lastSort` exists
      // purely for tests asserting on the 3-value CRM sort chip that was
      // tapped, so falling back to `newest` here is inert rather than a
      // guess a test could observe as wrong.
      _ => AdSort.newest,
    };
    if (adsHold != null) await adsHold!.future;
    if (adsError != null) throw adsError!;

    // Real `stage` narrowing (`my_listings_providers.dart`'s doc comment: "a
    // real `GET /my/ads` `stage` param now, not a client-only narrowing") —
    // filtered here, not left to the widget layer, so
    // `my_listings_screen_test.dart`'s own "narrows the visible list by
    // status" assertion exercises the same contract the live/fixture
    // repositories implement.
    final matched = stage == null
        ? ads
        : ads.where((ad) => ad.stage == stage).toList();

    final start = cursor == null ? 0 : (int.tryParse(cursor) ?? 0);
    final pageSize = limit ?? matched.length;
    final end = (start + pageSize).clamp(0, matched.length);
    final items = start >= matched.length
        ? const <Ad>[]
        : matched.sublist(start, end);
    final nextCursor = end >= matched.length ? null : end.toString();
    return AdPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<List<Coworker>> fetchCoworkers() async {
    fetchCoworkersCallCount++;
    if (coworkersError != null) throw coworkersError!;
    return coworkers;
  }
}
