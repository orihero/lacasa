/// Picks [FixtureRegionsRepository] or [LiveRegionsRepository] once, per
/// `filter_mode.dart`'s `useLiveFilterApi` switch — the same switch
/// `filterRepositoryProvider` uses, since the region/district picker is
/// part of the same `filter-sheet` screen, not an independently-toggled
/// surface.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/filter_mode.dart';
import '../data/fixture_regions_repository.dart';
import '../data/live_regions_repository.dart';
import '../data/regions_repository.dart';

final regionsRepositoryProvider = Provider<RegionsRepository>((ref) {
  if (useLiveFilterApi) {
    return LiveRegionsRepository(LaCasaApi.create());
  }
  return const FixtureRegionsRepository();
});

/// The cached region/district vocabulary — static reference data
/// (`docs/04-api-spec.md`'s Regions section: `Cache-Control: public,
/// max-age=86400`), so this is a plain (non-`autoDispose`) [FutureProvider]:
/// the app-wide `ProviderContainer` keeps its resolved value alive for the
/// process lifetime once first read, so opening `filter-sheet` a second
/// time (a fresh `FilterSheet` widget instance every time — it's a modal
/// bottom sheet, not a route) never re-fetches. This is this client's
/// caching answer to `regions_resource.dart`'s own documented gap (no
/// conditional-GET/`ETag` support in [Transport]) — a full re-fetch would
/// be wasteful for data that doesn't change inside one app session even
/// without HTTP-level caching, so this provider is the cache.
final regionsDataProvider = FutureProvider<RegionsData>((ref) {
  return ref.read(regionsRepositoryProvider).fetchAll();
});
