/// A [RegionsRepository] that answers with an empty vocabulary and never
/// touches the network.
///
/// **Why this exists.** `regionsRepositoryProvider` now builds
/// [LiveRegionsRepository] around `LaCasaApi.create()` unconditionally — the
/// bundled fixture repositories, and the `FLUTTER_TEST` switch in
/// `lib/api/app_mode.dart` that used to force them, are gone. Any widget test
/// that mounts the real router shell reaches the filter sheet's City/District
/// cascade incidentally, so an un-overridden provider fires a real
/// `GET /regions` out of the test process. That does not fail cleanly, it
/// *hangs*, and the test dies on `pumpAndSettle timed out` with nothing
/// pointing at the cause. Overriding the provider with this class is what
/// keeps that from happening.
///
/// **It is deliberately inert.** [fetchAll] returns `RegionsData` with no
/// regions and no districts — the emptiest value the non-nullable return type
/// allows — so a screen under test can never accidentally assert against
/// vocabulary this fake happened to invent. The City picker renders its empty
/// state and the District cascade has nothing to narrow, which is the correct
/// outcome for a test that is about something else entirely.
///
/// A test that actually exercises region/district behaviour — picking a city,
/// checking that districts filter by `district.regionId == region.id`, a
/// loading or error path — should not reach for this. It should override
/// `regionsRepositoryProvider` with a purpose-built fake from
/// `test/features/filter/support/` that returns the vocabulary the assertions
/// need.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/data/regions_repository.dart';

/// No regions, no districts, no network.
class InertRegionsRepository implements RegionsRepository {
  const InertRegionsRepository();

  @override
  Future<RegionsData> fetchAll() async =>
      const RegionsData(regions: <Region>[], districts: <District>[]);
}
