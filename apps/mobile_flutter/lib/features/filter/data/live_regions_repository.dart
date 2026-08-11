/// The real, network-backed [RegionsRepository] — thin adapter over
/// [LaCasaApi]'s `GET /regions`, no `regionId` narrowing (see
/// `regions_repository.dart`'s doc comment for why the full vocabulary is
/// always what this fetches).
library;

import '../../../api/api.dart';
import 'regions_repository.dart';

class LiveRegionsRepository implements RegionsRepository {
  const LiveRegionsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<RegionsData> fetchAll() => _api.regions.fetch();
}
