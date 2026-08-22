/// A do-nothing [MyListingsRepository] for tests that mount the `my-listings`
/// screen only incidentally — anything that builds the real router shell,
/// which resolves this feature's providers whether or not the test asserts on
/// them.
///
/// **Why it exists.** `lib/api/app_mode.dart` used to force a bundled
/// `FixtureMyListingsRepository` whenever `FLUTTER_TEST` was set. The fixture
/// classes are gone and that guard with them, so
/// `myListingsRepositoryProvider` now unconditionally builds
/// `LiveMyListingsRepository` around `LaCasaApi.create()`. Left un-overridden
/// under `flutter test` that fires real HTTP out of the test process, which
/// does not fail cleanly — it hangs, and the test dies on `pumpAndSettle
/// timed out` with nothing pointing at the cause.
///
/// **Deliberately inert.** [fetchMyAdsPage] answers an empty last page (no
/// items, `nextCursor: null`, so `MyListingsResultsNotifier.loadMore` stops
/// immediately) and [fetchCoworkers] answers an empty roster; neither ever
/// throws. A screen backed by this shows its empty state, which is the point:
/// there is no plausible-looking data here for a test to accidentally assert
/// against.
///
/// A test that actually wants `my-listings` behaviour — paging across two
/// pages, a stage/sort/filter round trip, the Author column resolving a
/// coworker — must not stretch this class to cover it. Override
/// `myListingsRepositoryProvider` with a purpose-built fake from
/// `test/features/my_listings/support/` instead, and opt this one out of the
/// ambient override list so Riverpod does not reject the duplicate.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/my_listings/data/my_listings_repository.dart';

class InertMyListingsRepository implements MyListingsRepository {
  const InertMyListingsRepository();

  @override
  Future<AdPage> fetchMyAdsPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    AdStage? stage,
    int? limit,
    String? cursor,
  }) async => const AdPage(items: <Ad>[], nextCursor: null);

  /// All-zero counts, so the header's stage strip renders "All · 0 active ·
  /// 0 sold · 0 drafts" — visible (a strip that vanished would be a
  /// different screen from the real one) but with nothing a test could
  /// mistake for meaningful data, same reasoning as the empty page above.
  @override
  Future<AdStageCounts> fetchStageCounts() async =>
      const AdStageCounts(active: 0, sold: 0, draft: 0);

  /// An empty map, not a per-id map of empty lists: this repository never
  /// answers any ads, so no ad id can reach the channel-badge strip anyway.
  @override
  Future<Map<String, List<ChannelStatus>>> fetchPublishStatuses(
    List<String> adIds,
  ) async => const <String, List<ChannelStatus>>{};

  @override
  Future<List<Coworker>> fetchCoworkers() async => const <Coworker>[];
}
