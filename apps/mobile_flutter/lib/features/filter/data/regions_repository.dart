/// Data-access seam for `filter-sheet`'s City/District cascade. Two
/// implementations — [FixtureRegionsRepository] (bundled, no network) and
/// [LiveRegionsRepository] (the real [LaCasaApi]'s `GET /regions`) — see
/// `regions_repository_provider.dart` for which one the app wires up by
/// default (the same `filter_mode.dart` switch `FilterRepository` already
/// uses — this is the same screen surface, not a second independent mode).
///
/// **One method, the full vocabulary, every time.** `GET /regions` also
/// accepts a `?regionId=` to pre-narrow server-side (`regions_resource.dart`),
/// but this repository never sends it: the picker cascades District from
/// whichever Region the user already picked by filtering [RegionsData
/// .districts] in memory (`district.regionId == region.id`), which needs
/// the whole vocabulary loaded once anyway to populate the Region list
/// itself. Fetching per-region would mean a second round trip *after* the
/// first one already had every district in hand — strictly more requests
/// for the same result.
library;

import '../../../api/api.dart';

abstract class RegionsRepository {
  Future<RegionsData> fetchAll();
}
